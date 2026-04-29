import { supabaseAdmin } from '../config/adminDb';

jest.mock('../config/adminDb', () => ({
  supabaseAdmin: {
    from: jest.fn(),
    auth: {
      admin: {
        generateLink: jest.fn(),
        deleteUser: jest.fn(),
      },
    },
  },
}));

jest.mock('../services/email.service', () => ({
  sendInviteEmail: jest.fn(),
}));

import { inviteMember, listMembers, removeMember } from '../services/member.service';
import { sendInviteEmail } from '../services/email.service';
import { AppError } from '../middleware/errorHandler';

const mockFrom = supabaseAdmin.from as jest.Mock;
const mockGenerateLink = supabaseAdmin.auth.admin.generateLink as jest.Mock;
const mockDeleteUser = supabaseAdmin.auth.admin.deleteUser as jest.Mock;
const mockSendInviteEmail = sendInviteEmail as jest.Mock;

const USER_ID      = 'a0000000-0000-0000-0000-000000000001';
const MEMBER_ID    = 'a0000000-0000-0000-0000-000000000002';
const OLD_ID       = 'a0000000-0000-0000-0000-000000000003';
const WORKSPACE_ID = 'b0000000-0000-0000-0000-000000000001';

const CALLER_ADMIN  = { workspace_id: WORKSPACE_ID, role: 'admin' };
const CALLER_MEMBER = { workspace_id: WORKSPACE_ID, role: 'member' };

const MEMBER_ROW = {
  id: MEMBER_ID,
  email: 'new@example.com',
  name: '',
  role: 'member' as const,
  invited_at: '2026-01-01T00:00:00Z',
  created_at: '2026-01-01T00:00:00Z',
};

const LINK_DATA = {
  user: { id: MEMBER_ID },
  properties: { action_link: 'https://supabase.co/invite?token=abc' },
};

// ─── Chain builders ───────────────────────────────────────────────────────────

// select.eq('id').is.single  (getCallerContext, target fetch)
function makeSelectSingleChain(result: { data: unknown; error: unknown }) {
  const single = jest.fn().mockResolvedValue(result);
  const is     = jest.fn().mockReturnValue({ single });
  const eq     = jest.fn().mockReturnValue({ is });
  const select = jest.fn().mockReturnValue({ eq });
  return { select };
}

// select.eq('workspace_id').eq('email').maybeSingle  (existing check)
function makeExistingChain(result: { data: unknown; error: unknown }) {
  const maybeSingle = jest.fn().mockResolvedValue(result);
  const eq2         = jest.fn().mockReturnValue({ maybeSingle });
  const eq1         = jest.fn().mockReturnValue({ eq: eq2 });
  const select      = jest.fn().mockReturnValue({ eq: eq1 });
  return { select };
}

// delete.eq  (purge soft-deleted row)
function makeDeleteEqChain(result: { data: unknown; error: unknown }) {
  const eq     = jest.fn().mockResolvedValue(result);
  const del    = jest.fn().mockReturnValue({ eq });
  return { delete: del };
}

// select.eq.single  (workspace name)
function makeWsNameChain(result: { data: unknown; error: unknown }) {
  const single = jest.fn().mockResolvedValue(result);
  const eq     = jest.fn().mockReturnValue({ single });
  const select = jest.fn().mockReturnValue({ eq });
  return { select };
}

// insert.select.single  (fresh insert)
function makeInsertChain(result: { data: unknown; error: unknown }) {
  const single = jest.fn().mockResolvedValue(result);
  const select = jest.fn().mockReturnValue({ single });
  const insert = jest.fn().mockReturnValue({ select });
  return { insert };
}

// select.eq.is.order  (listMembers)
function makeListChain(result: { data: unknown; error: unknown }) {
  const order  = jest.fn().mockResolvedValue(result);
  const is     = jest.fn().mockReturnValue({ order });
  const eq     = jest.fn().mockReturnValue({ is });
  const select = jest.fn().mockReturnValue({ eq });
  return { select };
}

// select('*',{count}).eq.eq.is  (admin count)
function makeCountChain(result: { count: number | null; error: unknown }) {
  const is     = jest.fn().mockResolvedValue(result);
  const eq2    = jest.fn().mockReturnValue({ is });
  const eq1    = jest.fn().mockReturnValue({ eq: eq2 });
  const select = jest.fn().mockReturnValue({ eq: eq1 });
  return { select };
}

