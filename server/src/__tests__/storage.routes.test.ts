jest.mock('express-rate-limit', () =>
  jest.fn(() => (_req: unknown, _res: unknown, next: () => void) => next()),
);
jest.mock('../middleware/auth.middleware', () => ({
  requireAuth: (req: { user?: { id: string; email: string } }, _res: unknown, next: () => void) => {
    req.user = { id: 'user-1', email: 'agency@example.com' };
    next();
  },
}));
jest.mock('../services/storage.service');
jest.mock('../services/workspace.service');

import request from 'supertest';
import app from '../app';
import * as storageService from '../services/storage.service';
import * as workspaceService from '../services/workspace.service';
import { AppError } from '../middleware/errorHandler';
import { ErrorCodes } from '../errors/codes';

const mockGetSignedUrl = storageService.getUploadSignedUrl as jest.Mock;
const mockGetWorkspace = workspaceService.getWorkspace as jest.Mock;

const WORKSPACE = { id: 'ws-1', name: 'Acme', slug: 'acme', owner_id: 'user-1', logo_url: null };

beforeEach(() => {
  jest.clearAllMocks();
  mockGetWorkspace.mockResolvedValue(WORKSPACE);
});

describe('POST /api/v1/storage/signed-url', () => {
  it('returns 200 with signedUrl, publicUrl and path', async () => {
    mockGetSignedUrl.mockResolvedValue({
      signedUrl: 'https://signed.url/upload',
      publicUrl: 'https://public.url/logo.png',
      path: 'user-1/123.png',
    });

    const res = await request(app)
      .post('/api/v1/storage/signed-url')
      .send({ file_name: 'logo.png' });

    expect(res.status).toBe(200);
    expect(res.body).toEqual({
      success: true,
      data: {
        signedUrl: 'https://signed.url/upload',
        publicUrl: 'https://public.url/logo.png',
        path: 'user-1/123.png',
      },
    });
    expect(mockGetSignedUrl).toHaveBeenCalledWith('user-1', 'logo.png');
  });

  it('verifies workspace ownership before issuing URL', async () => {
    mockGetSignedUrl.mockResolvedValue({
      signedUrl: 'https://s.url',
      publicUrl: 'https://p.url',
      path: 'p',
    });

    await request(app).post('/api/v1/storage/signed-url').send({ file_name: 'logo.png' });

    expect(mockGetWorkspace).toHaveBeenCalledWith('user-1');
  });

  it('returns 404 when user is not workspace owner', async () => {
    mockGetWorkspace.mockRejectedValue(new AppError('Workspace not found', 404, ErrorCodes.NOT_FOUND));

    const res = await request(app)
      .post('/api/v1/storage/signed-url')
      .send({ file_name: 'logo.png' });

    expect(res.status).toBe(404);
    expect(mockGetSignedUrl).not.toHaveBeenCalled();
  });

  it('returns 400 when file_name is missing', async () => {
    const res = await request(app).post('/api/v1/storage/signed-url').send({});
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockGetSignedUrl).not.toHaveBeenCalled();
  });

  it('returns 400 for disallowed file type including svg', async () => {
    mockGetSignedUrl.mockRejectedValue(
      new AppError('Only image files are allowed', 400, ErrorCodes.VALIDATION_ERROR),
    );

    const res = await request(app)
      .post('/api/v1/storage/signed-url')
      .send({ file_name: 'logo.svg' });

    expect(res.status).toBe(400);
  });

  it('returns 500 when storage service fails', async () => {
    mockGetSignedUrl.mockRejectedValue(
      new AppError('Failed to generate upload URL', 500, ErrorCodes.STORAGE_ERROR),
    );

    const res = await request(app)
      .post('/api/v1/storage/signed-url')
      .send({ file_name: 'logo.png' });

    expect(res.status).toBe(500);
    expect(res.body.error.code).toBe(ErrorCodes.STORAGE_ERROR);
  });
});

describe('DELETE /api/v1/storage/logo', () => {
  const OWNED_URL =
    'https://xyz.supabase.co/storage/v1/object/public/logos/user-1/1234567890.png';

  beforeEach(() => {
    (storageService.deleteLogoByUrl as jest.Mock) = jest.fn().mockResolvedValue(undefined);
  });

  it('returns 204 and deletes owned logo', async () => {
    const res = await request(app)
      .delete('/api/v1/storage/logo')
      .send({ logo_url: OWNED_URL });

    expect(res.status).toBe(204);
    expect(storageService.deleteLogoByUrl).toHaveBeenCalledWith(OWNED_URL);
  });

  it('returns 400 when logo_url is missing', async () => {
    const res = await request(app).delete('/api/v1/storage/logo').send({});
    expect(res.status).toBe(400);
  });

  it('returns 403 when logo_url belongs to a different user', async () => {
    const otherUserUrl =
      'https://xyz.supabase.co/storage/v1/object/public/logos/other-user/1234567890.png';
    const res = await request(app)
      .delete('/api/v1/storage/logo')
      .send({ logo_url: otherUserUrl });

    expect(res.status).toBe(403);
    expect(storageService.deleteLogoByUrl).not.toHaveBeenCalled();
  });

  it('returns 404 when user is not workspace owner', async () => {
    mockGetWorkspace.mockRejectedValueOnce(
      new AppError('Workspace not found', 404, ErrorCodes.NOT_FOUND),
    );
    const res = await request(app)
      .delete('/api/v1/storage/logo')
      .send({ logo_url: OWNED_URL });

    expect(res.status).toBe(404);
  });

  it('passes through non-Supabase URLs without ownership check', async () => {
    const externalUrl = 'https://other-cdn.example.com/logo.png';
    const res = await request(app)
      .delete('/api/v1/storage/logo')
      .send({ logo_url: externalUrl });

    // No path match → no ownership check → deleteLogoByUrl called (it no-ops internally)
    expect(res.status).toBe(204);
    expect(storageService.deleteLogoByUrl).toHaveBeenCalledWith(externalUrl);
  });
});
