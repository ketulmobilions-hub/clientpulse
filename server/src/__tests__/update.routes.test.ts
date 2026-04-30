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

const mockCreate = updateService.createUpdate as jest.Mock;
const mockList = updateService.listUpdates as jest.Mock;
const mockGet = updateService.getUpdate as jest.Mock;
const mockEdit = updateService.editUpdate as jest.Mock;
const mockDelete = updateService.deleteUpdate as jest.Mock;

// Use jest.requireActual to source enum values from the real module — avoids silent
// divergence when values are added/removed from the service.
const {
  VALID_UPDATE_STATUSES: REAL_STATUSES,
  VALID_UPDATE_CATEGORIES: REAL_CATEGORIES,
} = jest.requireActual<typeof updateService>('../services/update.service');

function restoreConstants() {
  (updateService as unknown as Record<string, unknown>)['VALID_UPDATE_STATUSES'] = REAL_STATUSES;
  (updateService as unknown as Record<string, unknown>)['VALID_UPDATE_CATEGORIES'] = REAL_CATEGORIES;
}

const VALID_UUID = '12345678-1234-1234-1234-123456789012';
const VALID_UUID_2 = '87654321-4321-4321-4321-210987654321';

const UPDATE = {
  id: VALID_UUID_2,
  project_id: VALID_UUID,
  author_id: 'user-1',
  title: 'Week 1 Progress',
  body: 'Backend is done',
  status: 'draft',
  category: 'progress',
  position: 0,
  notification_sent_at: null,
  created_at: '2026-01-01T00:00:00Z',
  updated_at: '2026-01-01T00:00:00Z',
};

const UPDATE_WITH_RELATIONS = {
  ...UPDATE,
  attachments: [],
  comments: [],
};

beforeEach(() => {
  jest.clearAllMocks();
  restoreConstants();
});

