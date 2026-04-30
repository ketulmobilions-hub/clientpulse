jest.mock('express-rate-limit', () => jest.fn(() => (_req: unknown, _res: unknown, next: () => void) => next()));
jest.mock('../middleware/auth.middleware', () => ({
  requireAuth: (req: { user?: { id: string; email: string } }, _res: unknown, next: () => void) => {
    req.user = { id: 'user-1', email: 'pm@agency.com' };
    next();
  },
}));
jest.mock('../services/update.service');

import request from 'supertest';
import app from '../app';
import * as updateService from '../services/update.service';
import { AppError } from '../middleware/errorHandler';

const mockListComments = updateService.listComments as jest.Mock;
const mockCreateAgencyComment = updateService.createAgencyComment as jest.Mock;

const VALID_UUID = '12345678-1234-1234-1234-123456789012';
const VALID_UUID_2 = '87654321-4321-4321-4321-210987654321';

const COMMENT = {
  id: VALID_UUID_2,
  update_id: VALID_UUID,
  parent_id: null,
  author_id: 'user-1',
  author_type: 'agency',
  author_name: 'pm@agency.com',
  body: 'Looks good!',
  created_at: '2026-01-01T00:00:00Z',
  updated_at: '2026-01-01T00:00:00Z',
};

beforeEach(() => {
  jest.clearAllMocks();
});

describe('GET /api/v1/updates/:updateId/comments', () => {
  it('returns 200 with comments array', async () => {
    mockListComments.mockResolvedValue([COMMENT]);
    const res = await request(app).get(`/api/v1/updates/${VALID_UUID}/comments`);
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ success: true, data: { comments: [COMMENT] } });
    expect(mockListComments).toHaveBeenCalledWith('user-1', VALID_UUID);
  });

  it('returns 200 with empty array when no comments', async () => {
    mockListComments.mockResolvedValue([]);
    const res = await request(app).get(`/api/v1/updates/${VALID_UUID}/comments`);
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ success: true, data: { comments: [] } });
  });

  it('returns 400 VALIDATION_ERROR for non-UUID updateId', async () => {
    const res = await request(app).get('/api/v1/updates/not-a-uuid/comments');
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(mockListComments).not.toHaveBeenCalled();
  });

  it('returns 404 NOT_FOUND when update missing', async () => {
    mockListComments.mockRejectedValue(new AppError('Update not found', 404, 'NOT_FOUND'));
    const res = await request(app).get(`/api/v1/updates/${VALID_UUID}/comments`);
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('NOT_FOUND');
  });

  it('returns 404 WORKSPACE_NOT_FOUND when user has no workspace', async () => {
    mockListComments.mockRejectedValue(new AppError('Workspace not found', 404, 'WORKSPACE_NOT_FOUND'));
    const res = await request(app).get(`/api/v1/updates/${VALID_UUID}/comments`);
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('WORKSPACE_NOT_FOUND');
  });

  it('returns 500 DB_ERROR on service failure', async () => {
    mockListComments.mockRejectedValue(new AppError('Failed to fetch comments', 500, 'DB_ERROR'));
    const res = await request(app).get(`/api/v1/updates/${VALID_UUID}/comments`);
    expect(res.status).toBe(500);
    expect(res.body.error.code).toBe('DB_ERROR');
  });
});

describe('POST /api/v1/updates/:updateId/comments', () => {
  const validBody = { body: 'Looking great!' };

  it('returns 201 with created comment', async () => {
    mockCreateAgencyComment.mockResolvedValue(COMMENT);
    const res = await request(app)
      .post(`/api/v1/updates/${VALID_UUID}/comments`)
      .send(validBody);
    expect(res.status).toBe(201);
    expect(res.body).toEqual({ success: true, data: { comment: COMMENT } });
    expect(mockCreateAgencyComment).toHaveBeenCalledWith('user-1', VALID_UUID, { body: 'Looking great!' });
  });

  it('returns 201 with valid parent_id', async () => {
    const replyComment = { ...COMMENT, parent_id: VALID_UUID_2 };
    mockCreateAgencyComment.mockResolvedValue(replyComment);
    const res = await request(app)
      .post(`/api/v1/updates/${VALID_UUID}/comments`)
      .send({ ...validBody, parent_id: VALID_UUID_2 });
    expect(res.status).toBe(201);
    expect(mockCreateAgencyComment).toHaveBeenCalledWith('user-1', VALID_UUID, {
      body: 'Looking great!',
      parent_id: VALID_UUID_2,
    });
  });

  it('returns 400 VALIDATION_ERROR when body missing', async () => {
    const res = await request(app)
      .post(`/api/v1/updates/${VALID_UUID}/comments`)
      .send({});
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(mockCreateAgencyComment).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR when body too long', async () => {
    const res = await request(app)
      .post(`/api/v1/updates/${VALID_UUID}/comments`)
      .send({ body: 'x'.repeat(5001) });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(mockCreateAgencyComment).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for non-UUID updateId', async () => {
    const res = await request(app)
      .post('/api/v1/updates/not-a-uuid/comments')
      .send(validBody);
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(mockCreateAgencyComment).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for non-UUID parent_id', async () => {
    const res = await request(app)
      .post(`/api/v1/updates/${VALID_UUID}/comments`)
      .send({ ...validBody, parent_id: 'not-a-uuid' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(mockCreateAgencyComment).not.toHaveBeenCalled();
  });

  it('treats explicit null parent_id as omitted (no parent)', async () => {
    mockCreateAgencyComment.mockResolvedValue(COMMENT);
    const res = await request(app)
      .post(`/api/v1/updates/${VALID_UUID}/comments`)
      .send({ ...validBody, parent_id: null });
    expect(res.status).toBe(201);
    expect(mockCreateAgencyComment).toHaveBeenCalledWith('user-1', VALID_UUID, { body: 'Looking great!' });
  });

  it('returns 404 WORKSPACE_NOT_FOUND when user has no workspace', async () => {
    mockCreateAgencyComment.mockRejectedValue(new AppError('Workspace not found', 404, 'WORKSPACE_NOT_FOUND'));
    const res = await request(app)
      .post(`/api/v1/updates/${VALID_UUID}/comments`)
      .send(validBody);
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('WORKSPACE_NOT_FOUND');
  });

  it('returns 400 VALIDATION_ERROR when parent is not top-level', async () => {
    mockCreateAgencyComment.mockRejectedValue(
      new AppError('Replies can only be made to top-level comments', 400, 'VALIDATION_ERROR'),
    );
    const res = await request(app)
      .post(`/api/v1/updates/${VALID_UUID}/comments`)
      .send({ ...validBody, parent_id: VALID_UUID_2 });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
  });

  it('returns 404 NOT_FOUND when update missing', async () => {
    mockCreateAgencyComment.mockRejectedValue(new AppError('Update not found', 404, 'NOT_FOUND'));
    const res = await request(app)
      .post(`/api/v1/updates/${VALID_UUID}/comments`)
      .send(validBody);
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('NOT_FOUND');
  });

  it('returns 404 NOT_FOUND when parent comment missing', async () => {
    mockCreateAgencyComment.mockRejectedValue(
      new AppError('Parent comment not found', 404, 'NOT_FOUND'),
    );
    const res = await request(app)
      .post(`/api/v1/updates/${VALID_UUID}/comments`)
      .send({ ...validBody, parent_id: VALID_UUID_2 });
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('NOT_FOUND');
  });
});
