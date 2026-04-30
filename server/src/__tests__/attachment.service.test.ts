jest.mock('../config/adminDb', () => ({
  supabaseAdmin: {
    from: jest.fn(),
    storage: {
      from: jest.fn(),
    },
  },
}));

import {
  generateAttachmentSignedUrl,
  saveAttachment,
  deleteAttachment,
} from '../services/attachment.service';
import { supabaseAdmin } from '../config/adminDb';

const mockFrom = supabaseAdmin.from as jest.Mock;
const mockStorageFrom = supabaseAdmin.storage.from as jest.Mock;

const USER_ID = 'user-1';
const WORKSPACE_ID = 'ws-1';
const PROJECT_ID = 'proj-1';
const UPDATE_ID = 'upd-1';
const ATTACHMENT_ID = 'att-1';
// Must match SUPABASE_URL in setup.ts ('https://test.supabase.co') so the
// ATTACHMENTS_URL_PREFIX check passes in the test environment.
const FILE_URL =
  'https://test.supabase.co/storage/v1/object/public/attachments/user-1/upd-1/1234-file.pdf';

// Derive expected storage path from FILE_URL using the same regex the service uses.
const ATTACHMENTS_PUBLIC_PATH_RE = /\/storage\/v1\/object\/public\/attachments\/(.+)$/;
const EXPECTED_STORAGE_PATH = decodeURIComponent(
  ATTACHMENTS_PUBLIC_PATH_RE.exec(FILE_URL)![1],
);

const WORKSPACE_ROW = { id: WORKSPACE_ID };
const PROJECT_ROW = { id: PROJECT_ID };
const UPDATE_ROW = { id: UPDATE_ID, project_id: PROJECT_ID };
const ATTACHMENT_ROW = {
  id: ATTACHMENT_ID,
  update_id: UPDATE_ID,
  file_name: 'report.pdf',
  file_url: FILE_URL,
  file_size: 1024,
  mime_type: 'application/pdf',
  uploaded_by: USER_ID,
  created_at: '2026-01-01T00:00:00Z',
};

// ─── Mock chain builders ───────────────────────────────────────────────────

// step 1: workspaces — .select('id').eq('owner_id',v).is('deleted_at',null).limit(1)
function makeWsLimitChain(result: { data: unknown; error: unknown }) {
  const limitMock = jest.fn().mockResolvedValue(result);
  const isMock = jest.fn().mockReturnValue({ limit: limitMock });
  const eqMock = jest.fn().mockReturnValue({ is: isMock });
  const selectMock = jest.fn().mockReturnValue({ eq: eqMock });
  return { select: selectMock };
}

// step 2: projects — .select('id').eq('workspace_id',v).is('deleted_at',null)
function makeProjectIdsChain(result: { data: unknown; error: unknown }) {
  const isMock = jest.fn().mockResolvedValue(result);
  const eqMock = jest.fn().mockReturnValue({ is: isMock });
  const selectMock = jest.fn().mockReturnValue({ eq: eqMock });
  return { select: selectMock };
}

// assertUpdateOwnership step 3: .select('id, project_id').eq('id',v).in('project_id',ids).single()
function makeUpdateOwnershipChain(result: { data: unknown; error: unknown }) {
  const singleMock = jest.fn().mockResolvedValue(result);
  const inMock = jest.fn().mockReturnValue({ single: singleMock });
  const eqMock = jest.fn().mockReturnValue({ in: inMock });
  const selectMock = jest.fn().mockReturnValue({ eq: eqMock });
  return { select: selectMock };
}

// deleteAttachment step 3: .select('id').in('project_id', ids)
function makeUpdateIdsChain(result: { data: unknown; error: unknown }) {
  const inMock = jest.fn().mockResolvedValue(result);
  const selectMock = jest.fn().mockReturnValue({ in: inMock });
  return { select: selectMock };
}

// deleteAttachment step 4: .select('id, file_url').eq('id',v).in('update_id',ids).single()
function makeFetchAttachmentWithOwnershipChain(result: { data: unknown; error: unknown }) {
  const singleMock = jest.fn().mockResolvedValue(result);
  const inMock = jest.fn().mockReturnValue({ single: singleMock });
  const eqMock = jest.fn().mockReturnValue({ in: inMock });
  const selectMock = jest.fn().mockReturnValue({ eq: eqMock });
  return { select: selectMock };
}

// countAttachments: .select('*', { count, head }).eq('update_id', v)
function makeCountChain(result: { count: number | null; error: unknown }) {
  const eqMock = jest.fn().mockResolvedValue(result);
  const selectMock = jest.fn().mockReturnValue({ eq: eqMock });
  return { select: selectMock };
}

