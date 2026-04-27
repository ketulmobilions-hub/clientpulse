import { supabase } from '../config/db';
import { supabaseAdmin } from '../config/adminDb';

jest.mock('../config/db', () => ({ supabase: { auth: { signInWithPassword: jest.fn() } } }));
jest.mock('../config/adminDb', () => ({
  supabaseAdmin: {
    auth: { admin: { createUser: jest.fn(), deleteUser: jest.fn(), signOut: jest.fn() } },
    from: jest.fn(),
  },
}));
jest.mock('../services/email.service', () => ({
  sendMagicLinkEmail: jest.fn(),
}));

import { registerUser, loginUser, generateMagicLink, verifyMagicLink } from '../services/auth.service';
import * as emailService from '../services/email.service';
import jwt from 'jsonwebtoken';

const mockCreateUser = supabaseAdmin.auth.admin.createUser as jest.Mock;
const mockDeleteUser = supabaseAdmin.auth.admin.deleteUser as jest.Mock;
const mockAdminSignOut = supabaseAdmin.auth.admin.signOut as jest.Mock;
const mockSignIn = supabase.auth.signInWithPassword as jest.Mock;
const mockFrom = supabaseAdmin.from as jest.Mock;
const mockSendMagicLinkEmail = emailService.sendMagicLinkEmail as jest.Mock;

const AUTH_USER = { id: 'uid-123', email: 'pm@agency.com' };
const WORKSPACE = { id: 'ws-456' };
const USER_ROW = { id: 'uid-123', email: 'pm@agency.com', name: 'Pat', role: 'admin' };

const PROJECT = { id: 'proj-abc', workspace_id: 'ws-456' };
const LINK_ROW = { id: 'link-1', token: 'deadbeef' };
const VALID_USER_ID = 'uid-123';

function makeInsertChain(result: { data: unknown; error: unknown }) {
  return {
    insert: jest.fn().mockReturnValue({
      select: jest.fn().mockReturnValue({
        single: jest.fn().mockResolvedValue(result),
      }),
    }),
  };
}

function makeDeleteChain(result: { error: unknown }) {
  const eqMock = jest.fn().mockResolvedValue(result);
  return {
    delete: jest.fn().mockReturnValue({ eq: eqMock }),
    _eq: eqMock,
  };
}

function makeSelectChain(result: { data: unknown; error: unknown }) {
  const singleMock = jest.fn().mockResolvedValue(result);
  const eqMock = jest.fn().mockReturnValue({ single: singleMock });
  const selectMock = jest.fn().mockReturnValue({ eq: eqMock });
  return { select: selectMock, _select: selectMock };
}

// projects: .select('id, workspace_id').eq('id', projectId).is('deleted_at', null).single()
function makeProjectSelectChain(result: { data: unknown; error: unknown }) {
  const singleMock = jest.fn().mockResolvedValue(result);
  const isMock = jest.fn().mockReturnValue({ single: singleMock });
  const eqMock = jest.fn().mockReturnValue({ is: isMock });
  const selectMock = jest.fn().mockReturnValue({ eq: eqMock });
  return { select: selectMock };
}

// workspaces: .select('id').eq('id', wsId).eq('owner_id', userId).is('deleted_at', null).single()
function makeWorkspaceOwnerSelectChain(result: { data: unknown; error: unknown }) {
  const singleMock = jest.fn().mockResolvedValue(result);
  const isMock = jest.fn().mockReturnValue({ single: singleMock });
  const eq2Mock = jest.fn().mockReturnValue({ is: isMock });
  const eq1Mock = jest.fn().mockReturnValue({ eq: eq2Mock });
  const selectMock = jest.fn().mockReturnValue({ eq: eq1Mock });
  return { select: selectMock, _eq1: eq1Mock, _eq2: eq2Mock };
}

// magic_links email_sent_at: .update({}).eq('id', linkId)
function makeUpdateEqChain(result: { error: unknown }) {
  const eqMock = jest.fn().mockResolvedValue(result);
  return { update: jest.fn().mockReturnValue({ eq: eqMock }) };
}

