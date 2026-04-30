import { supabaseAdmin } from '../config/adminDb';

jest.mock('../config/adminDb', () => ({
  supabaseAdmin: { from: jest.fn() },
}));

import {
  createUpdate,
  listUpdates,
  getUpdate,
  editUpdate,
  deleteUpdate,
} from '../services/update.service';

const mockFrom = supabaseAdmin.from as jest.Mock;

const USER_ID = '00000000-0000-0000-0000-000000000001';
const WORKSPACE_ID = '00000000-0000-0000-0000-000000000002';
const PROJECT_ID = '00000000-0000-0000-0000-000000000003';
const UPDATE_ID = '00000000-0000-0000-0000-000000000004';

const WORKSPACE_ROW = { id: WORKSPACE_ID };
const PROJECT_ROW = { id: PROJECT_ID };
const UPDATE_ROW = {
  id: UPDATE_ID,
  project_id: PROJECT_ID,
  author_id: USER_ID,
  title: 'Week 1',
  body: 'Progress on backend',
  status: 'draft',
  category: 'progress',
  position: 0,
  notification_sent_at: null,
  created_at: '2026-01-01T00:00:00Z',
  updated_at: '2026-01-01T00:00:00Z',
};

// getWorkspaceIdForUser: .select('id').eq('owner_id',v).is('deleted_at',null).limit(1)
function makeWsLimitChain(result: { data: unknown; error: unknown }) {
  const limitMock = jest.fn().mockResolvedValue(result);
  const isMock = jest.fn().mockReturnValue({ limit: limitMock });
  const eqMock = jest.fn().mockReturnValue({ is: isMock });
  const selectMock = jest.fn().mockReturnValue({ eq: eqMock });
  return { select: selectMock };
}

// assertProjectOwnership: .select('id').eq('id',v).eq('workspace_id',v).is('deleted_at',null).single()
function makeProjectOwnershipChain(result: { data: unknown; error: unknown }) {
  const singleMock = jest.fn().mockResolvedValue(result);
  const isMock = jest.fn().mockReturnValue({ single: singleMock });
  const eq2Mock = jest.fn().mockReturnValue({ is: isMock });
  const eq1Mock = jest.fn().mockReturnValue({ eq: eq2Mock });
  const selectMock = jest.fn().mockReturnValue({ eq: eq1Mock });
  return { select: selectMock };
}

// createUpdate: .insert({}).select(cols).single()
function makeInsertChain(result: { data: unknown; error: unknown }) {
  const singleMock = jest.fn().mockResolvedValue(result);
  const selectMock = jest.fn().mockReturnValue({ single: singleMock });
  const insertMock = jest.fn().mockReturnValue({ select: selectMock });
  return { insert: insertMock };
}

// listUpdates: .select(cols).eq('project_id',v).order(...)
function makeListChain(result: { data: unknown; error: unknown }) {
  const orderMock = jest.fn().mockResolvedValue(result);
  const eqMock = jest.fn().mockReturnValue({ order: orderMock });
  const selectMock = jest.fn().mockReturnValue({ eq: eqMock });
  return { select: selectMock };
}

// getProjectIdsForWorkspace: .select('id').eq('workspace_id',v).is('deleted_at',null)
function makeProjectIdsChain(result: { data: unknown; error: unknown }) {
  const isMock = jest.fn().mockResolvedValue(result);
  const eqMock = jest.fn().mockReturnValue({ is: isMock });
  const selectMock = jest.fn().mockReturnValue({ eq: eqMock });
  return { select: selectMock };
}

// getUpdate (new): .select(UPDATE_COLUMNS).eq('id',v).in('project_id', ids).single()
function makeGetUpdateChain(result: { data: unknown; error: unknown }) {
  const singleMock = jest.fn().mockResolvedValue(result);
  const inMock = jest.fn().mockReturnValue({ single: singleMock });
  const eqMock = jest.fn().mockReturnValue({ in: inMock });
  const selectMock = jest.fn().mockReturnValue({ eq: eqMock });
  return { select: selectMock };
}