// insert: .insert({}).select(cols).single()
function makeInsertChain(result: { data: unknown; error: unknown }) {
  const singleMock = jest.fn().mockResolvedValue(result);
  const selectMock = jest.fn().mockReturnValue({ single: singleMock });
  const insertMock = jest.fn().mockReturnValue({ select: selectMock });
  return { insert: insertMock };
}

// delete: .delete({ count: 'exact' }).eq('id', v)
function makeDeleteChain(result: { error: unknown; count: number | null }) {
  const eqMock = jest.fn().mockResolvedValue(result);
  const deleteMock = jest.fn().mockReturnValue({ eq: eqMock });
  return { delete: deleteMock };
}

function makeStorageMock({
  signedUrl = 'https://signed.url/upload',
  path = `${USER_ID}/${UPDATE_ID}/1234-file.pdf`,
  publicUrl = FILE_URL,
  uploadError = null as null | { message: string },
  removeError = null as null | { message: string },
} = {}) {
  const getPublicUrl = jest.fn().mockReturnValue({ data: { publicUrl } });
  const createSignedUploadUrl = jest.fn().mockResolvedValue(
    uploadError ? { data: null, error: uploadError } : { data: { signedUrl, path }, error: null },
  );
  const remove = jest.fn().mockResolvedValue({ error: removeError });
  mockStorageFrom.mockReturnValue({ createSignedUploadUrl, getPublicUrl, remove });
  return { createSignedUploadUrl, getPublicUrl, remove };
}

// Sets up the 3-step assertUpdateOwnership chain (generateSignedUrl + saveAttachment)
function setupUpdateOwnershipChain() {
  mockFrom
    .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
    .mockReturnValueOnce(makeProjectIdsChain({ data: [PROJECT_ROW], error: null }))
    .mockReturnValueOnce(makeUpdateOwnershipChain({ data: UPDATE_ROW, error: null }));
}

// Sets up the 4-step deleteAttachment ownership chain (ws → projects → updates → attachment fetch)
function setupDeleteOwnershipChain(
  attachmentData: unknown = { id: ATTACHMENT_ID, file_url: FILE_URL },
) {
  mockFrom
    .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
    .mockReturnValueOnce(makeProjectIdsChain({ data: [PROJECT_ROW], error: null }))
    .mockReturnValueOnce(makeUpdateIdsChain({ data: [{ id: UPDATE_ID }], error: null }))
    .mockReturnValueOnce(
      makeFetchAttachmentWithOwnershipChain({ data: attachmentData, error: null }),
    );
}

beforeEach(() => jest.clearAllMocks());

// ─── generateAttachmentSignedUrl ──────────────────────────────────────────