// magic_links atomic verify: .update({}).eq('token',t).is('used_at',null).gt('expires_at',now).select('...').single()
function makeAtomicUpdateChain(result: { data: unknown; error: unknown }) {
  const singleMock = jest.fn().mockResolvedValue(result);
  const selectMock = jest.fn().mockReturnValue({ single: singleMock });
  const gtMock = jest.fn().mockReturnValue({ select: selectMock });
  const isMock = jest.fn().mockReturnValue({ gt: gtMock });
  const eqMock = jest.fn().mockReturnValue({ is: isMock });
  const updateMock = jest.fn().mockReturnValue({ eq: eqMock });
  return { update: updateMock };
}

beforeEach(() => {
  jest.clearAllMocks();
  mockDeleteUser.mockResolvedValue({ error: null });
  mockAdminSignOut.mockResolvedValue({ error: null });
  mockSendMagicLinkEmail.mockResolvedValue(undefined);
});

describe('registerUser', () => {
  it('creates workspace and user, returns result', async () => {
    mockCreateUser.mockResolvedValue({ data: { user: AUTH_USER }, error: null });
    mockFrom
      .mockReturnValueOnce(makeInsertChain({ data: WORKSPACE, error: null }))
      .mockReturnValueOnce(makeInsertChain({ data: USER_ROW, error: null }));

    const result = await registerUser('pm@agency.com', 'secret123', 'Pat', 'Acme');
    expect(result.user).toEqual(USER_ROW);
    expect(result.workspaceId).toBe(WORKSPACE.id);
  });

  it('throws REGISTRATION_ERROR (400) when Supabase returns 4xx auth error', async () => {
    mockCreateUser.mockResolvedValue({
      data: { user: null },
      error: { message: 'User already exists', code: 'user_already_exists', status: 422 },
    });

    await expect(registerUser('dup@agency.com', 'pass12345', 'Dup', 'Dup Agency')).rejects.toMatchObject({
      code: 'REGISTRATION_ERROR',
      statusCode: 400,
    });
  });

  it('throws DB_ERROR (500) when Supabase returns 5xx auth error', async () => {
    mockCreateUser.mockResolvedValue({
      data: { user: null },
      error: { message: 'Internal server error', status: 500 },
    });

    await expect(registerUser('pm@agency.com', 'pass12345', 'Pat', 'Acme')).rejects.toMatchObject({
      code: 'DB_ERROR',
      statusCode: 500,
    });
  });

  it('deletes auth user and throws DB_ERROR when workspace insert fails', async () => {
    mockCreateUser.mockResolvedValue({ data: { user: AUTH_USER }, error: null });
    mockFrom.mockReturnValueOnce(makeInsertChain({ data: null, error: new Error('db down') }));

    await expect(registerUser('pm@agency.com', 'pass12345', 'Pat', 'Acme')).rejects.toMatchObject({
      code: 'DB_ERROR',
    });
    expect(mockDeleteUser).toHaveBeenCalledWith(AUTH_USER.id);
  });

  it('deletes both workspace and auth user when user-row insert fails', async () => {
    mockCreateUser.mockResolvedValue({ data: { user: AUTH_USER }, error: null });
    const wsDeleteMock = makeDeleteChain({ error: null });
    mockFrom
      .mockReturnValueOnce(makeInsertChain({ data: WORKSPACE, error: null }))
      .mockReturnValueOnce(makeInsertChain({ data: null, error: new Error('db down') }))
      .mockReturnValueOnce(wsDeleteMock);

    await expect(registerUser('pm@agency.com', 'pass12345', 'Pat', 'Acme')).rejects.toMatchObject({
      code: 'DB_ERROR',
    });
    expect(wsDeleteMock.delete).toHaveBeenCalled();
    expect(wsDeleteMock._eq).toHaveBeenCalledWith('id', WORKSPACE.id);
    expect(mockDeleteUser).toHaveBeenCalledWith(AUTH_USER.id);
  });

  it('logs error and still throws when rollback deleteUser fails', async () => {
    const consoleSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
    mockCreateUser.mockResolvedValue({ data: { user: AUTH_USER }, error: null });
    mockFrom.mockReturnValueOnce(makeInsertChain({ data: null, error: new Error('db down') }));
    mockDeleteUser.mockResolvedValue({ error: { message: 'delete failed' } });

    await expect(registerUser('pm@agency.com', 'pass12345', 'Pat', 'Acme')).rejects.toMatchObject({
      code: 'DB_ERROR',
    });
    expect(consoleSpy).toHaveBeenCalledWith(
      expect.stringContaining('Rollback failed'),
      AUTH_USER.id,
      expect.any(String),
    );
    consoleSpy.mockRestore();
  });
});

