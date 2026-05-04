jest.mock('express-rate-limit', () => jest.fn(() => (_req: unknown, _res: unknown, next: () => void) => next()));
jest.mock('../services/auth.service');
jest.mock('../config/db', () => ({
  supabase: { auth: { getUser: jest.fn() } },
}));

import request from 'supertest';
import app from '../app';
import * as authService from '../services/auth.service';
import { supabase } from '../config/db';
import { AppError } from '../middleware/errorHandler';
import { ErrorCodes } from '../errors/codes';

const mockGenerateMagicLink = authService.generateMagicLink as jest.Mock;
const mockVerifyMagicLink = authService.verifyMagicLink as jest.Mock;
const mockGetUser = supabase.auth.getUser as jest.Mock;

const AUTHED_USER = { id: 'uid-123', email: 'pm@agency.com' };
const VALID_AUTH_HEADER = 'Bearer valid-agency-token';
const VALID_PROJECT_ID = '11111111-1111-1111-1111-111111111111';

beforeEach(() => {
  jest.clearAllMocks();
  mockGetUser.mockResolvedValue({ data: { user: AUTHED_USER }, error: null });
});

describe('POST /api/v1/auth/magic-link', () => {
  const validBody = { projectId: VALID_PROJECT_ID, email: 'client@example.com', clientName: 'Alice' };

  it('returns 200 with sent:true on success', async () => {
    mockGenerateMagicLink.mockResolvedValue({ sent: true });

    const res = await request(app)
      .post('/api/v1/auth/magic-link')
      .set('Authorization', VALID_AUTH_HEADER)
      .send(validBody);

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ success: true, data: { sent: true } });
    expect(mockGenerateMagicLink).toHaveBeenCalledWith(VALID_PROJECT_ID, 'client@example.com', 'Alice', AUTHED_USER.id);
  });

  it('passes userId from auth token to generateMagicLink', async () => {
    mockGenerateMagicLink.mockResolvedValue({ sent: true });

    await request(app)
      .post('/api/v1/auth/magic-link')
      .set('Authorization', VALID_AUTH_HEADER)
      .send(validBody);

    expect(mockGenerateMagicLink).toHaveBeenCalledWith(
      expect.any(String),
      expect.any(String),
      expect.any(String),
      AUTHED_USER.id,
    );
  });

  it('returns 200 when clientName omitted', async () => {
    mockGenerateMagicLink.mockResolvedValue({ sent: true });

    const res = await request(app)
      .post('/api/v1/auth/magic-link')
      .set('Authorization', VALID_AUTH_HEADER)
      .send({ projectId: VALID_PROJECT_ID, email: 'client@example.com' });

    expect(res.status).toBe(200);
    expect(mockGenerateMagicLink).toHaveBeenCalledWith(VALID_PROJECT_ID, 'client@example.com', undefined, AUTHED_USER.id);
  });

  it('returns 401 UNAUTHORIZED when no auth header', async () => {
    const res = await request(app)
      .post('/api/v1/auth/magic-link')
      .send(validBody);

    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe(ErrorCodes.UNAUTHORIZED);
    expect(mockGenerateMagicLink).not.toHaveBeenCalled();
  });

  it('returns 401 UNAUTHORIZED when token invalid', async () => {
    mockGetUser.mockResolvedValue({ data: { user: null }, error: { message: 'invalid JWT' } });

    const res = await request(app)
      .post('/api/v1/auth/magic-link')
      .set('Authorization', 'Bearer bad-token')
      .send(validBody);

    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe(ErrorCodes.UNAUTHORIZED);
  });

  it('returns 400 VALIDATION_ERROR when projectId missing', async () => {
    const res = await request(app)
      .post('/api/v1/auth/magic-link')
      .set('Authorization', VALID_AUTH_HEADER)
      .send({ email: 'client@example.com' });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockGenerateMagicLink).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR when projectId is not a UUID', async () => {
    const res = await request(app)
      .post('/api/v1/auth/magic-link')
      .set('Authorization', VALID_AUTH_HEADER)
      .send({ ...validBody, projectId: 'not-a-uuid' });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockGenerateMagicLink).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR when email missing', async () => {
    const res = await request(app)
      .post('/api/v1/auth/magic-link')
      .set('Authorization', VALID_AUTH_HEADER)
      .send({ projectId: VALID_PROJECT_ID });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
  });

  it('returns 400 VALIDATION_ERROR for invalid email format', async () => {
    const res = await request(app)
      .post('/api/v1/auth/magic-link')
      .set('Authorization', VALID_AUTH_HEADER)
      .send({ ...validBody, email: 'notanemail' });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
  });

  it('returns 400 VALIDATION_ERROR for clientName exceeding 100 chars', async () => {
    const res = await request(app)
      .post('/api/v1/auth/magic-link')
      .set('Authorization', VALID_AUTH_HEADER)
      .send({ ...validBody, clientName: 'a'.repeat(101) });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
  });

  it('returns 404 NOT_FOUND when project does not exist', async () => {
    mockGenerateMagicLink.mockRejectedValue(new AppError('Project not found', 404, ErrorCodes.NOT_FOUND));

    const res = await request(app)
      .post('/api/v1/auth/magic-link')
      .set('Authorization', VALID_AUTH_HEADER)
      .send(validBody);

    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe(ErrorCodes.NOT_FOUND);
  });

  it('returns 403 FORBIDDEN when project belongs to a different workspace', async () => {
    mockGenerateMagicLink.mockRejectedValue(new AppError('Access denied', 403, ErrorCodes.FORBIDDEN));

    const res = await request(app)
      .post('/api/v1/auth/magic-link')
      .set('Authorization', VALID_AUTH_HEADER)
      .send(validBody);

    expect(res.status).toBe(403);
    expect(res.body.error.code).toBe(ErrorCodes.FORBIDDEN);
  });

  it('propagates DB_ERROR from service', async () => {
    mockGenerateMagicLink.mockRejectedValue(new AppError('Failed to generate magic link', 500, ErrorCodes.DB_ERROR));

    const res = await request(app)
      .post('/api/v1/auth/magic-link')
      .set('Authorization', VALID_AUTH_HEADER)
      .send(validBody);

    expect(res.status).toBe(500);
    expect(res.body.error.code).toBe(ErrorCodes.DB_ERROR);
  });
});

