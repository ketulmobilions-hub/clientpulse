import request from 'supertest';
import express from 'express';
import { supabase } from '../config/db';
import { requireAuth } from '../middleware/auth.middleware';
import { errorHandler, notFound } from '../middleware/errorHandler';

jest.mock('../config/db', () => ({
  supabase: { auth: { getUser: jest.fn() } },
}));

const mockGetUser = supabase.auth.getUser as jest.Mock;

function makeApp() {
  const app = express();
  app.use(express.json());
  app.get('/protected', requireAuth, (req, res) => {
    res.json({ success: true, user: req.user });
  });
  app.use(notFound);
  app.use(errorHandler);
  return app;
}

beforeEach(() => jest.clearAllMocks());

describe('requireAuth middleware', () => {
  it('calls next and attaches user when token is valid', async () => {
    mockGetUser.mockResolvedValue({
      data: { user: { id: 'uid-1', email: 'pm@agency.com' } },
      error: null,
    });

    const res = await request(makeApp())
      .get('/protected')
      .set('Authorization', 'Bearer valid-token');

    expect(res.status).toBe(200);
    expect(res.body.user).toEqual({ id: 'uid-1', email: 'pm@agency.com' });
  });

  it('returns 401 UNAUTHORIZED when Authorization header is missing', async () => {
    const res = await request(makeApp()).get('/protected');

    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe('UNAUTHORIZED');
    expect(mockGetUser).not.toHaveBeenCalled();
  });

  it('returns 401 UNAUTHORIZED when Authorization header has wrong format', async () => {
    const res = await request(makeApp())
      .get('/protected')
      .set('Authorization', 'Token bad-format');

    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe('UNAUTHORIZED');
  });

  it('returns 401 UNAUTHORIZED when token is invalid or expired', async () => {
    mockGetUser.mockResolvedValue({
      data: { user: null },
      error: { message: 'invalid JWT' },
    });

    const res = await request(makeApp())
      .get('/protected')
      .set('Authorization', 'Bearer expired-token');

    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe('UNAUTHORIZED');
  });

  it('returns 401 UNAUTHORIZED when user has no email (non-email auth user)', async () => {
    mockGetUser.mockResolvedValue({
      data: { user: { id: 'uid-1', email: null } },
      error: null,
    });

    const res = await request(makeApp())
      .get('/protected')
      .set('Authorization', 'Bearer valid-token');

    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe('UNAUTHORIZED');
  });
});
