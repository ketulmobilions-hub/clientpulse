jest.mock('express-rate-limit', () => jest.fn(() => (_req: unknown, _res: unknown, next: () => void) => next()));
jest.mock('../services/portal.service');

import request from 'supertest';
import app from '../app';
import * as portalService from '../services/portal.service';
import { AppError } from '../middleware/errorHandler';
import { ErrorCodes } from '../errors/codes';

const mockGetOverview = portalService.getPortalOverview as jest.Mock;
const mockListUpdates = portalService.listPortalUpdates as jest.Mock;
const mockCreateComment = portalService.createPortalComment as jest.Mock;

const VALID_TOKEN = 'a'.repeat(64);
const INVALID_TOKEN = 'not-valid-hex!!';
const VALID_UUID = '12345678-1234-1234-1234-123456789012';

const WORKSPACE = { name: 'Acme Agency', slug: 'acme-agency', logo_url: null };
const PROJECT = {
  id: VALID_UUID,
  name: 'Website Redesign',
  description: 'Full redesign',
  client_name: 'Acme Corp',
  status: 'active',
  start_date: null,
  expected_end_date: null,
};
const MILESTONES = [
  { id: VALID_UUID, title: 'Discovery', due_date: null, completed: true, completed_at: '2026-04-01T00:00:00Z', position: 0 },
  { id: '87654321-4321-4321-4321-210987654321', title: 'Design', due_date: null, completed: false, completed_at: null, position: 1 },
];
const OVERVIEW = {
  workspace: WORKSPACE,
  project: PROJECT,
  milestones: MILESTONES,
  progress: { total: 2, completed: 1, percent: 50 },
};

const UPDATE = {
  id: VALID_UUID,
  title: 'Week 1 Update',
  body: 'Work is progressing',
  category: 'progress',
  position: 0,
  created_at: '2026-04-01T00:00:00Z',
  updated_at: '2026-04-01T00:00:00Z',
  attachments: [],
};

const COMMENT = {
  id: VALID_UUID,
  update_id: VALID_UUID,
  parent_id: null,
  author_type: 'client',
  author_name: 'Alice',
  body: 'Looks great!',
  created_at: '2026-04-02T00:00:00Z',
  updated_at: '2026-04-02T00:00:00Z',
};

beforeEach(() => jest.clearAllMocks());

describe('GET /api/v1/portal/:token', () => {
  it('returns 200 with workspace, project, milestones, and progress', async () => {
    mockGetOverview.mockResolvedValue(OVERVIEW);
    const res = await request(app).get(`/api/v1/portal/${VALID_TOKEN}`);
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ success: true, data: OVERVIEW });
    expect(mockGetOverview).toHaveBeenCalledWith(VALID_TOKEN);
  });

  it('returns progress percent 0 when no milestones', async () => {
    mockGetOverview.mockResolvedValue({ ...OVERVIEW, milestones: [], progress: { total: 0, completed: 0, percent: 0 } });
    const res = await request(app).get(`/api/v1/portal/${VALID_TOKEN}`);
    expect(res.status).toBe(200);
    expect(res.body.data.progress).toEqual({ total: 0, completed: 0, percent: 0 });
  });

  it('returns 401 INVALID_TOKEN for non-hex token format', async () => {
    const res = await request(app).get(`/api/v1/portal/${INVALID_TOKEN}`);
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe(ErrorCodes.INVALID_TOKEN);
    expect(mockGetOverview).not.toHaveBeenCalled();
  });

  it('returns 401 INVALID_TOKEN when service throws INVALID_TOKEN', async () => {
    mockGetOverview.mockRejectedValue(new AppError('Invalid or expired token', 401, ErrorCodes.INVALID_TOKEN));
    const res = await request(app).get(`/api/v1/portal/${VALID_TOKEN}`);
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe(ErrorCodes.INVALID_TOKEN);
  });

  it('returns 500 DB_ERROR on service DB failure', async () => {
    mockGetOverview.mockRejectedValue(new AppError('Database error', 500, ErrorCodes.DB_ERROR));
    const res = await request(app).get(`/api/v1/portal/${VALID_TOKEN}`);
    expect(res.status).toBe(500);
    expect(res.body.error.code).toBe(ErrorCodes.DB_ERROR);
  });
});