describe('loginUser', () => {
  it('returns token and full user including role, name, workspaceId', async () => {
    mockSignIn.mockResolvedValue({
      data: { session: { access_token: 'jwt-token' }, user: { id: 'uid-123' } },
      error: null,
    });
    const selectChain = makeSelectChain({
      data: { id: 'uid-123', email: 'pm@agency.com', name: 'Pat', role: 'admin', workspace_id: 'ws-456' },
      error: null,
    });
    mockFrom.mockReturnValueOnce(selectChain);

    const result = await loginUser('pm@agency.com', 'secret123');
    expect(result.token).toBe('jwt-token');
    expect(result.user.id).toBe('uid-123');
    expect(result.user.name).toBe('Pat');
    expect(result.user.role).toBe('admin');
    expect(result.user.workspaceId).toBe('ws-456');
    expect(selectChain._select).toHaveBeenCalledWith(expect.stringContaining('workspace_id'));
  });

  it('throws INVALID_CREDENTIALS on wrong password', async () => {
    mockSignIn.mockResolvedValue({ data: { session: null, user: null }, error: { message: 'Invalid login credentials' } });
    await expect(loginUser('pm@agency.com', 'wrong')).rejects.toMatchObject({ code: 'INVALID_CREDENTIALS' });
  });

  it('throws DB_ERROR and revokes session when user row not found', async () => {
    mockSignIn.mockResolvedValue({
      data: { session: { access_token: 'live-token' }, user: { id: 'uid-123' } },
      error: null,
    });
    mockFrom.mockReturnValueOnce(makeSelectChain({ data: null, error: new Error('not found') }));

    await expect(loginUser('pm@agency.com', 'pass12345')).rejects.toMatchObject({ code: 'DB_ERROR' });
    expect(mockAdminSignOut).toHaveBeenCalledWith('live-token');
  });

  it('logs error but still throws DB_ERROR when session revocation fails', async () => {
    const consoleSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
    mockSignIn.mockResolvedValue({
      data: { session: { access_token: 'live-token' }, user: { id: 'uid-123' } },
      error: null,
    });
    mockFrom.mockReturnValueOnce(makeSelectChain({ data: null, error: new Error('not found') }));
    mockAdminSignOut.mockResolvedValue({ error: { message: 'signout failed' } });

    await expect(loginUser('pm@agency.com', 'pass12345')).rejects.toMatchObject({ code: 'DB_ERROR' });
    expect(consoleSpy).toHaveBeenCalledWith(
      expect.stringContaining('Failed to revoke session'),
      'uid-123',
      expect.any(String),
    );
    consoleSpy.mockRestore();
  });
});

