import { supabase } from '../config/db';
import { supabaseAdmin } from '../config/adminDb';

jest.mock('../config/db', () => ({ supabase: { auth: { signInWithPassword: jest.fn() } } }));
jest.mock('../config/adminDb', () => ({
  supabaseAdmin: {
    auth: { admin: { createUser: jest.fn(), deleteUser: jest.fn(), signOut: jest.fn() } },
    from: jest.fn(),
  },
}));

import { registerUser, loginUser } from '../services/auth.service';

const mockCreateUser = supabaseAdmin.auth.admin.createUser as jest.Mock;
const mockDeleteUser = supabaseAdmin.auth.admin.deleteUser as jest.Mock;
const mockAdminSignOut = supabaseAdmin.auth.admin.signOut as jest.Mock;
const mockSignIn = supabase.auth.signInWithPassword as jest.Mock;
const mockFrom = supabaseAdmin.from as jest.Mock;

const AUTH_USER = { id: 'uid-123', email: 'pm@agency.com' };
const WORKSPACE = { id: 'ws-456' };
const USER_ROW = { id: 'uid-123', email: 'pm@agency.com', name: 'Pat', role: 'admin' };

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

beforeEach(() => {
  jest.clearAllMocks();
  mockDeleteUser.mockResolvedValue({ error: null });
  mockAdminSignOut.mockResolvedValue({ error: null });
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