describe('GET /api/v1/portal/:token/updates', () => {
  const PAGE_RESULT = {
    updates: [UPDATE],
    pagination: { page: 1, limit: 20, total: 1 },
  };

  it('returns 200 with published updates and pagination', async () => {
    mockListUpdates.mockResolvedValue(PAGE_RESULT);
    const res = await request(app).get(`/api/v1/portal/${VALID_TOKEN}/updates`);
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ success: true, data: PAGE_RESULT });
    expect(mockListUpdates).toHaveBeenCalledWith(VALID_TOKEN, 1, 20);
  });

  it('passes page and limit query params to service', async () => {
    mockListUpdates.mockResolvedValue({ updates: [], pagination: { page: 2, limit: 5, total: 0 } });
    const res = await request(app).get(`/api/v1/portal/${VALID_TOKEN}/updates?page=2&limit=5`);
    expect(res.status).toBe(200);
    expect(mockListUpdates).toHaveBeenCalledWith(VALID_TOKEN, 2, 5);
  });

  it('defaults page=1 limit=20 when params absent', async () => {
    mockListUpdates.mockResolvedValue(PAGE_RESULT);
    await request(app).get(`/api/v1/portal/${VALID_TOKEN}/updates`);
    expect(mockListUpdates).toHaveBeenCalledWith(VALID_TOKEN, 1, 20);
  });

  it('returns 400 VALIDATION_ERROR when limit exceeds 50', async () => {
    const res = await request(app).get(`/api/v1/portal/${VALID_TOKEN}/updates?limit=51`);
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockListUpdates).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR when page is not a valid integer', async () => {
    const res = await request(app).get(`/api/v1/portal/${VALID_TOKEN}/updates?page=abc`);
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockListUpdates).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR when page is 0', async () => {
    const res = await request(app).get(`/api/v1/portal/${VALID_TOKEN}/updates?page=0`);
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockListUpdates).not.toHaveBeenCalled();
  });

  it('returns 401 INVALID_TOKEN for bad token format', async () => {
    const res = await request(app).get(`/api/v1/portal/${INVALID_TOKEN}/updates`);
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe(ErrorCodes.INVALID_TOKEN);
    expect(mockListUpdates).not.toHaveBeenCalled();
  });

  it('returns 401 INVALID_TOKEN when service throws', async () => {
    mockListUpdates.mockRejectedValue(new AppError('Invalid or expired token', 401, ErrorCodes.INVALID_TOKEN));
    const res = await request(app).get(`/api/v1/portal/${VALID_TOKEN}/updates`);
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe(ErrorCodes.INVALID_TOKEN);
  });
});

