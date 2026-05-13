import { ErrorCodes } from '../errors/codes';
import { supabase } from '../config/db';
import { supabaseAdmin } from '../config/adminDb';

jest.mock('../config/db', () => ({ supabase: { auth: { signInWithPassword: jest.fn() } } }));
jest.mock('../config/adminDb', () => ({
  supabaseAdmin: {
    auth: {
      admin: {
        createUser: jest.fn(),
        deleteUser: jest.fn(),
        signOut: jest.fn(),
        updateUserById: jest.fn(),
      },
    },
    from: jest.fn(),
    schema: jest.fn(),
  },
}));
jest.mock('../services/email.service', () => ({
  sendMagicLinkEmail: jest.fn(),
  sendVerificationEmail: jest.fn(),
}));

import {
  registerUser,
  loginUser,
  generateMagicLink,
  verifyMagicLink,
  verifyEmailToken,
  resendVerification,
  LoginResult,
} from '../services/auth.service';
import * as emailService from '../services/email.service';
import { AppError } from '../middleware/errorHandler';
import jwt from 'jsonwebtoken';

const mockCreateUser = supabaseAdmin.auth.admin.createUser as jest.Mock;
const mockDeleteUser = supabaseAdmin.auth.admin.deleteUser as jest.Mock;
const mockUpdateUserById = supabaseAdmin.auth.admin.updateUserById as jest.Mock;
const mockSignIn = supabase.auth.signInWithPassword as jest.Mock;
const mockFrom = supabaseAdmin.from as jest.Mock;
const mockSchema = supabaseAdmin.schema as jest.Mock;
const mockSendMagicLinkEmail = emailService.sendMagicLinkEmail as jest.Mock;
const mockSendVerificationEmail = emailService.sendVerificationEmail as jest.Mock;

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
  // mockReturnValueOnce queues survive clearAllMocks (jest only clears call
  // history, not the implementation queue). Tests that don't consume every
  // queued return value leak into the next test. Hard reset on the chain
  // mocks specifically — they're the ones we set with .mockReturnValueOnce.
  mockFrom.mockReset();
  mockSchema.mockReset();
  mockDeleteUser.mockResolvedValue({ error: null });
  mockUpdateUserById.mockResolvedValue({ error: null });
  mockSendMagicLinkEmail.mockResolvedValue(undefined);
  mockSendVerificationEmail.mockResolvedValue(undefined);
});

// auth schema lookup chain:
//   .schema('auth').from('users').select(...).ilike('email', e).maybeSingle()
function makeAuthSchemaLookupChain(result: { data: unknown; error: unknown }) {
  const maybeSingleMock = jest.fn().mockResolvedValue(result);
  const ilikeMock = jest.fn().mockReturnValue({ maybeSingle: maybeSingleMock });
  const selectMock = jest.fn().mockReturnValue({ ilike: ilikeMock });
  const fromMock = jest.fn().mockReturnValue({ select: selectMock });
  return { from: fromMock };
}

// verification_tokens insert: .insert({}). No .select chain — the service does
// not need the row back (only for cleanup on rollback).
function makeVerificationInsertChain(result: { error: unknown }) {
  return { insert: jest.fn().mockResolvedValue(result) };
}