describe('generateMagicLink', () => {
  function setupHappyPath() {
    mockFrom
      .mockReturnValueOnce(makeProjectSelectChain({ data: PROJECT, error: null }))
      .mockReturnValueOnce(makeWorkspaceOwnerSelectChain({ data: WORKSPACE, error: null }))
      .mockReturnValueOnce(makeInsertChain({ data: LINK_ROW, error: null }))
      .mockReturnValueOnce(makeUpdateEqChain({ error: null }));
  }

  it('sends magic link email and returns { sent: true }', async () => {
    setupHappyPath();

    const result = await generateMagicLink(PROJECT.id, 'client@example.com', 'Alice', VALID_USER_ID);

    expect(result).toEqual({ sent: true });
    expect(mockSendMagicLinkEmail).toHaveBeenCalledWith(
      'client@example.com',
      'Alice',
      expect.stringContaining(encodeURIComponent(LINK_ROW.token)),
    );
  });

  it('uses fallback name "there" when clientName is undefined', async () => {
    setupHappyPath();

    await generateMagicLink(PROJECT.id, 'client@example.com', undefined, VALID_USER_ID);

    expect(mockSendMagicLinkEmail).toHaveBeenCalledWith(
      'client@example.com',
      'there',
      expect.any(String),
    );
  });

  it('encodes token in magic link URL', async () => {
    setupHappyPath();

    await generateMagicLink(PROJECT.id, 'client@example.com', 'Alice', VALID_USER_ID);

    const url = (mockSendMagicLinkEmail.mock.calls[0] as string[])[2];
    expect(url).toContain('/p/verify?token=');
    expect(url).toContain(encodeURIComponent(LINK_ROW.token));
  });

  it('throws NOT_FOUND when project does not exist', async () => {
    mockFrom.mockReturnValueOnce(makeProjectSelectChain({ data: null, error: new Error('not found') }));

    await expect(
      generateMagicLink('bad-project-id', 'client@example.com', undefined, VALID_USER_ID),
    ).rejects.toMatchObject({ code: 'NOT_FOUND', statusCode: 404 });
    expect(mockSendMagicLinkEmail).not.toHaveBeenCalled();
  });

  it('throws FORBIDDEN when workspace does not belong to authenticated user', async () => {
    mockFrom
      .mockReturnValueOnce(makeProjectSelectChain({ data: PROJECT, error: null }))
      .mockReturnValueOnce(makeWorkspaceOwnerSelectChain({ data: null, error: new Error('not owner') }));

    await expect(
      generateMagicLink(PROJECT.id, 'client@example.com', undefined, 'other-user-id'),
    ).rejects.toMatchObject({ code: 'FORBIDDEN', statusCode: 403 });
    expect(mockSendMagicLinkEmail).not.toHaveBeenCalled();
  });

  it('queries workspace with correct workspace_id and owner_id filters', async () => {
    const wsChain = makeWorkspaceOwnerSelectChain({ data: WORKSPACE, error: null });
    mockFrom
      .mockReturnValueOnce(makeProjectSelectChain({ data: PROJECT, error: null }))
      .mockReturnValueOnce(wsChain)
      .mockReturnValueOnce(makeInsertChain({ data: LINK_ROW, error: null }))
      .mockReturnValueOnce(makeUpdateEqChain({ error: null }));

    await generateMagicLink(PROJECT.id, 'client@example.com', undefined, VALID_USER_ID);

    expect(wsChain._eq1).toHaveBeenCalledWith('id', PROJECT.workspace_id);
    expect(wsChain._eq2).toHaveBeenCalledWith('owner_id', VALID_USER_ID);
  });

  it('throws DB_ERROR when magic_links insert fails', async () => {
    mockFrom
      .mockReturnValueOnce(makeProjectSelectChain({ data: PROJECT, error: null }))
      .mockReturnValueOnce(makeWorkspaceOwnerSelectChain({ data: WORKSPACE, error: null }))
      .mockReturnValueOnce(makeInsertChain({ data: null, error: new Error('insert failed') }));

    await expect(
      generateMagicLink(PROJECT.id, 'client@example.com', undefined, VALID_USER_ID),
    ).rejects.toMatchObject({ code: 'DB_ERROR', statusCode: 500 });
    expect(mockSendMagicLinkEmail).not.toHaveBeenCalled();
  });

  it('propagates EMAIL_ERROR when email send fails', async () => {
    mockFrom
      .mockReturnValueOnce(makeProjectSelectChain({ data: PROJECT, error: null }))
      .mockReturnValueOnce(makeWorkspaceOwnerSelectChain({ data: WORKSPACE, error: null }))
      .mockReturnValueOnce(makeInsertChain({ data: LINK_ROW, error: null }));
    mockSendMagicLinkEmail.mockRejectedValue({ code: 'EMAIL_ERROR', statusCode: 502 });

    await expect(
      generateMagicLink(PROJECT.id, 'client@example.com', 'Alice', VALID_USER_ID),
    ).rejects.toMatchObject({ code: 'EMAIL_ERROR' });
  });

  it('logs error but still returns { sent: true } when email_sent_at update fails', async () => {
    const consoleSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
    mockFrom
      .mockReturnValueOnce(makeProjectSelectChain({ data: PROJECT, error: null }))
      .mockReturnValueOnce(makeWorkspaceOwnerSelectChain({ data: WORKSPACE, error: null }))
      .mockReturnValueOnce(makeInsertChain({ data: LINK_ROW, error: null }))
      .mockReturnValueOnce(makeUpdateEqChain({ error: { message: 'update failed' } }));

    const result = await generateMagicLink(PROJECT.id, 'client@example.com', 'Alice', VALID_USER_ID);

    expect(result).toEqual({ sent: true });
    expect(consoleSpy).toHaveBeenCalledWith(
      expect.stringContaining('email_sent_at update failed'),
      LINK_ROW.id,
      expect.any(String),
    );
    consoleSpy.mockRestore();
  });
});