// attachments fetch: .select(cols).eq('update_id',v)
function makeAttachmentsChain(result: { data: unknown; error: unknown }) {
  const eqMock = jest.fn().mockResolvedValue(result);
  const selectMock = jest.fn().mockReturnValue({ eq: eqMock });
  return { select: selectMock };
}

// comments fetch: .select(cols).eq('update_id',v).order(...)
function makeCommentsChain(result: { data: unknown; error: unknown }) {
  const orderMock = jest.fn().mockResolvedValue(result);
  const eqMock = jest.fn().mockReturnValue({ order: orderMock });
  const selectMock = jest.fn().mockReturnValue({ eq: eqMock });
  return { select: selectMock };
}

// editUpdate: .update(payload).eq('id',v).in('project_id', ids[]).select(cols).single()
function makeEditChain(result: { data: unknown; error: unknown }) {
  const singleMock = jest.fn().mockResolvedValue(result);
  const selectMock = jest.fn().mockReturnValue({ single: singleMock });
  const inMock = jest.fn().mockReturnValue({ select: selectMock });
  const eq1Mock = jest.fn().mockReturnValue({ in: inMock });
  const updateMock = jest.fn().mockReturnValue({ eq: eq1Mock });
  return { update: updateMock };
}

// deleteUpdate: .delete({count:'exact'}).eq('id',v).in('project_id', ids[])
function makeDeleteChain(result: { error: unknown; count: number | null }) {
  const inMock = jest.fn().mockResolvedValue(result);
  const eqMock = jest.fn().mockReturnValue({ in: inMock });
  const deleteMock = jest.fn().mockReturnValue({ eq: eqMock });
  return { delete: deleteMock };
}

const PROJECT_IDS_RESULT = { data: [{ id: PROJECT_ID }], error: null };
const EMPTY_PROJECT_IDS_RESULT = { data: [], error: null };

beforeEach(() => jest.clearAllMocks());