describe('POST /api/v1/portal/:token/updates/:updateId/comments', () => {
  const validBody = { author_name: 'Alice', body: 'Looks great!' };

  it('returns 201 with created comment', async () => {
    mockCreateComment.mockResolvedValue(COMMENT);
    const res = await request(app)
      .post(`/api/v1/portal/${VALID_TOKEN}/updates/${VALID_UUID}/comments`)
      .send(validBody);
    expect(res.status).toBe(201);
    expect(res.body).toEqual({ success: true, data: { comment: COMMENT } });
    expect(mockCreateComment).toHaveBeenCalledWith(VALID_TOKEN, VALID_UUID, { author_name: 'Alice', body: 'Looks great!', parent_id: undefined });
  });

  it('passes parent_id when provided', async () => {
    const parentId = '11111111-1111-1111-1111-111111111111';
    mockCreateComment.mockResolvedValue({ ...COMMENT, parent_id: parentId });
    const res = await request(app)
      .post(`/api/v1/portal/${VALID_TOKEN}/updates/${VALID_UUID}/comments`)
      .send({ ...validBody, parent_id: parentId });
    expect(res.status).toBe(201);
    expect(mockCreateComment).toHaveBeenCalledWith(VALID_TOKEN, VALID_UUID, { author_name: 'Alice', body: 'Looks great!', parent_id: parentId });
  });

  it('returns 400 VALIDATION_ERROR when author_name is missing', async () => {
    const res = await request(app)
      .post(`/api/v1/portal/${VALID_TOKEN}/updates/${VALID_UUID}/comments`)
      .send({ body: 'Hi' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockCreateComment).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR when body is missing', async () => {
    const res = await request(app)
      .post(`/api/v1/portal/${VALID_TOKEN}/updates/${VALID_UUID}/comments`)
      .send({ author_name: 'Alice' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockCreateComment).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR when author_name is empty string', async () => {
    const res = await request(app)
      .post(`/api/v1/portal/${VALID_TOKEN}/updates/${VALID_UUID}/comments`)
      .send({ author_name: '', body: 'Hi' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockCreateComment).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for non-UUID updateId', async () => {
    const res = await request(app)
      .post(`/api/v1/portal/${VALID_TOKEN}/updates/not-a-uuid/comments`)
      .send(validBody);
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockCreateComment).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for non-UUID parent_id', async () => {
    const res = await request(app)
      .post(`/api/v1/portal/${VALID_TOKEN}/updates/${VALID_UUID}/comments`)
      .send({ ...validBody, parent_id: 'not-a-uuid' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockCreateComment).not.toHaveBeenCalled();
  });

  it('returns 401 INVALID_TOKEN for bad token format', async () => {
    const res = await request(app)
      .post(`/api/v1/portal/${INVALID_TOKEN}/updates/${VALID_UUID}/comments`)
      .send(validBody);
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe(ErrorCodes.INVALID_TOKEN);
    expect(mockCreateComment).not.toHaveBeenCalled();
  });

  it('returns 404 NOT_FOUND when update does not belong to project', async () => {
    mockCreateComment.mockRejectedValue(new AppError('Update not found', 404, ErrorCodes.NOT_FOUND));
    const res = await request(app)
      .post(`/api/v1/portal/${VALID_TOKEN}/updates/${VALID_UUID}/comments`)
      .send(validBody);
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe(ErrorCodes.NOT_FOUND);
  });

  it('returns 401 INVALID_TOKEN when service throws for bad share token', async () => {
    mockCreateComment.mockRejectedValue(new AppError('Invalid or expired token', 401, ErrorCodes.INVALID_TOKEN));
    const res = await request(app)
      .post(`/api/v1/portal/${VALID_TOKEN}/updates/${VALID_UUID}/comments`)
      .send(validBody);
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe(ErrorCodes.INVALID_TOKEN);
  });

  it('returns 404 NOT_FOUND when parent comment does not belong to update', async () => {
    const parentId = '22222222-2222-2222-2222-222222222222';
    mockCreateComment.mockRejectedValue(new AppError('Parent comment not found', 404, ErrorCodes.NOT_FOUND));
    const res = await request(app)
      .post(`/api/v1/portal/${VALID_TOKEN}/updates/${VALID_UUID}/comments`)
      .send({ ...validBody, parent_id: parentId });
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe(ErrorCodes.NOT_FOUND);
  });

  it('returns 400 VALIDATION_ERROR when parent comment is itself a reply (depth > 1)', async () => {
    const parentId = '33333333-3333-3333-3333-333333333333';
    mockCreateComment.mockRejectedValue(new AppError('Replies can only be made to top-level comments', 400, ErrorCodes.VALIDATION_ERROR));
    const res = await request(app)
      .post(`/api/v1/portal/${VALID_TOKEN}/updates/${VALID_UUID}/comments`)
      .send({ ...validBody, parent_id: parentId });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
  });
});