describe('generateAttachmentSignedUrl', () => {
  it('returns signedUrl, publicUrl, path on success', async () => {
    setupUpdateOwnershipChain();
    mockFrom.mockReturnValueOnce(makeCountChain({ count: 0, error: null }));
    const { createSignedUploadUrl } = makeStorageMock();

    const result = await generateAttachmentSignedUrl(USER_ID, UPDATE_ID, 'report.pdf', 'application/pdf');

    expect(result.signedUrl).toBe('https://signed.url/upload');
    expect(result.publicUrl).toBe(FILE_URL);
    expect(createSignedUploadUrl).toHaveBeenCalledWith(
      expect.stringMatching(new RegExp(`^${USER_ID}/${UPDATE_ID}/`)),
    );
  });

  it('scopes storage path under different userId than the default', async () => {
    setupUpdateOwnershipChain();
    mockFrom.mockReturnValueOnce(makeCountChain({ count: 0, error: null }));
    const { createSignedUploadUrl } = makeStorageMock();

    await generateAttachmentSignedUrl('other-user', UPDATE_ID, 'doc.pdf', 'application/pdf');

    const calledPath: string = createSignedUploadUrl.mock.calls[0][0];
    expect(calledPath).toMatch(/^other-user\//);
    expect(calledPath).not.toMatch(new RegExp(`^${USER_ID}/`));
  });

  it('throws MAX_ATTACHMENTS when update already has 3', async () => {
    setupUpdateOwnershipChain();
    mockFrom.mockReturnValueOnce(makeCountChain({ count: 3, error: null }));

    await expect(
      generateAttachmentSignedUrl(USER_ID, UPDATE_ID, 'file.pdf', 'application/pdf'),
    ).rejects.toMatchObject({ code: 'MAX_ATTACHMENTS', statusCode: 409 });
  });

  it('throws INVALID_FILE_TYPE for blocked single extensions', async () => {
    for (const name of ['malware.exe', 'script.sh', 'page.php', 'hack.py', 'inject.js']) {
      setupUpdateOwnershipChain();
      mockFrom.mockReturnValueOnce(makeCountChain({ count: 0, error: null }));

      await expect(
        generateAttachmentSignedUrl(USER_ID, UPDATE_ID, name, 'application/octet-stream'),
      ).rejects.toMatchObject({ code: 'INVALID_FILE_TYPE', statusCode: 400 });
    }
  });

  it('blocks dangerous final extension regardless of intermediate extensions', async () => {
    setupUpdateOwnershipChain();
    mockFrom.mockReturnValueOnce(makeCountChain({ count: 0, error: null }));

    // evil.pdf.exe — final ext is .exe, must be blocked
    await expect(
      generateAttachmentSignedUrl(USER_ID, UPDATE_ID, 'evil.pdf.exe', 'application/octet-stream'),
    ).rejects.toMatchObject({ code: 'INVALID_FILE_TYPE' });
  });

  it('allows safe final extension when name contains a blocked inner segment', async () => {
    setupUpdateOwnershipChain();
    mockFrom.mockReturnValueOnce(makeCountChain({ count: 0, error: null }));
    makeStorageMock();

    // evil.exe.pdf — final ext is .pdf, should pass extension check
    await expect(
      generateAttachmentSignedUrl(USER_ID, UPDATE_ID, 'evil.exe.pdf', 'application/pdf'),
    ).resolves.toBeDefined();
  });

  // Fix #7 (round 2)
  it('throws VALIDATION_ERROR for filename with no alphanumeric characters', async () => {
    setupUpdateOwnershipChain();
    mockFrom.mockReturnValueOnce(makeCountChain({ count: 0, error: null }));

    await expect(
      generateAttachmentSignedUrl(USER_ID, UPDATE_ID, '!!!!.???', 'application/octet-stream'),
    ).rejects.toMatchObject({ code: 'VALIDATION_ERROR', statusCode: 400 });
  });

  it('throws NOT_FOUND when update not owned by user', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain({ data: [PROJECT_ROW], error: null }))
      .mockReturnValueOnce(makeUpdateOwnershipChain({ data: null, error: { code: 'PGRST116' } }));

    await expect(
      generateAttachmentSignedUrl(USER_ID, UPDATE_ID, 'file.pdf', 'application/pdf'),
    ).rejects.toMatchObject({ code: 'NOT_FOUND', statusCode: 404 });
  });

  it('throws STORAGE_ERROR when Supabase storage fails', async () => {
    setupUpdateOwnershipChain();
    mockFrom.mockReturnValueOnce(makeCountChain({ count: 0, error: null }));
    makeStorageMock({ uploadError: { message: 'bucket missing' } });

    await expect(
      generateAttachmentSignedUrl(USER_ID, UPDATE_ID, 'file.pdf', 'application/pdf'),
    ).rejects.toMatchObject({ code: 'STORAGE_ERROR', statusCode: 500 });
  });
});

// ─── saveAttachment ────────────────────────────────────────────────────────