describe('verifyMagicLink', () => {
  const VALID_TOKEN = 'abc123hex';
  const LINK_DATA = {
    id: 'link-1',
    project_id: 'proj-abc',
    email: 'client@example.com',
    client_name: 'Alice',
  };

  it('atomically marks token used and returns portal JWT', async () => {
    mockFrom.mockReturnValueOnce(makeAtomicUpdateChain({ data: LINK_DATA, error: null }));

    const result = await verifyMagicLink(VALID_TOKEN);

    expect(result.token).toBeTruthy();
    const decoded = jwt.decode(result.token) as Record<string, unknown>;
    expect(decoded['type']).toBe('portal');
    expect(decoded['projectId']).toBe(LINK_DATA.project_id);
    expect(decoded['email']).toBe(LINK_DATA.email);
    expect(decoded['clientName']).toBe(LINK_DATA.client_name);
  });

  it('sets clientName to undefined in JWT when client_name is null', async () => {
    mockFrom.mockReturnValueOnce(
      makeAtomicUpdateChain({ data: { ...LINK_DATA, client_name: null }, error: null }),
    );

    const result = await verifyMagicLink(VALID_TOKEN);

    const decoded = jwt.decode(result.token) as Record<string, unknown>;
    expect(decoded['clientName']).toBeUndefined();
  });

  it('throws INVALID_TOKEN when token not found, already used, or expired (PGRST116)', async () => {
    mockFrom.mockReturnValueOnce(makeAtomicUpdateChain({ data: null, error: { code: 'PGRST116' } }));

    await expect(verifyMagicLink('used-token')).rejects.toMatchObject({
      code: 'INVALID_TOKEN',
      statusCode: 401,
    });
  });

  it('throws DB_ERROR on non-PGRST116 database errors', async () => {
    mockFrom.mockReturnValueOnce(
      makeAtomicUpdateChain({ data: null, error: { code: '08006', message: 'connection failure' } }),
    );

    await expect(verifyMagicLink('sometoken')).rejects.toMatchObject({
      code: 'DB_ERROR',
      statusCode: 500,
    });
  });

  it('issues a signed JWT verifiable with JWT_SECRET', async () => {
    mockFrom.mockReturnValueOnce(makeAtomicUpdateChain({ data: LINK_DATA, error: null }));

    const result = await verifyMagicLink(VALID_TOKEN);

    const decoded = jwt.verify(result.token, process.env['JWT_SECRET']!) as Record<string, unknown>;
    expect(decoded['type']).toBe('portal');
    expect(decoded['projectId']).toBe(LINK_DATA.project_id);
  });
});