describe('GET /api/v1/auth/magic-link/verify', () => {
  const PORTAL_TOKEN = 'portal.jwt.token';

  it('returns 200 with portal token on valid magic link token', async () => {
    mockVerifyMagicLink.mockResolvedValue({ token: PORTAL_TOKEN });

    const res = await request(app)
      .get('/api/v1/auth/magic-link/verify')
      .query({ token: 'abc123hex' });

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ success: true, data: { token: PORTAL_TOKEN } });
    expect(mockVerifyMagicLink).toHaveBeenCalledWith('abc123hex');
  });

  it('returns 400 VALIDATION_ERROR when token query param missing', async () => {
    const res = await request(app)
      .get('/api/v1/auth/magic-link/verify');

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockVerifyMagicLink).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR when token is whitespace only', async () => {
    const res = await request(app)
      .get('/api/v1/auth/magic-link/verify')
      .query({ token: '   ' });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
  });

  it('returns 401 INVALID_TOKEN on expired or used token', async () => {
    mockVerifyMagicLink.mockRejectedValue(new AppError('Invalid or expired magic link', 401, ErrorCodes.INVALID_TOKEN));

    const res = await request(app)
      .get('/api/v1/auth/magic-link/verify')
      .query({ token: 'expiredtoken' });

    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe(ErrorCodes.INVALID_TOKEN);
  });

  it('propagates DB errors from service', async () => {
    mockVerifyMagicLink.mockRejectedValue(new AppError('Failed to consume magic link', 500, ErrorCodes.DB_ERROR));

    const res = await request(app)
      .get('/api/v1/auth/magic-link/verify')
      .query({ token: 'sometoken' });

    expect(res.status).toBe(500);
    expect(res.body.error.code).toBe(ErrorCodes.DB_ERROR);
  });
});