describe('saveAttachment', () => {
  const VALID_INPUT = {
    file_url: FILE_URL,
    file_name: 'report.pdf',
    file_size: 1024,
    mime_type: 'application/pdf',
  };

  it('inserts and returns attachment on success', async () => {
    setupUpdateOwnershipChain();
    mockFrom.mockReturnValueOnce(makeCountChain({ count: 0, error: null }));
    mockFrom.mockReturnValueOnce(makeInsertChain({ data: ATTACHMENT_ROW, error: null }));

    const result = await saveAttachment(USER_ID, UPDATE_ID, VALID_INPUT);
    expect(result).toEqual(ATTACHMENT_ROW);
  });

  it('throws MAX_ATTACHMENTS when update already has 3', async () => {
    setupUpdateOwnershipChain();
    mockFrom.mockReturnValueOnce(makeCountChain({ count: 3, error: null }));

    await expect(saveAttachment(USER_ID, UPDATE_ID, VALID_INPUT)).rejects.toMatchObject({
      code: 'MAX_ATTACHMENTS',
      statusCode: 409,
    });
  });

  // Fix #1 + round-2 fix #3: custom SQLSTATE CP001, not P0001.
  it('throws MAX_ATTACHMENTS when DB trigger fires (TOCTOU race — CP001)', async () => {
    setupUpdateOwnershipChain();
    mockFrom.mockReturnValueOnce(makeCountChain({ count: 2, error: null }));
    mockFrom.mockReturnValueOnce(
      makeInsertChain({
        data: null,
        error: { code: 'CP001', message: 'MAX_ATTACHMENTS: update upd-1 already has 3 attachments' },
      }),
    );

    await expect(saveAttachment(USER_ID, UPDATE_ID, VALID_INPUT)).rejects.toMatchObject({
      code: 'MAX_ATTACHMENTS',
      statusCode: 409,
    });
  });

  it('throws FILE_TOO_LARGE when file_size exceeds 10MB', async () => {
    setupUpdateOwnershipChain();
    mockFrom.mockReturnValueOnce(makeCountChain({ count: 0, error: null }));

    await expect(
      saveAttachment(USER_ID, UPDATE_ID, { ...VALID_INPUT, file_size: 10 * 1024 * 1024 + 1 }),
    ).rejects.toMatchObject({ code: 'FILE_TOO_LARGE', statusCode: 400 });
  });

  it('accepts file_size exactly at 10MB boundary', async () => {
    setupUpdateOwnershipChain();
    mockFrom.mockReturnValueOnce(makeCountChain({ count: 0, error: null }));
    mockFrom.mockReturnValueOnce(
      makeInsertChain({ data: { ...ATTACHMENT_ROW, file_size: 10 * 1024 * 1024 }, error: null }),
    );

    await expect(
      saveAttachment(USER_ID, UPDATE_ID, { ...VALID_INPUT, file_size: 10 * 1024 * 1024 }),
    ).resolves.toBeDefined();
  });

  it('throws INVALID_FILE_TYPE for dangerous extensions on record save', async () => {
    for (const name of ['malware.exe', 'script.sh', 'inject.js', 'page.php']) {
      setupUpdateOwnershipChain();
      mockFrom.mockReturnValueOnce(makeCountChain({ count: 0, error: null }));

      await expect(
        saveAttachment(USER_ID, UPDATE_ID, {
          ...VALID_INPUT,
          file_name: name,
          file_url: `https://test.supabase.co/storage/v1/object/public/attachments/u/upd/${name}`,
        }),
      ).rejects.toMatchObject({ code: 'INVALID_FILE_TYPE', statusCode: 400 });
    }
  });

  // Fix #7 (round 2)
  it('throws VALIDATION_ERROR for file_name with no alphanumeric characters', async () => {
    setupUpdateOwnershipChain();
    mockFrom.mockReturnValueOnce(makeCountChain({ count: 0, error: null }));

    await expect(
      saveAttachment(USER_ID, UPDATE_ID, { ...VALID_INPUT, file_name: '!!!!.???' }),
    ).rejects.toMatchObject({ code: 'VALIDATION_ERROR', statusCode: 400 });
  });

  it('throws VALIDATION_ERROR when file_url is an arbitrary external URL', async () => {
    setupUpdateOwnershipChain();
    mockFrom.mockReturnValueOnce(makeCountChain({ count: 0, error: null }));

    await expect(
      saveAttachment(USER_ID, UPDATE_ID, { ...VALID_INPUT, file_url: 'https://evil.com/malware.pdf' }),
    ).rejects.toMatchObject({ code: 'VALIDATION_ERROR', statusCode: 400 });
  });

  it('throws VALIDATION_ERROR when file_url uses HTTP instead of HTTPS', async () => {
    setupUpdateOwnershipChain();
    mockFrom.mockReturnValueOnce(makeCountChain({ count: 0, error: null }));

    await expect(
      saveAttachment(USER_ID, UPDATE_ID, {
        ...VALID_INPUT,
        file_url: 'http://test.supabase.co/storage/v1/object/public/attachments/u/f.pdf',
      }),
    ).rejects.toMatchObject({ code: 'VALIDATION_ERROR', statusCode: 400 });
  });

  it('throws NOT_FOUND when update not owned by user', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain({ data: [PROJECT_ROW], error: null }))
      .mockReturnValueOnce(makeUpdateOwnershipChain({ data: null, error: { code: 'PGRST116' } }));

    await expect(saveAttachment(USER_ID, UPDATE_ID, VALID_INPUT)).rejects.toMatchObject({
      code: 'NOT_FOUND',
      statusCode: 404,
    });
  });

  it('throws DB_ERROR on unexpected insert failure', async () => {
    setupUpdateOwnershipChain();
    mockFrom.mockReturnValueOnce(makeCountChain({ count: 0, error: null }));
    mockFrom.mockReturnValueOnce(makeInsertChain({ data: null, error: new Error('db down') }));

    await expect(saveAttachment(USER_ID, UPDATE_ID, VALID_INPUT)).rejects.toMatchObject({
      code: 'DB_ERROR',
      statusCode: 500,
    });
  });
});