describe('POST /api/v1/projects/:projectId/updates', () => {
  const validBody = { title: 'Week 1', body: 'Progress on backend' };

  it('returns 201 with created update', async () => {
    mockCreate.mockResolvedValue(UPDATE);
    const res = await request(app)
      .post(`/api/v1/projects/${VALID_UUID}/updates`)
      .send(validBody);
    expect(res.status).toBe(201);
    expect(res.body).toEqual({ success: true, data: { update: UPDATE } });
    expect(mockCreate).toHaveBeenCalledWith('user-1', VALID_UUID, expect.objectContaining({ title: 'Week 1', body: 'Progress on backend' }));
  });

  it('returns 400 VALIDATION_ERROR when title missing', async () => {
    const res = await request(app)
      .post(`/api/v1/projects/${VALID_UUID}/updates`)
      .send({ body: 'No title' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(mockCreate).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR when body missing', async () => {
    const res = await request(app)
      .post(`/api/v1/projects/${VALID_UUID}/updates`)
      .send({ title: 'No body' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(mockCreate).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for invalid category', async () => {
    const res = await request(app)
      .post(`/api/v1/projects/${VALID_UUID}/updates`)
      .send({ ...validBody, category: 'invalid' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(mockCreate).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for invalid status', async () => {
    const res = await request(app)
      .post(`/api/v1/projects/${VALID_UUID}/updates`)
      .send({ ...validBody, status: 'archived' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(mockCreate).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for non-UUID projectId', async () => {
    const res = await request(app)
      .post('/api/v1/projects/not-a-uuid/updates')
      .send(validBody);
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(mockCreate).not.toHaveBeenCalled();
  });

  it('accepts valid category and status', async () => {
    mockCreate.mockResolvedValue(UPDATE);
    const res = await request(app)
      .post(`/api/v1/projects/${VALID_UUID}/updates`)
      .send({ ...validBody, category: 'milestone', status: 'published' });
    expect(res.status).toBe(201);
    expect(mockCreate).toHaveBeenCalledWith('user-1', VALID_UUID, expect.objectContaining({ category: 'milestone', status: 'published' }));
  });

  it('accepts all 5 new categories', async () => {
    for (const category of REAL_CATEGORIES) {
      jest.clearAllMocks();
      restoreConstants();
      mockCreate.mockResolvedValue({ ...UPDATE, category });
      const res = await request(app)
        .post(`/api/v1/projects/${VALID_UUID}/updates`)
        .send({ ...validBody, category });
      expect(res.status).toBe(201);
    }
  });

  it('returns 400 VALIDATION_ERROR for legacy general category', async () => {
    const res = await request(app)
      .post(`/api/v1/projects/${VALID_UUID}/updates`)
      .send({ ...validBody, category: 'general' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(mockCreate).not.toHaveBeenCalled();
  });

  it('propagates service NOT_FOUND', async () => {
    mockCreate.mockRejectedValue(new AppError('Project not found', 404, 'NOT_FOUND'));
    const res = await request(app)
      .post(`/api/v1/projects/${VALID_UUID}/updates`)
      .send(validBody);
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('NOT_FOUND');
  });
});

describe('GET /api/v1/projects/:projectId/updates', () => {
  it('returns 200 with updates list', async () => {
    mockList.mockResolvedValue([UPDATE]);
    const res = await request(app).get(`/api/v1/projects/${VALID_UUID}/updates`);
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ success: true, data: { updates: [UPDATE] } });
    expect(mockList).toHaveBeenCalledWith('user-1', VALID_UUID);
  });

  it('returns 400 VALIDATION_ERROR for non-UUID projectId', async () => {
    const res = await request(app).get('/api/v1/projects/not-a-uuid/updates');
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(mockList).not.toHaveBeenCalled();
  });

  it('propagates service NOT_FOUND', async () => {
    mockList.mockRejectedValue(new AppError('Project not found', 404, 'NOT_FOUND'));
    const res = await request(app).get(`/api/v1/projects/${VALID_UUID}/updates`);
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('NOT_FOUND');
  });
});

describe('GET /api/v1/updates/:id', () => {
  it('returns 200 with update including attachments and comments', async () => {
    mockGet.mockResolvedValue(UPDATE_WITH_RELATIONS);
    const res = await request(app).get(`/api/v1/updates/${VALID_UUID_2}`);
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ success: true, data: { update: UPDATE_WITH_RELATIONS } });
    expect(mockGet).toHaveBeenCalledWith('user-1', VALID_UUID_2);
  });

  it('returns 400 VALIDATION_ERROR for non-UUID id', async () => {
    const res = await request(app).get('/api/v1/updates/not-a-uuid');
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(mockGet).not.toHaveBeenCalled();
  });

  it('returns 404 NOT_FOUND when update missing', async () => {
    mockGet.mockRejectedValue(new AppError('Update not found', 404, 'NOT_FOUND'));
    const res = await request(app).get(`/api/v1/updates/${VALID_UUID_2}`);
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('NOT_FOUND');
  });
});

describe('PATCH /api/v1/updates/:id', () => {
  it('returns 200 with updated update', async () => {
    const updated = { ...UPDATE, title: 'Week 2' };
    mockEdit.mockResolvedValue(updated);
    const res = await request(app)
      .patch(`/api/v1/updates/${VALID_UUID_2}`)
      .send({ title: 'Week 2' });
    expect(res.status).toBe(200);
    expect(res.body.data.update.title).toBe('Week 2');
    expect(mockEdit).toHaveBeenCalledWith('user-1', VALID_UUID_2, expect.objectContaining({ title: 'Week 2' }));
  });

  it('returns 400 VALIDATION_ERROR for empty body', async () => {
    mockEdit.mockRejectedValue(new AppError('No fields to update', 400, 'VALIDATION_ERROR'));
    const res = await request(app)
      .patch(`/api/v1/updates/${VALID_UUID_2}`)
      .send({});
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
  });

  it('returns 400 VALIDATION_ERROR for non-UUID id', async () => {
    const res = await request(app).patch('/api/v1/updates/not-a-uuid').send({ title: 'X' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(mockEdit).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for invalid category', async () => {
    const res = await request(app)
      .patch(`/api/v1/updates/${VALID_UUID_2}`)
      .send({ category: 'unknown' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(mockEdit).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for invalid status', async () => {
    const res = await request(app)
      .patch(`/api/v1/updates/${VALID_UUID_2}`)
      .send({ status: 'deleted' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(mockEdit).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for negative position', async () => {
    const res = await request(app)
      .patch(`/api/v1/updates/${VALID_UUID_2}`)
      .send({ position: -1 });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(mockEdit).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for non-integer position', async () => {
    const res = await request(app)
      .patch(`/api/v1/updates/${VALID_UUID_2}`)
      .send({ position: 1.5 });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(mockEdit).not.toHaveBeenCalled();
  });

  it('accepts valid position and passes to service', async () => {
    mockEdit.mockResolvedValue({ ...UPDATE, position: 2 });
    const res = await request(app)
      .patch(`/api/v1/updates/${VALID_UUID_2}`)
      .send({ position: 2 });
    expect(res.status).toBe(200);
    expect(mockEdit).toHaveBeenCalledWith('user-1', VALID_UUID_2, expect.objectContaining({ position: 2 }));
  });

  it('accepts all valid categories', async () => {
    for (const category of REAL_CATEGORIES) {
      jest.clearAllMocks();
      restoreConstants();
      mockEdit.mockResolvedValue({ ...UPDATE, category });
      const res = await request(app)
        .patch(`/api/v1/updates/${VALID_UUID_2}`)
        .send({ category });
      expect(res.status).toBe(200);
    }
  });

  it('accepts all valid statuses', async () => {
    for (const status of REAL_STATUSES) {
      jest.clearAllMocks();
      restoreConstants();
      mockEdit.mockResolvedValue({ ...UPDATE, status });
      const res = await request(app)
        .patch(`/api/v1/updates/${VALID_UUID_2}`)
        .send({ status });
      expect(res.status).toBe(200);
    }
  });

  it('propagates service NOT_FOUND', async () => {
    mockEdit.mockRejectedValue(new AppError('Update not found', 404, 'NOT_FOUND'));
    const res = await request(app)
      .patch(`/api/v1/updates/${VALID_UUID_2}`)
      .send({ title: 'X' });
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('NOT_FOUND');
  });
});

describe('DELETE /api/v1/updates/:id', () => {
  it('returns 204 on success', async () => {
    mockDelete.mockResolvedValue(undefined);
    const res = await request(app).delete(`/api/v1/updates/${VALID_UUID_2}`);
    expect(res.status).toBe(204);
    expect(mockDelete).toHaveBeenCalledWith('user-1', VALID_UUID_2);
  });

  it('returns 400 VALIDATION_ERROR for non-UUID id', async () => {
    const res = await request(app).delete('/api/v1/updates/not-a-uuid');
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(mockDelete).not.toHaveBeenCalled();
  });

  it('returns 404 NOT_FOUND when update missing', async () => {
    mockDelete.mockRejectedValue(new AppError('Update not found', 404, 'NOT_FOUND'));
    const res = await request(app).delete(`/api/v1/updates/${VALID_UUID_2}`);
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('NOT_FOUND');
  });

  it('returns 500 DB_ERROR when deletion unconfirmed', async () => {
    mockDelete.mockRejectedValue(new AppError('Failed to confirm deletion', 500, 'DB_ERROR'));
    const res = await request(app).delete(`/api/v1/updates/${VALID_UUID_2}`);
    expect(res.status).toBe(500);
    expect(res.body.error.code).toBe('DB_ERROR');
  });
});