describe('createUpdate', () => {
  it('inserts and returns new update', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectOwnershipChain({ data: PROJECT_ROW, error: null }))
      .mockReturnValueOnce(makeInsertChain({ data: UPDATE_ROW, error: null }));

    const result = await createUpdate(USER_ID, PROJECT_ID, { title: 'Week 1', body: 'Progress' });
    expect(result).toEqual(UPDATE_ROW);
  });

  it('defaults category to progress and status to draft', async () => {
    const insertChain = makeInsertChain({ data: UPDATE_ROW, error: null });
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectOwnershipChain({ data: PROJECT_ROW, error: null }))
      .mockReturnValueOnce(insertChain);

    await createUpdate(USER_ID, PROJECT_ID, { title: 'T', body: 'B' });
    expect(insertChain.insert).toHaveBeenCalledWith(
      expect.objectContaining({ category: 'progress', status: 'draft' }),
    );
  });

  it('strips dangerous HTML from body before insert', async () => {
    const insertChain = makeInsertChain({ data: UPDATE_ROW, error: null });
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectOwnershipChain({ data: PROJECT_ROW, error: null }))
      .mockReturnValueOnce(insertChain);

    await createUpdate(USER_ID, PROJECT_ID, {
      title: 'T',
      body: 'Safe content <script>alert("xss")</script> more content',
    });
    const insertedBody = (insertChain.insert as jest.Mock).mock.calls[0][0].body as string;
    expect(insertedBody).not.toContain('<script>');
    expect(insertedBody).toContain('Safe content');
    expect(insertedBody).toContain('more content');
  });

  it('strips dangerous URI schemes from Markdown links before insert', async () => {
    const insertChain = makeInsertChain({ data: UPDATE_ROW, error: null });
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectOwnershipChain({ data: PROJECT_ROW, error: null }))
      .mockReturnValueOnce(insertChain);

    await createUpdate(USER_ID, PROJECT_ID, {
      title: 'T',
      body: [
        '[js](javascript:alert(1))',
        '[vbs](vbscript:msgbox(1))',
        '[data](data:text/html,<h1>x</h1>)',
        '[safe](https://example.com)',
      ].join(' '),
    });
    const insertedBody = (insertChain.insert as jest.Mock).mock.calls[0][0].body as string;
    expect(insertedBody).not.toContain('javascript:');
    expect(insertedBody).not.toContain('vbscript:');
    expect(insertedBody).not.toContain('data:');
    expect(insertedBody).toContain('[js](#)');
    expect(insertedBody).toContain('[vbs](#)');
    expect(insertedBody).toContain('[data](#)');
    expect(insertedBody).toContain('[safe](https://example.com)');
  });

  it('throws NOT_FOUND when project not in workspace (PGRST116)', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectOwnershipChain({ data: null, error: { code: 'PGRST116' } }));

    await expect(createUpdate(USER_ID, PROJECT_ID, { title: 'T', body: 'B' })).rejects.toMatchObject({
      code: 'NOT_FOUND',
      statusCode: 404,
    });
  });

  it('throws DB_ERROR when assertProjectOwnership has non-PGRST116 DB error', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectOwnershipChain({ data: null, error: { code: 'INTERNAL_ERROR' } }));

    await expect(createUpdate(USER_ID, PROJECT_ID, { title: 'T', body: 'B' })).rejects.toMatchObject({
      code: 'DB_ERROR',
      statusCode: 500,
    });
  });

  it('throws DB_ERROR on insert failure', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectOwnershipChain({ data: PROJECT_ROW, error: null }))
      .mockReturnValueOnce(makeInsertChain({ data: null, error: new Error('db down') }));

    await expect(createUpdate(USER_ID, PROJECT_ID, { title: 'T', body: 'B' })).rejects.toMatchObject({
      code: 'DB_ERROR',
    });
  });
});

describe('listUpdates', () => {
  it('returns updates newest first with attachment_count mapped', async () => {
    const rowWithAttachments = { ...UPDATE_ROW, attachments: [{ count: 2 }] };
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectOwnershipChain({ data: PROJECT_ROW, error: null }))
      .mockReturnValueOnce(makeListChain({ data: [rowWithAttachments], error: null }));

    const result = await listUpdates(USER_ID, PROJECT_ID);
    expect(result).toEqual([{ ...UPDATE_ROW, attachment_count: 2 }]);
  });

  it('maps attachment_count to 0 when attachments array is empty', async () => {
    const rowWithEmpty = { ...UPDATE_ROW, attachments: [] };
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectOwnershipChain({ data: PROJECT_ROW, error: null }))
      .mockReturnValueOnce(makeListChain({ data: [rowWithEmpty], error: null }));

    const result = await listUpdates(USER_ID, PROJECT_ID);
    expect(result).toEqual([{ ...UPDATE_ROW, attachment_count: 0 }]);
  });

  it('maps attachment_count to 0 when attachments is null', async () => {
    const rowWithNull = { ...UPDATE_ROW, attachments: null };
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectOwnershipChain({ data: PROJECT_ROW, error: null }))
      .mockReturnValueOnce(makeListChain({ data: [rowWithNull], error: null }));

    const result = await listUpdates(USER_ID, PROJECT_ID);
    expect(result).toEqual([{ ...UPDATE_ROW, attachment_count: 0 }]);
  });

  it('returns empty array when no updates', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectOwnershipChain({ data: PROJECT_ROW, error: null }))
      .mockReturnValueOnce(makeListChain({ data: null, error: null }));

    const result = await listUpdates(USER_ID, PROJECT_ID);
    expect(result).toEqual([]);
  });

  it('throws NOT_FOUND when project not owned (PGRST116)', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectOwnershipChain({ data: null, error: { code: 'PGRST116' } }));

    await expect(listUpdates(USER_ID, PROJECT_ID)).rejects.toMatchObject({ code: 'NOT_FOUND' });
  });

  it('throws DB_ERROR when assertProjectOwnership has non-PGRST116 DB error', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectOwnershipChain({ data: null, error: { code: 'INTERNAL_ERROR' } }));

    await expect(listUpdates(USER_ID, PROJECT_ID)).rejects.toMatchObject({
      code: 'DB_ERROR',
      statusCode: 500,
    });
  });

  it('throws DB_ERROR on list query failure', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectOwnershipChain({ data: PROJECT_ROW, error: null }))
      .mockReturnValueOnce(makeListChain({ data: null, error: new Error('db down') }));

    await expect(listUpdates(USER_ID, PROJECT_ID)).rejects.toMatchObject({ code: 'DB_ERROR' });
  });
});

