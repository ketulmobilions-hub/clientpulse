import { ErrorCodes } from '../errors/codes';
import request from 'supertest';
import { supabaseAdmin } from '../config/adminDb';

// Env vars are set in setup.ts before this module loads

jest.mock('../config/adminDb', () => ({
  supabaseAdmin: { from: jest.fn() },
}));

import app from '../app';

const mockFrom = supabaseAdmin.from as jest.Mock;

beforeEach(() => {
  mockFrom.mockReturnValue({
    select: jest.fn().mockResolvedValue({ error: null }),
  });
});

afterEach(() => {
  jest.clearAllMocks();
});

describe('GET /api/v1/health', () => {
  it('returns 200 with success true and message when DB is reachable', async () => {
    const res = await request(app).get('/api/v1/health');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ success: true, message: 'ClientPulse API is running' });
  });

  it('returns 503 when DB is unreachable', async () => {
    mockFrom.mockReturnValue({
      select: jest.fn().mockResolvedValue({ error: new Error('connection refused') }),
    });
    const res = await request(app).get('/api/v1/health');
    expect(res.status).toBe(503);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe(ErrorCodes.DB_UNAVAILABLE);
  });
});

describe('404 handler', () => {
  it('returns correct error format for unknown route', async () => {
    const res = await request(app).get('/api/v1/nonexistent');
    expect(res.status).toBe(404);
    expect(res.body).toEqual({
      success: false,
      error: { code: ErrorCodes.NOT_FOUND, message: 'Route not found' },
    });
  });
});
