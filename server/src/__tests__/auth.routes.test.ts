jest.mock('express-rate-limit', () => jest.fn(() => (_req: unknown, _res: unknown, next: () => void) => next()));
jest.mock('../services/auth.service');

import request from 'supertest';
import app from '../app';
import * as authService from '../services/auth.service';
import { AppError } from '../middleware/errorHandler';
import { ErrorCodes } from '../errors/codes';

const mockRegister = authService.registerUser as jest.Mock;
const mockLogin = authService.loginUser as jest.Mock;
const mockVerify = authService.verifyEmailToken as jest.Mock;
const mockResend = authService.resendVerification as jest.Mock;

const REGISTER_RESULT = {
  user: { id: 'uid-123', email: 'pm@agency.com', name: 'Pat', role: 'admin' },
  workspaceId: 'ws-456',
  requires_verification: true,
};

const LOGIN_RESULT = {
  token: 'jwt-token',
  user: { id: 'uid-123', email: 'pm@agency.com', name: 'Pat', role: 'admin', workspaceId: 'ws-456' },
};

beforeEach(() => jest.clearAllMocks());

describe('POST /api/v1/auth/register', () => {
  const validBody = { email: 'pm@agency.com', password: 'secret123', name: 'Pat', workspaceName: 'Acme' };

  it('returns 201 with user and workspaceId on success', async () => {
    mockRegister.mockResolvedValue(REGISTER_RESULT);
    const res = await request(app).post('/api/v1/auth/register').send(validBody);
    expect(res.status).toBe(201);
    expect(res.body).toEqual({ success: true, data: REGISTER_RESULT });
  });

  it('returns 400 VALIDATION_ERROR when fields missing', async () => {
    const res = await request(app).post('/api/v1/auth/register').send({ email: 'a@b.com' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockRegister).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for whitespace-only name', async () => {
    const res = await request(app).post('/api/v1/auth/register').send({ ...validBody, name: '   ' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
  });

  it('returns 400 VALIDATION_ERROR for non-string email', async () => {
    const res = await request(app).post('/api/v1/auth/register').send({ ...validBody, email: 42 });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
  });

  it('returns 400 VALIDATION_ERROR for invalid email format', async () => {
    const res = await request(app).post('/api/v1/auth/register').send({ ...validBody, email: 'notanemail' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
  });

  it('returns 400 VALIDATION_ERROR for password shorter than 8 chars', async () => {
    const res = await request(app).post('/api/v1/auth/register').send({ ...validBody, password: 'short' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
  });

  it('returns 409 EMAIL_EXISTS on duplicate email from service', async () => {
    mockRegister.mockRejectedValue(
      new AppError('An account with this email already exists', 409, ErrorCodes.EMAIL_EXISTS),
    );
    const res = await request(app).post('/api/v1/auth/register').send(validBody);
    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe(ErrorCodes.EMAIL_EXISTS);
    expect(res.body.error.message).toBe('An account with this email already exists');
  });

  it('returns 400 REGISTRATION_ERROR on other registration failures from service', async () => {
    mockRegister.mockRejectedValue(new AppError('Password too weak', 400, ErrorCodes.REGISTRATION_ERROR));
    const res = await request(app).post('/api/v1/auth/register').send(validBody);
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.REGISTRATION_ERROR);
  });
});

describe('POST /api/v1/auth/login', () => {
  const validBody = { email: 'pm@agency.com', password: 'secret123' };

  it('returns 200 with token and full user on success', async () => {
    mockLogin.mockResolvedValue(LOGIN_RESULT);
    const res = await request(app).post('/api/v1/auth/login').send(validBody);
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ success: true, data: LOGIN_RESULT });
    expect(res.body.data.user.id).toBe('uid-123');
    expect(res.body.data.user.workspaceId).toBe('ws-456');
    expect(res.body.data.user.role).toBe('admin');
  });

  it('returns 400 VALIDATION_ERROR when fields missing', async () => {
    const res = await request(app).post('/api/v1/auth/login').send({ email: 'x@y.com' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockLogin).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for invalid email format', async () => {
    const res = await request(app).post('/api/v1/auth/login').send({ email: 'notvalid', password: 'pass123' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
  });

  it('returns 401 INVALID_CREDENTIALS on wrong password from service', async () => {
    mockLogin.mockRejectedValue(new AppError('Invalid email or password', 401, ErrorCodes.INVALID_CREDENTIALS));
    const res = await request(app).post('/api/v1/auth/login').send(validBody);
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe(ErrorCodes.INVALID_CREDENTIALS);
  });

  it('returns 200 with requires_verification shape (no token) for unverified user', async () => {
    mockLogin.mockResolvedValue({ requires_verification: true, email: 'unverified@agency.com' });
    const res = await request(app).post('/api/v1/auth/login').send({
      email: 'unverified@agency.com',
      password: 'secret123',
    });
    expect(res.status).toBe(200);
    expect(res.body.data.requires_verification).toBe(true);
    expect(res.body.data.email).toBe('unverified@agency.com');
    expect(res.body.data.token).toBeUndefined();
  });
});

describe('GET /api/v1/auth/verify-email', () => {
  it('returns 200 with verified shape on valid token', async () => {
    mockVerify.mockResolvedValue({ verified: true, email: 'pm@agency.com' });
    const res = await request(app).get('/api/v1/auth/verify-email?token=abc123');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ success: true, data: { verified: true, email: 'pm@agency.com' } });
    expect(mockVerify).toHaveBeenCalledWith('abc123');
  });

  it('returns 400 VALIDATION_ERROR when token query missing', async () => {
    const res = await request(app).get('/api/v1/auth/verify-email');
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockVerify).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR when token query is whitespace only', async () => {
    const res = await request(app).get('/api/v1/auth/verify-email?token=%20%20');
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
  });

  it('returns 400 INVALID_TOKEN when service rejects token', async () => {
    mockVerify.mockRejectedValue(
      new AppError('Verification link is invalid or expired', 400, ErrorCodes.INVALID_TOKEN),
    );
    const res = await request(app).get('/api/v1/auth/verify-email?token=bogus');
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.INVALID_TOKEN);
  });
});

describe('POST /api/v1/auth/resend-verification', () => {
  it('returns 200 with sent on success', async () => {
    mockResend.mockResolvedValue({ sent: true });
    const res = await request(app)
      .post('/api/v1/auth/resend-verification')
      .send({ email: 'pm@agency.com' });
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ success: true, data: { sent: true } });
  });

  it('returns 400 VALIDATION_ERROR when email missing', async () => {
    const res = await request(app).post('/api/v1/auth/resend-verification').send({});
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockResend).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for invalid email format', async () => {
    const res = await request(app)
      .post('/api/v1/auth/resend-verification')
      .send({ email: 'notanemail' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
  });

  it('always returns 200 sent:true regardless of cooldown (no enumeration oracle)', async () => {
    // Service enforces cooldown silently and never throws RATE_LIMITED.
    // Route should reflect that — same response shape whether the email
    // exists, is verified, missing, or hit cooldown.
    mockResend.mockResolvedValue({ sent: true });
    const res = await request(app)
      .post('/api/v1/auth/resend-verification')
      .send({ email: 'pm@agency.com' });
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ success: true, data: { sent: true } });
  });
});