// ─── deleteAttachment ──────────────────────────────────────────────────────

describe('deleteAttachment', () => {
  // Fix #4 (round 2): DB record deleted first, then storage. Mock order matches.
  it('deletes DB record then storage file on success', async () => {
    setupDeleteOwnershipChain();
    mockFrom.mockReturnValueOnce(makeDeleteChain({ error: null, count: 1 }));
    const { remove } = makeStorageMock();

    await expect(deleteAttachment(USER_ID, ATTACHMENT_ID)).resolves.toBeUndefined();
    expect(remove).toHaveBeenCalledWith([EXPECTED_STORAGE_PATH]);
  });

  it('throws NOT_FOUND when attachment does not exist in user workspace', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain({ data: [PROJECT_ROW], error: null }))
      .mockReturnValueOnce(makeUpdateIdsChain({ data: [{ id: UPDATE_ID }], error: null }))
      .mockReturnValueOnce(
        makeFetchAttachmentWithOwnershipChain({ data: null, error: { code: 'PGRST116' } }),
      );

    await expect(deleteAttachment(USER_ID, ATTACHMENT_ID)).rejects.toMatchObject({
      code: 'NOT_FOUND',
      statusCode: 404,
    });
  });

  it('throws NOT_FOUND when user has no workspace', async () => {
    mockFrom.mockReturnValueOnce(makeWsLimitChain({ data: [], error: null }));

    await expect(deleteAttachment(USER_ID, ATTACHMENT_ID)).rejects.toMatchObject({
      code: 'NOT_FOUND',
      statusCode: 404,
    });
  });

  // Fix #6 (round 2): test for zero-updates case
  it('throws NOT_FOUND when workspace has projects but no updates', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain({ data: [PROJECT_ROW], error: null }))
      .mockReturnValueOnce(makeUpdateIdsChain({ data: [], error: null }));

    await expect(deleteAttachment(USER_ID, ATTACHMENT_ID)).rejects.toMatchObject({
      code: 'NOT_FOUND',
      statusCode: 404,
    });
  });

  it('resolves successfully even when storage delete fails (file orphaned, no throw)', async () => {
    setupDeleteOwnershipChain();
    mockFrom.mockReturnValueOnce(makeDeleteChain({ error: null, count: 1 }));
    makeStorageMock({ removeError: { message: 'not found in storage' } });

    await expect(deleteAttachment(USER_ID, ATTACHMENT_ID)).resolves.toBeUndefined();
  });

  // Fix #5 (round 2): assert storage.from itself not called, not just remove.
  it('skips storage.from entirely when file_url does not match attachments bucket pattern', async () => {
    const rowWithExternalUrl = { id: ATTACHMENT_ID, file_url: 'https://cdn.example.com/f.pdf' };
    setupDeleteOwnershipChain(rowWithExternalUrl);
    mockFrom.mockReturnValueOnce(makeDeleteChain({ error: null, count: 1 }));

    await deleteAttachment(USER_ID, ATTACHMENT_ID);
    expect(mockStorageFrom).not.toHaveBeenCalled();
  });

  it('resolves successfully when DB count is 0 (concurrent delete already completed)', async () => {
    setupDeleteOwnershipChain();
    mockFrom.mockReturnValueOnce(makeDeleteChain({ error: null, count: 0 }));
    makeStorageMock();

    await expect(deleteAttachment(USER_ID, ATTACHMENT_ID)).resolves.toBeUndefined();
  });

  it('throws DB_ERROR when delete returns null count', async () => {
    setupDeleteOwnershipChain();
    mockFrom.mockReturnValueOnce(makeDeleteChain({ error: null, count: null }));

    await expect(deleteAttachment(USER_ID, ATTACHMENT_ID)).rejects.toMatchObject({
      code: 'DB_ERROR',
      statusCode: 500,
    });
  });

  it('throws DB_ERROR when delete query fails', async () => {
    setupDeleteOwnershipChain();
    mockFrom.mockReturnValueOnce(makeDeleteChain({ error: new Error('db down'), count: null }));

    await expect(deleteAttachment(USER_ID, ATTACHMENT_ID)).rejects.toMatchObject({
      code: 'DB_ERROR',
      statusCode: 500,
    });
  });
});