// Fix #7: update.eq('id').eq('workspace_id').select('id')  (soft-delete)
function makeSoftDeleteChain(result: { data: unknown; error: unknown }) {
  const select = jest.fn().mockResolvedValue(result);
  const eq2    = jest.fn().mockReturnValue({ select });
  const eq1    = jest.fn().mockReturnValue({ eq: eq2 });
  const update = jest.fn().mockReturnValue({ eq: eq1 });
  return { update };
}

// Helper: set up a standard fresh-invite mock sequence (no pre-existing row)
function setupFreshInvite(insertResult: { data: unknown; error: unknown }) {
  mockFrom
    .mockReturnValueOnce(makeSelectSingleChain({ data: CALLER_ADMIN, error: null }))
    .mockReturnValueOnce(makeExistingChain({ data: null, error: null }))
    .mockReturnValueOnce(makeWsNameChain({ data: { name: 'Acme' }, error: null }))
    .mockReturnValueOnce(makeInsertChain(insertResult));
  mockGenerateLink.mockResolvedValueOnce({ data: LINK_DATA, error: null });
}

beforeEach(() => {
  jest.clearAllMocks();
  mockDeleteUser.mockResolvedValue({ data: {}, error: null });
  mockSendInviteEmail.mockResolvedValue(undefined);
});

// ─── inviteMember ─────────────────────────────────────────────────────────────