describe('getUpdate', () => {
  it('returns update with attachments and comments', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain(PROJECT_IDS_RESULT))
      .mockReturnValueOnce(makeGetUpdateChain({ data: UPDATE_ROW, error: null }))
      .mockReturnValueOnce(makeAttachmentsChain({ data: [], error: null }))
      .mockReturnValueOnce(makeCommentsChain({ data: [], error: null }));

    const result = await getUpdate(USER_ID, UPDATE_ID);
    expect(result.id).toBe(UPDATE_ID);
    expect(result.attachments).toEqual([]);
    expect(result.comments).toEqual([]);
  });

  it('passes workspace project IDs to ownership filter', async () => {
    // Build chain with direct reference to inMock for assertion
    const singleMock = jest.fn().mockResolvedValue({ data: UPDATE_ROW, error: null });
    const inMock = jest.fn().mockReturnValue({ single: singleMock });
    const eqMock = jest.fn().mockReturnValue({ in: inMock });
    const selectMock = jest.fn().mockReturnValue({ eq: eqMock });

    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain(PROJECT_IDS_RESULT))
      .mockReturnValueOnce({ select: selectMock })
      .mockReturnValueOnce(makeAttachmentsChain({ data: [], error: null }))
      .mockReturnValueOnce(makeCommentsChain({ data: [], error: null }));

    await getUpdate(USER_ID, UPDATE_ID);

    expect(inMock).toHaveBeenCalledWith('project_id', [PROJECT_ID]);
  });

  it('throws NOT_FOUND when workspace has no projects', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain(EMPTY_PROJECT_IDS_RESULT));

    await expect(getUpdate(USER_ID, UPDATE_ID)).rejects.toMatchObject({
      code: 'NOT_FOUND',
      statusCode: 404,
    });
  });

  it('throws NOT_FOUND when update not in user workspace', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain(PROJECT_IDS_RESULT))
      .mockReturnValueOnce(makeGetUpdateChain({ data: null, error: { code: 'PGRST116' } }));

    await expect(getUpdate(USER_ID, UPDATE_ID)).rejects.toMatchObject({ code: 'NOT_FOUND' });
  });

  it('throws WORKSPACE_NOT_FOUND when user has no workspace', async () => {
    mockFrom.mockReturnValueOnce(makeWsLimitChain({ data: [], error: null }));

    await expect(getUpdate(USER_ID, UPDATE_ID)).rejects.toMatchObject({
      code: 'WORKSPACE_NOT_FOUND',
    });
  });
});

