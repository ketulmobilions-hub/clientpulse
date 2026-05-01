jest.mock('express-rate-limit', () => jest.fn(() => (_req: unknown, _res: unknown, next: () => void) => next()));
jest.mock('../services/auth.service');

import request from 'supertest';
import app from '../app';
import * as authService from '../services/auth.service';
import { AppError } from '../middleware/errorHandler';
import { ErrorCodes } from '../errors/codes';

const mockRegister = authService.registerUser as jest.Mock;
const mockLogin = authService.loginUser as jest.Mock;

const REGISTER_RESULT = {
  user: { id: 'uid-123', email: 'pm@agency.com', name: 'Pat', role: 'admin' },
  workspaceId: 'ws-456',
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

  it('returns 400 REGISTRATION_ERROR on duplicate email from service', async () => {
    mockRegister.mockRejectedValue(new AppError('Registration failed', 400, ErrorCodes.REGISTRATION_ERROR));
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
});