describe('inviteMember', () => {
  it('returns member and sends email on fresh invite', async () => {
    setupFreshInvite({ data: MEMBER_ROW, error: null });

    const result = await inviteMember(USER_ID, 'new@example.com', 'member');

    expect(result).toEqual(MEMBER_ROW);
    expect(mockSendInviteEmail).toHaveBeenCalledWith(
      'new@example.com',
      'Acme',
      LINK_DATA.properties.action_link,
    );
  });

  // Fix #5: email is normalized to lowercase
  it('normalizes email to lowercase before all operations', async () => {
    setupFreshInvite({ data: { ...MEMBER_ROW, email: 'new@example.com' }, error: null });

    await inviteMember(USER_ID, 'NEW@EXAMPLE.COM', 'member');

    // sendInviteEmail should receive the lowercased email
    expect(mockSendInviteEmail).toHaveBeenCalledWith('new@example.com', expect.any(String), expect.any(String));
  });

  it('throws FORBIDDEN when caller is not admin', async () => {
    mockFrom.mockReturnValueOnce(makeSelectSingleChain({ data: CALLER_MEMBER, error: null }));

    await expect(inviteMember(USER_ID, 'x@x.com', 'member')).rejects.toMatchObject({
      code: 'FORBIDDEN',
      statusCode: 403,
    });
    expect(mockGenerateLink).not.toHaveBeenCalled();
  });

  it('throws NOT_FOUND when caller has no users record', async () => {
    mockFrom.mockReturnValueOnce(makeSelectSingleChain({ data: null, error: { code: 'PGRST116' } }));

    await expect(inviteMember(USER_ID, 'x@x.com', 'member')).rejects.toMatchObject({
      code: 'NOT_FOUND',
      statusCode: 404,
    });
  });

  it('throws CONFLICT when member is already active', async () => {
    mockFrom
      .mockReturnValueOnce(makeSelectSingleChain({ data: CALLER_ADMIN, error: null }))
      .mockReturnValueOnce(makeExistingChain({ data: { id: MEMBER_ID, deleted_at: null }, error: null }));

    await expect(inviteMember(USER_ID, 'existing@example.com', 'member')).rejects.toMatchObject({
      code: 'CONFLICT',
      statusCode: 409,
    });
    expect(mockGenerateLink).not.toHaveBeenCalled();
  });

  it('throws NOT_FOUND when workspace lookup fails', async () => {
    mockFrom
      .mockReturnValueOnce(makeSelectSingleChain({ data: CALLER_ADMIN, error: null }))
      .mockReturnValueOnce(makeExistingChain({ data: null, error: null }))
      .mockReturnValueOnce(makeWsNameChain({ data: null, error: { code: 'PGRST116' } }));

    await expect(inviteMember(USER_ID, 'x@x.com', 'member')).rejects.toMatchObject({
      code: 'NOT_FOUND',
      statusCode: 404,
    });
    expect(mockGenerateLink).not.toHaveBeenCalled();
  });

  it('throws DB_ERROR when generateLink fails', async () => {
    mockFrom
      .mockReturnValueOnce(makeSelectSingleChain({ data: CALLER_ADMIN, error: null }))
      .mockReturnValueOnce(makeExistingChain({ data: null, error: null }))
      .mockReturnValueOnce(makeWsNameChain({ data: { name: 'Acme' }, error: null }));
    mockGenerateLink.mockResolvedValueOnce({ data: null, error: new Error('auth failure') });

    await expect(inviteMember(USER_ID, 'x@x.com', 'member')).rejects.toMatchObject({
      code: 'DB_ERROR',
      statusCode: 500,
    });
  });

  it('throws CONFLICT on 23505 insert error and rolls back auth user', async () => {
    setupFreshInvite({ data: null, error: { code: '23505' } });

    await expect(inviteMember(USER_ID, 'new@example.com', 'member')).rejects.toMatchObject({
      code: 'CONFLICT',
      statusCode: 409,
    });
    expect(mockDeleteUser).toHaveBeenCalledWith(MEMBER_ID);
  });

  it('throws DB_ERROR on generic insert failure and rolls back auth user', async () => {
    setupFreshInvite({ data: null, error: { code: '99999' } });

    await expect(inviteMember(USER_ID, 'new@example.com', 'member')).rejects.toMatchObject({
      code: 'DB_ERROR',
      statusCode: 500,
    });
    expect(mockDeleteUser).toHaveBeenCalledWith(MEMBER_ID);
  });

  // Fix #13: email failure path
  it('rolls back auth user (cascade) when email fails and throws EMAIL_ERROR', async () => {
    setupFreshInvite({ data: MEMBER_ROW, error: null });
    mockSendInviteEmail.mockRejectedValueOnce(new AppError('Email delivery failed', 502, 'EMAIL_ERROR'));

    await expect(inviteMember(USER_ID, 'new@example.com', 'member')).rejects.toMatchObject({
      code: 'EMAIL_ERROR',
      statusCode: 502,
    });
    expect(mockDeleteUser).toHaveBeenCalledWith(MEMBER_ID);
  });

  // Fix #8: INTERNAL_ERROR from sendInviteEmail must propagate, not trigger rollback
  it('propagates INTERNAL_ERROR from email service without rolling back', async () => {
    setupFreshInvite({ data: MEMBER_ROW, error: null });
    mockSendInviteEmail.mockRejectedValueOnce(new AppError('Invalid invite URL', 500, 'INTERNAL_ERROR'));

    await expect(inviteMember(USER_ID, 'new@example.com', 'member')).rejects.toMatchObject({
      code: 'INTERNAL_ERROR',
      statusCode: 500,
    });
    expect(mockDeleteUser).not.toHaveBeenCalled();
  });

  // Fix #14: re-invite soft-deleted member (unified path — purge first, then fresh insert)
  it('purges soft-deleted row and re-invites as fresh insert', async () => {
    const softDeleted = { id: OLD_ID, deleted_at: '2025-12-01T00:00:00Z' };

    mockFrom
      .mockReturnValueOnce(makeSelectSingleChain({ data: CALLER_ADMIN, error: null }))
      .mockReturnValueOnce(makeExistingChain({ data: softDeleted, error: null }))
      .mockReturnValueOnce(makeDeleteEqChain({ data: null, error: null }))
      .mockReturnValueOnce(makeWsNameChain({ data: { name: 'Acme' }, error: null }))
      .mockReturnValueOnce(makeInsertChain({ data: MEMBER_ROW, error: null }));
    mockGenerateLink.mockResolvedValueOnce({ data: LINK_DATA, error: null });

    const result = await inviteMember(USER_ID, 'old@example.com', 'member');

    expect(result).toEqual(MEMBER_ROW);
    expect(mockSendInviteEmail).toHaveBeenCalled();
  });

  // Fix #10: re-invite email failure also rolls back correctly
  it('rolls back auth user when email fails during re-invite', async () => {
    const softDeleted = { id: OLD_ID, deleted_at: '2025-12-01T00:00:00Z' };

    mockFrom
      .mockReturnValueOnce(makeSelectSingleChain({ data: CALLER_ADMIN, error: null }))
      .mockReturnValueOnce(makeExistingChain({ data: softDeleted, error: null }))
      .mockReturnValueOnce(makeDeleteEqChain({ data: null, error: null }))
      .mockReturnValueOnce(makeWsNameChain({ data: { name: 'Acme' }, error: null }))
      .mockReturnValueOnce(makeInsertChain({ data: MEMBER_ROW, error: null }));
    mockGenerateLink.mockResolvedValueOnce({ data: LINK_DATA, error: null });
    mockSendInviteEmail.mockRejectedValueOnce(new AppError('Email delivery failed', 502, 'EMAIL_ERROR'));

    await expect(inviteMember(USER_ID, 'old@example.com', 'member')).rejects.toMatchObject({
      code: 'EMAIL_ERROR',
      statusCode: 502,
    });
    expect(mockDeleteUser).toHaveBeenCalledWith(MEMBER_ID);
  });
});

