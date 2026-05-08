jest.mock('express-rate-limit', () => jest.fn(() => (_req: unknown, _res: unknown, next: () => void) => next()));

import request from 'supertest';
import { supabaseAdmin } from '../config/adminDb';
import { ErrorCodes } from '../errors/codes';

jest.mock('../config/adminDb', () => ({
  supabaseAdmin: { from: jest.fn() },
}));

import app from '../app';

const mockFrom = supabaseAdmin.from as jest.Mock;
const mockInsert = jest.fn();

beforeEach(() => {
  mockFrom.mockReturnValue({ insert: mockInsert });
  mockInsert.mockResolvedValue({ error: null });
});

afterEach(() => {
  jest.clearAllMocks();
});

const post = (body: Record<string, unknown>) =>
  request(app).post('/api/v1/waitlist').send(body);

describe('POST /api/v1/waitlist', () => {
  it('records a valid email and returns 201', async () => {
    const res = await post({ email: 'founder@agency.com' });
    expect(res.status).toBe(201);
    expect(res.body).toEqual({ success: true });
    expect(mockInsert).toHaveBeenCalledWith({
      email: 'founder@agency.com',
      referrer: null,
      utm_source: null,
    });
  });

  it('lowercases the email before insert', async () => {
    await post({ email: 'Founder@Agency.COM' });
    expect(mockInsert).toHaveBeenCalledWith(expect.objectContaining({ email: 'founder@agency.com' }));
  });

  it('passes referrer and utmSource through', async () => {
    await post({ email: 'a@b.com', referrer: 'https://twitter.com', utmSource: 'launch' });
    expect(mockInsert).toHaveBeenCalledWith({
      email: 'a@b.com',
      referrer: 'https://twitter.com',
      utm_source: 'launch',
    });
  });

  it('treats duplicate-email DB error as success (no enumeration)', async () => {
    mockInsert.mockResolvedValue({ error: { code: '23505', message: 'duplicate' } });
    const res = await post({ email: 'dup@a.com' });
    expect(res.status).toBe(201);
    expect(res.body).toEqual({ success: true });
  });

  it('rejects invalid email with 400', async () => {
    const res = await post({ email: 'not-an-email' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
  });

  it('rejects missing email with 400', async () => {
    const res = await post({});
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
  });

  it('returns 500 when DB returns a non-duplicate error', async () => {
    mockInsert.mockResolvedValue({ error: { code: '42P01', message: 'no table' } });
    const res = await post({ email: 'a@b.com' });
    expect(res.status).toBe(500);
    expect(res.body.error.code).toBe(ErrorCodes.DB_ERROR);
  });
});