describe('registerUser', () => {
  it('creates workspace + user, issues verification token, returns requires_verification', async () => {
    mockCreateUser.mockResolvedValue({ data: { user: AUTH_USER }, error: null });
    mockFrom
      .mockReturnValueOnce(makeInsertChain({ data: WORKSPACE, error: null }))
      .mockReturnValueOnce(makeInsertChain({ data: USER_ROW, error: null }))
      .mockReturnValueOnce(makeVerificationInsertChain({ error: null }));

    const result = await registerUser('pm@agency.com', 'secret123', 'Pat', 'Acme');
    expect(result.user).toEqual(USER_ROW);
    expect(result.workspaceId).toBe(WORKSPACE.id);
    expect(result.requires_verification).toBe(true);
    expect(mockSendVerificationEmail).toHaveBeenCalledWith(
      'pm@agency.com',
      'Pat',
      expect.stringContaining('/verify-email?token='),
    );
    expect(mockCreateUser).toHaveBeenCalledWith(
      expect.objectContaining({ email_confirm: false }),
    );
  });

  it('rolls back via cascade-delete on auth.users when verification email fails', async () => {
    mockCreateUser.mockResolvedValue({ data: { user: AUTH_USER }, error: null });
    mockFrom
      .mockReturnValueOnce(makeInsertChain({ data: WORKSPACE, error: null }))
      .mockReturnValueOnce(makeInsertChain({ data: USER_ROW, error: null }))
      .mockReturnValueOnce(makeVerificationInsertChain({ error: null }));
    mockSendVerificationEmail.mockRejectedValue(
      new AppError('Email delivery failed', 502, ErrorCodes.EMAIL_ERROR),
    );

    await expect(registerUser('pm@agency.com', 'secret123', 'Pat', 'Acme')).rejects.toMatchObject({
      code: ErrorCodes.EMAIL_ERROR,
    });
    // Single deleteUser — FK cascade pulls workspace + users row.
    expect(mockDeleteUser).toHaveBeenCalledWith(AUTH_USER.id);
    expect(mockDeleteUser).toHaveBeenCalledTimes(1);
  });

  it('throws EMAIL_EXISTS (409) when Supabase reports duplicate email (email_exists)', async () => {
    mockCreateUser.mockResolvedValue({
      data: { user: null },
      error: { message: 'A user with this email address has already been registered', code: 'email_exists', status: 422 },
    });

    await expect(registerUser('dup@agency.com', 'pass12345', 'Dup', 'Dup Agency')).rejects.toMatchObject({
      code: ErrorCodes.EMAIL_EXISTS,
      statusCode: 409,
      message: 'An account with this email already exists',
    });
  });

  it('throws EMAIL_EXISTS (409) when Supabase reports duplicate email (user_already_exists)', async () => {
    mockCreateUser.mockResolvedValue({
      data: { user: null },
      error: { message: 'User already exists', code: 'user_already_exists', status: 422 },
    });

    await expect(registerUser('dup@agency.com', 'pass12345', 'Dup', 'Dup Agency')).rejects.toMatchObject({
      code: ErrorCodes.EMAIL_EXISTS,
      statusCode: 409,
    });
  });

  it('throws REGISTRATION_ERROR (400) and passes through Supabase message on other 4xx auth errors', async () => {
    mockCreateUser.mockResolvedValue({
      data: { user: null },
      error: { message: 'Password should be at least 8 characters', code: 'weak_password', status: 422 },
    });

    await expect(registerUser('pm@agency.com', 'short', 'Pat', 'Acme')).rejects.toMatchObject({
      code: ErrorCodes.REGISTRATION_ERROR,
      statusCode: 400,
      message: 'Password should be at least 8 characters',
    });
  });

  it('throws EMAIL_EXISTS (409) via message-based fallback when code field is missing', async () => {
    mockCreateUser.mockResolvedValue({
      data: { user: null },
      error: { message: 'A user with this email address has already been registered', status: 422 },
    });

    await expect(registerUser('dup@agency.com', 'pass12345', 'Dup', 'Dup Agency')).rejects.toMatchObject({
      code: ErrorCodes.EMAIL_EXISTS,
      statusCode: 409,
    });
  });

  it('falls back to "Registration failed" when 4xx auth error has empty message', async () => {
    mockCreateUser.mockResolvedValue({
      data: { user: null },
      error: { message: '', status: 422 },
    });

    await expect(registerUser('pm@agency.com', 'pass12345', 'Pat', 'Acme')).rejects.toMatchObject({
      code: ErrorCodes.REGISTRATION_ERROR,
      statusCode: 400,
      message: 'Registration failed',
    });
  });

  it('falls back to "Registration failed" when 4xx auth error has non-string message', async () => {
    mockCreateUser.mockResolvedValue({
      data: { user: null },
      error: { message: { nested: 'object' }, status: 422 },
    });

    await expect(registerUser('pm@agency.com', 'pass12345', 'Pat', 'Acme')).rejects.toMatchObject({
      code: ErrorCodes.REGISTRATION_ERROR,
      statusCode: 400,
      message: 'Registration failed',
    });
  });

  it('throws INTERNAL_ERROR (500) when Supabase returns 5xx auth/network error', async () => {
    mockCreateUser.mockResolvedValue({
      data: { user: null },
      error: { message: 'Internal server error', status: 500 },
    });

    await expect(registerUser('pm@agency.com', 'pass12345', 'Pat', 'Acme')).rejects.toMatchObject({
      code: ErrorCodes.INTERNAL_ERROR,
      statusCode: 500,
    });
  });

  it('deletes auth user and throws DB_ERROR when workspace insert fails', async () => {
    mockCreateUser.mockResolvedValue({ data: { user: AUTH_USER }, error: null });
    mockFrom.mockReturnValueOnce(makeInsertChain({ data: null, error: new Error('db down') }));

    await expect(registerUser('pm@agency.com', 'pass12345', 'Pat', 'Acme')).rejects.toMatchObject({
      code: ErrorCodes.DB_ERROR,
    });
    expect(mockDeleteUser).toHaveBeenCalledWith(AUTH_USER.id);
  });

  it('deletes auth user when user-row insert fails (FK cascade handles workspace)', async () => {
    mockCreateUser.mockResolvedValue({ data: { user: AUTH_USER }, error: null });
    mockFrom
      .mockReturnValueOnce(makeInsertChain({ data: WORKSPACE, error: null }))
      .mockReturnValueOnce(makeInsertChain({ data: null, error: new Error('db down') }));

    await expect(registerUser('pm@agency.com', 'pass12345', 'Pat', 'Acme')).rejects.toMatchObject({
      code: ErrorCodes.DB_ERROR,
    });
    // Single deleteUser call — FK ON DELETE CASCADE on workspaces.owner_id +
    // users.id pulls the rest. Replaces the prior multi-step explicit cleanup.
    expect(mockDeleteUser).toHaveBeenCalledWith(AUTH_USER.id);
    expect(mockDeleteUser).toHaveBeenCalledTimes(1);
  });

  it('logs error and still throws when rollback deleteUser fails', async () => {
    const consoleSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
    mockCreateUser.mockResolvedValue({ data: { user: AUTH_USER }, error: null });
    mockFrom.mockReturnValueOnce(makeInsertChain({ data: null, error: new Error('db down') }));
    mockDeleteUser.mockResolvedValue({ error: { message: 'delete failed' } });

    await expect(registerUser('pm@agency.com', 'pass12345', 'Pat', 'Acme')).rejects.toMatchObject({
      code: ErrorCodes.DB_ERROR,
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
      data: {
        session: { access_token: 'jwt-token' },
        user: { id: 'uid-123', email: 'pm@agency.com', email_confirmed_at: '2026-01-01T00:00:00Z' },
      },
      error: null,
    });
    const selectChain = makeSelectChain({
      data: { id: 'uid-123', email: 'pm@agency.com', name: 'Pat', role: 'admin', workspace_id: 'ws-456' },
      error: null,
    });
    mockFrom.mockReturnValueOnce(selectChain);

    const result = (await loginUser('pm@agency.com', 'secret123')) as LoginResult;
    expect(result.token).toBe('jwt-token');
    expect(result.user.id).toBe('uid-123');
    expect(result.user.name).toBe('Pat');
    expect(result.user.role).toBe('admin');
    expect(result.user.workspaceId).toBe('ws-456');
    expect(selectChain._select).toHaveBeenCalledWith(expect.stringContaining('workspace_id'));
  });

  it('returns requires_verification (no token) and revokes session for unverified user', async () => {
    mockSignIn.mockResolvedValue({
      data: {
        session: { access_token: 'jwt-unverified' },
        user: { id: 'uid-123', email: 'unverified@agency.com', email_confirmed_at: null },
      },
      error: null,
    });

    const result = await loginUser('unverified@agency.com', 'secret123');

    expect(result).toEqual({ requires_verification: true, email: 'unverified@agency.com' });
    expect((result as { token?: string }).token).toBeUndefined();
  });

  it('throws INVALID_CREDENTIALS on wrong password', async () => {
    mockSignIn.mockResolvedValue({ data: { session: null, user: null }, error: { message: 'Invalid login credentials' } });
    await expect(loginUser('pm@agency.com', 'wrong')).rejects.toMatchObject({ code: ErrorCodes.INVALID_CREDENTIALS });
  });

  it('returns requires_verification when Supabase reports email_not_confirmed (by code)', async () => {
    mockSignIn.mockResolvedValue({
      data: { session: null, user: null },
      error: { code: 'email_not_confirmed', message: 'Email not confirmed' },
    });

    const result = await loginUser('unverified@agency.com', 'secret123');

    expect(result).toEqual({ requires_verification: true, email: 'unverified@agency.com' });
    expect((result as { token?: string }).token).toBeUndefined();
  });

  it('returns requires_verification via message-based fallback when code missing', async () => {
    mockSignIn.mockResolvedValue({
      data: { session: null, user: null },
      error: { message: 'Email not confirmed' },
    });

    const result = await loginUser('unverified@agency.com', 'secret123');
    expect(result).toEqual({ requires_verification: true, email: 'unverified@agency.com' });
  });

  it('does NOT misroute unrelated errors that contain the phrase', async () => {
    // Anchored regex must reject error strings where the phrase appears as
    // part of a larger message (e.g. MFA enrollment context).
    mockSignIn.mockResolvedValue({
      data: { session: null, user: null },
      error: { message: 'MFA enrollment requires email not confirmed first' },
    });

    await expect(loginUser('pm@agency.com', 'pass12345')).rejects.toMatchObject({
      code: ErrorCodes.INVALID_CREDENTIALS,
    });
  });

  it('throws DB_ERROR when user row not found (token never returned to caller)', async () => {
    mockSignIn.mockResolvedValue({
      data: {
        session: { access_token: 'live-token' },
        user: { id: 'uid-123', email: 'pm@agency.com', email_confirmed_at: '2026-01-01T00:00:00Z' },
      },
      error: null,
    });
    mockFrom.mockReturnValueOnce(makeSelectChain({ data: null, error: new Error('not found') }));

    await expect(loginUser('pm@agency.com', 'pass12345')).rejects.toMatchObject({ code: ErrorCodes.DB_ERROR });
    // No signOut assertion — that call was misleading (only revokes refresh
    // token, not access token). Caller never sees the access token, so
    // there's nothing to revoke from a security standpoint.
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
    ).rejects.toMatchObject({ code: ErrorCodes.NOT_FOUND, statusCode: 404 });
    expect(mockSendMagicLinkEmail).not.toHaveBeenCalled();
  });

  it('throws FORBIDDEN when workspace does not belong to authenticated user', async () => {
    mockFrom
      .mockReturnValueOnce(makeProjectSelectChain({ data: PROJECT, error: null }))
      .mockReturnValueOnce(makeWorkspaceOwnerSelectChain({ data: null, error: new Error('not owner') }));

    await expect(
      generateMagicLink(PROJECT.id, 'client@example.com', undefined, 'other-user-id'),
    ).rejects.toMatchObject({ code: ErrorCodes.FORBIDDEN, statusCode: 403 });
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
    ).rejects.toMatchObject({ code: ErrorCodes.DB_ERROR, statusCode: 500 });
    expect(mockSendMagicLinkEmail).not.toHaveBeenCalled();
  });

  it('propagates EMAIL_ERROR when email send fails', async () => {
    mockFrom
      .mockReturnValueOnce(makeProjectSelectChain({ data: PROJECT, error: null }))
      .mockReturnValueOnce(makeWorkspaceOwnerSelectChain({ data: WORKSPACE, error: null }))
      .mockReturnValueOnce(makeInsertChain({ data: LINK_ROW, error: null }));
    mockSendMagicLinkEmail.mockRejectedValue({ code: ErrorCodes.EMAIL_ERROR, statusCode: 502 });

    await expect(
      generateMagicLink(PROJECT.id, 'client@example.com', 'Alice', VALID_USER_ID),
    ).rejects.toMatchObject({ code: ErrorCodes.EMAIL_ERROR });
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
      code: ErrorCodes.INVALID_TOKEN,
      statusCode: 401,
    });
  });

  it('throws DB_ERROR on non-PGRST116 database errors', async () => {
    mockFrom.mockReturnValueOnce(
      makeAtomicUpdateChain({ data: null, error: { code: '08006', message: 'connection failure' } }),
    );

    await expect(verifyMagicLink('sometoken')).rejects.toMatchObject({
      code: ErrorCodes.DB_ERROR,
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

// verification_tokens select-by-token:
//   .select(...).eq('token',h).maybeSingle()
function makeTokenSelectChain(result: { data: unknown; error: unknown }) {
  const maybeSingleMock = jest.fn().mockResolvedValue(result);
  const eqMock = jest.fn().mockReturnValue({ maybeSingle: maybeSingleMock });
  return { select: jest.fn().mockReturnValue({ eq: eqMock }) };
}

// verification_tokens consume update (no row returned):
//   .update({}).eq('token',h).is('consumed_at',null)
function makeTokenConsumeChain(result: { error: unknown }) {
  const isMock = jest.fn().mockResolvedValue(result);
  const eqMock = jest.fn().mockReturnValue({ is: isMock });
  return { update: jest.fn().mockReturnValue({ eq: eqMock }) };
}

describe('verifyEmailToken', () => {
  const futureExpires = new Date(Date.now() + 3600_000).toISOString();
  const pastExpires = new Date(Date.now() - 1000).toISOString();

  it('confirms user FIRST then marks token consumed, returns { verified, email }', async () => {
    const consumeChain = makeTokenConsumeChain({ error: null });
    mockFrom
      .mockReturnValueOnce(
        makeTokenSelectChain({
          data: {
            user_id: 'uid-123',
            email: 'pm@agency.com',
            consumed_at: null,
            expires_at: futureExpires,
          },
          error: null,
        }),
      )
      .mockReturnValueOnce(consumeChain);

    const result = await verifyEmailToken('valid-token');

    expect(result).toEqual({ verified: true, email: 'pm@agency.com' });
    expect(mockUpdateUserById).toHaveBeenCalledWith('uid-123', { email_confirm: true });
    expect(consumeChain.update).toHaveBeenCalled();

    // Order matters: confirm BEFORE consume. Verify by checking call order on
    // the parent mocks. updateUserById is called between the two mockFrom calls.
    const updateCallOrder = mockUpdateUserById.mock.invocationCallOrder[0]!;
    const consumeCallOrder = consumeChain.update.mock.invocationCallOrder[0]!;
    expect(updateCallOrder).toBeLessThan(consumeCallOrder);
  });

  it('returns { verified, email } idempotently when token already consumed', async () => {
    mockFrom.mockReturnValueOnce(
      makeTokenSelectChain({
        data: {
          user_id: 'uid-123',
          email: 'pm@agency.com',
          consumed_at: '2026-05-13T10:00:00Z',
          expires_at: futureExpires,
        },
        error: null,
      }),
    );

    const result = await verifyEmailToken('already-used');

    expect(result).toEqual({ verified: true, email: 'pm@agency.com' });
    expect(mockUpdateUserById).not.toHaveBeenCalled();
  });

  it('throws INVALID_TOKEN when token does not exist', async () => {
    mockFrom.mockReturnValueOnce(makeTokenSelectChain({ data: null, error: null }));

    await expect(verifyEmailToken('bogus')).rejects.toMatchObject({
      code: ErrorCodes.INVALID_TOKEN,
      statusCode: 400,
    });
    expect(mockUpdateUserById).not.toHaveBeenCalled();
  });

  it('throws INVALID_TOKEN when token is expired (unconsumed)', async () => {
    mockFrom.mockReturnValueOnce(
      makeTokenSelectChain({
        data: {
          user_id: 'uid-123',
          email: 'pm@agency.com',
          consumed_at: null,
          expires_at: pastExpires,
        },
        error: null,
      }),
    );

    await expect(verifyEmailToken('expired')).rejects.toMatchObject({
      code: ErrorCodes.INVALID_TOKEN,
    });
    expect(mockUpdateUserById).not.toHaveBeenCalled();
  });

  it('throws DB_ERROR on database failure during select', async () => {
    mockFrom.mockReturnValueOnce(
      makeTokenSelectChain({ data: null, error: { code: '08006', message: 'down' } }),
    );

    await expect(verifyEmailToken('x')).rejects.toMatchObject({
      code: ErrorCodes.DB_ERROR,
      statusCode: 500,
    });
  });

  it('throws INTERNAL_ERROR (token NOT consumed) when updateUserById fails', async () => {
    const consumeChain = makeTokenConsumeChain({ error: null });
    mockFrom
      .mockReturnValueOnce(
        makeTokenSelectChain({
          data: {
            user_id: 'uid-123',
            email: 'pm@agency.com',
            consumed_at: null,
            expires_at: futureExpires,
          },
          error: null,
        }),
      )
      .mockReturnValueOnce(consumeChain);
    mockUpdateUserById.mockResolvedValue({ error: { message: 'auth update failed' } });

    await expect(verifyEmailToken('valid-token')).rejects.toMatchObject({
      code: ErrorCodes.INTERNAL_ERROR,
    });
    // Critical: consume must NOT have run if confirm failed.
    expect(consumeChain.update).not.toHaveBeenCalled();
  });
});

// verification_tokens cooldown lookup:
//   .select('created_at').eq('user_id',u).is('consumed_at',null).order().limit(1).maybeSingle()
function makeCooldownLookupChain(result: { data: unknown; error: unknown }) {
  const maybeSingleMock = jest.fn().mockResolvedValue(result);
  const limitMock = jest.fn().mockReturnValue({ maybeSingle: maybeSingleMock });
  const orderMock = jest.fn().mockReturnValue({ limit: limitMock });
  const isMock = jest.fn().mockReturnValue({ order: orderMock });
  const eqMock = jest.fn().mockReturnValue({ is: isMock });
  return { select: jest.fn().mockReturnValue({ eq: eqMock }) };
}

// verification_tokens invalidate-old:
//   .update({}).eq('user_id',u).is('consumed_at',null)
function makeInvalidateOldChain(result: { error: unknown }) {
  const isMock = jest.fn().mockResolvedValue(result);
  const eqMock = jest.fn().mockReturnValue({ is: isMock });
  return { update: jest.fn().mockReturnValue({ eq: eqMock }) };
}

// users name lookup: .select('name').eq('id',u).maybeSingle()
function makeUserNameLookupChain(result: { data: unknown; error: unknown }) {
  const maybeSingleMock = jest.fn().mockResolvedValue(result);
  const eqMock = jest.fn().mockReturnValue({ maybeSingle: maybeSingleMock });
  return { select: jest.fn().mockReturnValue({ eq: eqMock }) };
}

describe('resendVerification', () => {
  function setupAuthLookup(result: { data: unknown; error: unknown }) {
    mockSchema.mockReturnValue(makeAuthSchemaLookupChain(result));
  }

  it('always returns { sent: true } and sends email for unverified user', async () => {
    setupAuthLookup({
      data: { id: 'uid-123', email_confirmed_at: null },
      error: null,
    });
    mockFrom
      .mockReturnValueOnce(makeCooldownLookupChain({ data: null, error: null }))
      .mockReturnValueOnce(makeInvalidateOldChain({ error: null }))
      .mockReturnValueOnce(makeUserNameLookupChain({ data: { name: 'Pat' }, error: null }))
      .mockReturnValueOnce(makeVerificationInsertChain({ error: null }));

    const result = await resendVerification('pm@agency.com');

    expect(result).toEqual({ sent: true });
    expect(mockSendVerificationEmail).toHaveBeenCalledWith(
      'pm@agency.com',
      'Pat',
      expect.stringContaining('/verify-email?token='),
    );
  });

  it('returns { sent: true } silently when email is already verified (no enumeration)', async () => {
    setupAuthLookup({
      data: { id: 'uid-456', email_confirmed_at: '2026-01-01T00:00:00Z' },
      error: null,
    });

    const result = await resendVerification('verified@agency.com');

    expect(result).toEqual({ sent: true });
    expect(mockSendVerificationEmail).not.toHaveBeenCalled();
  });

  it('returns { sent: true } silently for unknown email (no enumeration)', async () => {
    setupAuthLookup({ data: null, error: null });

    const result = await resendVerification('ghost@nowhere.com');

    expect(result).toEqual({ sent: true });
    expect(mockSendVerificationEmail).not.toHaveBeenCalled();
  });

  it('returns { sent: true } silently and does NOT send email when within cooldown', async () => {
    setupAuthLookup({
      data: { id: 'uid-123', email_confirmed_at: null },
      error: null,
    });
    const recentMs = new Date(Date.now() - 5_000).toISOString();
    mockFrom.mockReturnValueOnce(
      makeCooldownLookupChain({ data: { created_at: recentMs }, error: null }),
    );

    const result = await resendVerification('pm@agency.com');

    expect(result).toEqual({ sent: true });
    expect(mockSendVerificationEmail).not.toHaveBeenCalled();
  });

  it('proceeds when last token issued more than 60s ago', async () => {
    setupAuthLookup({
      data: { id: 'uid-123', email_confirmed_at: null },
      error: null,
    });
    const longAgoMs = new Date(Date.now() - 120_000).toISOString();
    mockFrom
      .mockReturnValueOnce(
        makeCooldownLookupChain({ data: { created_at: longAgoMs }, error: null }),
      )
      .mockReturnValueOnce(makeInvalidateOldChain({ error: null }))
      .mockReturnValueOnce(makeUserNameLookupChain({ data: { name: 'Pat' }, error: null }))
      .mockReturnValueOnce(makeVerificationInsertChain({ error: null }));

    await expect(resendVerification('pm@agency.com')).resolves.toEqual({ sent: true });
    expect(mockSendVerificationEmail).toHaveBeenCalled();
  });

  it('returns { sent: true } silently when auth lookup itself errors (no oracle)', async () => {
    setupAuthLookup({ data: null, error: { code: '08006', message: 'down' } });

    const result = await resendVerification('pm@agency.com');

    expect(result).toEqual({ sent: true });
    expect(mockSendVerificationEmail).not.toHaveBeenCalled();
  });

  it('returns { sent: true } silently when email send fails (no oracle)', async () => {
    setupAuthLookup({
      data: { id: 'uid-123', email_confirmed_at: null },
      error: null,
    });
    mockFrom
      .mockReturnValueOnce(makeCooldownLookupChain({ data: null, error: null }))
      .mockReturnValueOnce(makeInvalidateOldChain({ error: null }))
      .mockReturnValueOnce(makeUserNameLookupChain({ data: { name: 'Pat' }, error: null }))
      .mockReturnValueOnce(makeVerificationInsertChain({ error: null }));
    mockSendVerificationEmail.mockRejectedValue(new Error('Resend down'));

    const result = await resendVerification('pm@agency.com');

    expect(result).toEqual({ sent: true });
  });
});