// ─── listMembers ──────────────────────────────────────────────────────────────

describe('listMembers', () => {
  it('returns members array', async () => {
    mockFrom
      .mockReturnValueOnce(makeSelectSingleChain({ data: CALLER_ADMIN, error: null }))
      .mockReturnValueOnce(makeListChain({ data: [MEMBER_ROW], error: null }));

    expect(await listMembers(USER_ID)).toEqual([MEMBER_ROW]);
  });

  it('returns empty array when workspace has no members', async () => {
    mockFrom
      .mockReturnValueOnce(makeSelectSingleChain({ data: CALLER_ADMIN, error: null }))
      .mockReturnValueOnce(makeListChain({ data: null, error: null }));

    expect(await listMembers(USER_ID)).toEqual([]);
  });

  it('throws NOT_FOUND when caller has no users record', async () => {
    mockFrom.mockReturnValueOnce(makeSelectSingleChain({ data: null, error: { code: 'PGRST116' } }));

    await expect(listMembers(USER_ID)).rejects.toMatchObject({ code: 'NOT_FOUND', statusCode: 404 });
  });

  it('throws DB_ERROR on list query failure', async () => {
    mockFrom
      .mockReturnValueOnce(makeSelectSingleChain({ data: CALLER_ADMIN, error: null }))
      .mockReturnValueOnce(makeListChain({ data: null, error: new Error('db down') }));

    await expect(listMembers(USER_ID)).rejects.toMatchObject({ code: 'DB_ERROR', statusCode: 500 });
  });
});

// ─── removeMember ─────────────────────────────────────────────────────────────