describe('editUpdate', () => {
  it('updates fields and returns updated row', async () => {
    const updated = { ...UPDATE_ROW, title: 'Week 2' };
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain(PROJECT_IDS_RESULT))
      .mockReturnValueOnce(makeEditChain({ data: updated, error: null }));

    const result = await editUpdate(USER_ID, UPDATE_ID, { title: 'Week 2' });
    expect(result.title).toBe('Week 2');
  });

  it('strips dangerous HTML from body', async () => {
    const editChain = makeEditChain({ data: UPDATE_ROW, error: null });
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain(PROJECT_IDS_RESULT))
      .mockReturnValueOnce(editChain);

    await editUpdate(USER_ID, UPDATE_ID, { body: 'Clean <script>xss()</script> text' });
    const payload = (editChain.update as jest.Mock).mock.calls[0][0] as Record<string, unknown>;
    expect(payload.body as string).not.toContain('<script>');
    expect(payload.body as string).toContain('Clean');
  });

  it('updates position field', async () => {
    const editChain = makeEditChain({ data: { ...UPDATE_ROW, position: 3 }, error: null });
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain(PROJECT_IDS_RESULT))
      .mockReturnValueOnce(editChain);

    const result = await editUpdate(USER_ID, UPDATE_ID, { position: 3 });
    expect(result.position).toBe(3);
    expect(editChain.update).toHaveBeenCalledWith(expect.objectContaining({ position: 3 }));
  });

  it('throws VALIDATION_ERROR when no fields provided', async () => {
    mockFrom.mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }));

    await expect(editUpdate(USER_ID, UPDATE_ID, {})).rejects.toMatchObject({
      code: 'VALIDATION_ERROR',
      statusCode: 400,
    });
  });

  it('throws NOT_FOUND when workspace has no projects', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain(EMPTY_PROJECT_IDS_RESULT));

    await expect(editUpdate(USER_ID, UPDATE_ID, { title: 'X' })).rejects.toMatchObject({
      code: 'NOT_FOUND',
      statusCode: 404,
    });
  });

  it('throws NOT_FOUND when update does not exist or not owned (PGRST116)', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain(PROJECT_IDS_RESULT))
      .mockReturnValueOnce(makeEditChain({ data: null, error: { code: 'PGRST116' } }));

    await expect(editUpdate(USER_ID, UPDATE_ID, { title: 'X' })).rejects.toMatchObject({
      code: 'NOT_FOUND',
    });
  });

  it('throws DB_ERROR when data is null without error', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain(PROJECT_IDS_RESULT))
      .mockReturnValueOnce(makeEditChain({ data: null, error: null }));

    await expect(editUpdate(USER_ID, UPDATE_ID, { title: 'X' })).rejects.toMatchObject({
      code: 'DB_ERROR',
      statusCode: 500,
    });
  });
});

describe('deleteUpdate', () => {
  it('hard-deletes update without error', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain(PROJECT_IDS_RESULT))
      .mockReturnValueOnce(makeDeleteChain({ error: null, count: 1 }));

    await expect(deleteUpdate(USER_ID, UPDATE_ID)).resolves.toBeUndefined();
  });

  it('throws NOT_FOUND when workspace has no projects', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain(EMPTY_PROJECT_IDS_RESULT));

    await expect(deleteUpdate(USER_ID, UPDATE_ID)).rejects.toMatchObject({
      code: 'NOT_FOUND',
      statusCode: 404,
    });
  });

  it('throws NOT_FOUND when count is 0', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain(PROJECT_IDS_RESULT))
      .mockReturnValueOnce(makeDeleteChain({ error: null, count: 0 }));

    await expect(deleteUpdate(USER_ID, UPDATE_ID)).rejects.toMatchObject({ code: 'NOT_FOUND' });
  });

  it('throws DB_ERROR when count is null — deletion unconfirmed', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain(PROJECT_IDS_RESULT))
      .mockReturnValueOnce(makeDeleteChain({ error: null, count: null }));

    await expect(deleteUpdate(USER_ID, UPDATE_ID)).rejects.toMatchObject({
      code: 'DB_ERROR',
      statusCode: 500,
    });
  });

  it('throws DB_ERROR on delete query failure', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain(PROJECT_IDS_RESULT))
      .mockReturnValueOnce(makeDeleteChain({ error: new Error('db down'), count: null }));

    await expect(deleteUpdate(USER_ID, UPDATE_ID)).rejects.toMatchObject({ code: 'DB_ERROR' });
  });
});