describe('removeMember', () => {
  const TARGET_MEMBER = { id: MEMBER_ID, workspace_id: WORKSPACE_ID, role: 'member' };
  const TARGET_ADMIN  = { id: MEMBER_ID, workspace_id: WORKSPACE_ID, role: 'admin' };

  it('soft-deletes a non-admin member', async () => {
    mockFrom
      .mockReturnValueOnce(makeSelectSingleChain({ data: CALLER_ADMIN, error: null }))
      .mockReturnValueOnce(makeSelectSingleChain({ data: TARGET_MEMBER, error: null }))
      .mockReturnValueOnce(makeSoftDeleteChain({ data: [{ id: MEMBER_ID }], error: null }));

    await expect(removeMember(USER_ID, MEMBER_ID)).resolves.toBeUndefined();
  });

  it('throws FORBIDDEN when caller is not admin', async () => {
    mockFrom.mockReturnValueOnce(makeSelectSingleChain({ data: CALLER_MEMBER, error: null }));

    await expect(removeMember(USER_ID, MEMBER_ID)).rejects.toMatchObject({
      code: 'FORBIDDEN', statusCode: 403,
    });
  });

  it('throws VALIDATION_ERROR when removing self', async () => {
    mockFrom.mockReturnValueOnce(makeSelectSingleChain({ data: CALLER_ADMIN, error: null }));

    await expect(removeMember(USER_ID, USER_ID)).rejects.toMatchObject({
      code: 'VALIDATION_ERROR', statusCode: 400,
    });
  });

  it('throws NOT_FOUND when member does not exist', async () => {
    mockFrom
      .mockReturnValueOnce(makeSelectSingleChain({ data: CALLER_ADMIN, error: null }))
      .mockReturnValueOnce(makeSelectSingleChain({ data: null, error: { code: 'PGRST116' } }));

    await expect(removeMember(USER_ID, MEMBER_ID)).rejects.toMatchObject({
      code: 'NOT_FOUND', statusCode: 404,
    });
  });

  it('throws NOT_FOUND when member belongs to different workspace', async () => {
    mockFrom
      .mockReturnValueOnce(makeSelectSingleChain({ data: CALLER_ADMIN, error: null }))
      .mockReturnValueOnce(makeSelectSingleChain({
        data: { ...TARGET_MEMBER, workspace_id: 'c0000000-0000-0000-0000-000000000001' },
        error: null,
      }));

    await expect(removeMember(USER_ID, MEMBER_ID)).rejects.toMatchObject({
      code: 'NOT_FOUND', statusCode: 404,
    });
  });

  it('throws VALIDATION_ERROR when removing the last admin', async () => {
    mockFrom
      .mockReturnValueOnce(makeSelectSingleChain({ data: CALLER_ADMIN, error: null }))
      .mockReturnValueOnce(makeSelectSingleChain({ data: TARGET_ADMIN, error: null }))
      .mockReturnValueOnce(makeCountChain({ count: 1, error: null }));

    await expect(removeMember(USER_ID, MEMBER_ID)).rejects.toMatchObject({
      code: 'VALIDATION_ERROR', statusCode: 400,
    });
  });

  // Fix #1: count query error must surface, not be swallowed
  it('throws DB_ERROR when admin count query fails', async () => {
    mockFrom
      .mockReturnValueOnce(makeSelectSingleChain({ data: CALLER_ADMIN, error: null }))
      .mockReturnValueOnce(makeSelectSingleChain({ data: TARGET_ADMIN, error: null }))
      .mockReturnValueOnce(makeCountChain({ count: null, error: new Error('db timeout') }));

    await expect(removeMember(USER_ID, MEMBER_ID)).rejects.toMatchObject({
      code: 'DB_ERROR', statusCode: 500,
    });
  });

  it('allows removing a non-last admin', async () => {
    mockFrom
      .mockReturnValueOnce(makeSelectSingleChain({ data: CALLER_ADMIN, error: null }))
      .mockReturnValueOnce(makeSelectSingleChain({ data: TARGET_ADMIN, error: null }))
      .mockReturnValueOnce(makeCountChain({ count: 2, error: null }))
      .mockReturnValueOnce(makeSoftDeleteChain({ data: [{ id: MEMBER_ID }], error: null }));

    await expect(removeMember(USER_ID, MEMBER_ID)).resolves.toBeUndefined();
  });

  // Fix #7: concurrent removal returns NOT_FOUND, not silent 204
  it('throws NOT_FOUND when member was concurrently removed (0 rows updated)', async () => {
    mockFrom
      .mockReturnValueOnce(makeSelectSingleChain({ data: CALLER_ADMIN, error: null }))
      .mockReturnValueOnce(makeSelectSingleChain({ data: TARGET_MEMBER, error: null }))
      .mockReturnValueOnce(makeSoftDeleteChain({ data: [], error: null }));

    await expect(removeMember(USER_ID, MEMBER_ID)).rejects.toMatchObject({
      code: 'NOT_FOUND', statusCode: 404,
    });
  });

  it('throws DB_ERROR when soft-delete query fails', async () => {
    mockFrom
      .mockReturnValueOnce(makeSelectSingleChain({ data: CALLER_ADMIN, error: null }))
      .mockReturnValueOnce(makeSelectSingleChain({ data: TARGET_MEMBER, error: null }))
      .mockReturnValueOnce(makeSoftDeleteChain({ data: null, error: new Error('db down') }));

    await expect(removeMember(USER_ID, MEMBER_ID)).rejects.toMatchObject({
      code: 'DB_ERROR', statusCode: 500,
    });
  });
});
