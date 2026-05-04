jest.mock('express-rate-limit', () => jest.fn(() => (_req: unknown, _res: unknown, next: () => void) => next()));
jest.mock('../middleware/auth.middleware', () => ({
  requireAuth: (req: { user?: { id: string; email: string } }, _res: unknown, next: () => void) => {
    req.user = { id: 'user-1', email: 'pm@agency.com' };
    next();
  },
}));
jest.mock('../services/milestone.service');

import request from 'supertest';
import app from '../app';
import * as milestoneService from '../services/milestone.service';
import { AppError } from '../middleware/errorHandler';
import { ErrorCodes } from '../errors/codes';

const mockList = milestoneService.listMilestones as jest.Mock;
const mockCreate = milestoneService.createMilestone as jest.Mock;
const mockUpdate = milestoneService.updateMilestone as jest.Mock;
const mockDelete = milestoneService.deleteMilestone as jest.Mock;

const VALID_UUID = '12345678-1234-1234-1234-123456789012';
const VALID_UUID_2 = '87654321-4321-4321-4321-210987654321';

const MILESTONE = {
  id: VALID_UUID_2,
  project_id: VALID_UUID,
  title: 'Beta Launch',
  due_date: '2026-05-11',
  completed: false,
  completed_at: null,
  position: 0,
  created_at: '2026-01-01T00:00:00Z',
  updated_at: '2026-01-01T00:00:00Z',
};

beforeEach(() => jest.clearAllMocks());

describe('GET /api/v1/projects/:projectId/milestones', () => {
  it('returns 200 with milestones list', async () => {
    mockList.mockResolvedValue([MILESTONE]);
    const res = await request(app).get(`/api/v1/projects/${VALID_UUID}/milestones`);
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ success: true, data: { milestones: [MILESTONE] } });
    expect(mockList).toHaveBeenCalledWith(VALID_UUID, 'user-1');
  });

  it('returns 200 with empty array when no milestones', async () => {
    mockList.mockResolvedValue([]);
    const res = await request(app).get(`/api/v1/projects/${VALID_UUID}/milestones`);
    expect(res.status).toBe(200);
    expect(res.body.data.milestones).toEqual([]);
  });

  it('returns 400 VALIDATION_ERROR for non-UUID projectId', async () => {
    const res = await request(app).get('/api/v1/projects/not-a-uuid/milestones');
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockList).not.toHaveBeenCalled();
  });

  it('propagates service NOT_FOUND', async () => {
    mockList.mockRejectedValue(new AppError('Project not found', 404, ErrorCodes.NOT_FOUND));
    const res = await request(app).get(`/api/v1/projects/${VALID_UUID}/milestones`);
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe(ErrorCodes.NOT_FOUND);
  });
});

describe('POST /api/v1/projects/:projectId/milestones', () => {
  const validBody = { title: 'Beta Launch' };

  it('returns 201 with created milestone', async () => {
    mockCreate.mockResolvedValue(MILESTONE);
    const res = await request(app)
      .post(`/api/v1/projects/${VALID_UUID}/milestones`)
      .send(validBody);
    expect(res.status).toBe(201);
    expect(res.body).toEqual({ success: true, data: { milestone: MILESTONE } });
    expect(mockCreate).toHaveBeenCalledWith(VALID_UUID, 'user-1', expect.objectContaining({ title: 'Beta Launch' }));
  });

  it('returns 400 VALIDATION_ERROR when title missing', async () => {
    const res = await request(app)
      .post(`/api/v1/projects/${VALID_UUID}/milestones`)
      .send({});
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockCreate).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for empty string title', async () => {
    const res = await request(app)
      .post(`/api/v1/projects/${VALID_UUID}/milestones`)
      .send({ title: '' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockCreate).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for whitespace-only title', async () => {
    const res = await request(app)
      .post(`/api/v1/projects/${VALID_UUID}/milestones`)
      .send({ title: '   ' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockCreate).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for null title', async () => {
    const res = await request(app)
      .post(`/api/v1/projects/${VALID_UUID}/milestones`)
      .send({ title: null });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockCreate).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for non-UUID projectId', async () => {
    const res = await request(app)
      .post('/api/v1/projects/not-a-uuid/milestones')
      .send(validBody);
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockCreate).not.toHaveBeenCalled();
  });

  it('accepts valid due_date and position', async () => {
    mockCreate.mockResolvedValue(MILESTONE);
    const res = await request(app)
      .post(`/api/v1/projects/${VALID_UUID}/milestones`)
      .send({ ...validBody, due_date: '2026-05-11', position: 2 });
    expect(res.status).toBe(201);
    expect(mockCreate).toHaveBeenCalledWith(VALID_UUID, 'user-1', expect.objectContaining({ due_date: '2026-05-11', position: 2 }));
  });

  it('accepts null due_date', async () => {
    mockCreate.mockResolvedValue({ ...MILESTONE, due_date: null });
    const res = await request(app)
      .post(`/api/v1/projects/${VALID_UUID}/milestones`)
      .send({ ...validBody, due_date: null });
    expect(res.status).toBe(201);
    expect(mockCreate).toHaveBeenCalledWith(VALID_UUID, 'user-1', expect.objectContaining({ due_date: null }));
  });

  it('returns 400 VALIDATION_ERROR for invalid due_date format', async () => {
    const res = await request(app)
      .post(`/api/v1/projects/${VALID_UUID}/milestones`)
      .send({ ...validBody, due_date: 'not-a-date' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockCreate).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for semantically invalid date (e.g. month 99)', async () => {
    const res = await request(app)
      .post(`/api/v1/projects/${VALID_UUID}/milestones`)
      .send({ ...validBody, due_date: '2026-99-01' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockCreate).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for out-of-range year', async () => {
    const res = await request(app)
      .post(`/api/v1/projects/${VALID_UUID}/milestones`)
      .send({ ...validBody, due_date: '1999-01-01' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockCreate).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for null position', async () => {
    const res = await request(app)
      .post(`/api/v1/projects/${VALID_UUID}/milestones`)
      .send({ ...validBody, position: null });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockCreate).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for negative position', async () => {
    const res = await request(app)
      .post(`/api/v1/projects/${VALID_UUID}/milestones`)
      .send({ ...validBody, position: -1 });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockCreate).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for non-integer position', async () => {
    const res = await request(app)
      .post(`/api/v1/projects/${VALID_UUID}/milestones`)
      .send({ ...validBody, position: 1.5 });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockCreate).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for position exceeding upper bound', async () => {
    const res = await request(app)
      .post(`/api/v1/projects/${VALID_UUID}/milestones`)
      .send({ ...validBody, position: 100_001 });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockCreate).not.toHaveBeenCalled();
  });

  it('propagates service NOT_FOUND', async () => {
    mockCreate.mockRejectedValue(new AppError('Project not found', 404, ErrorCodes.NOT_FOUND));
    const res = await request(app)
      .post(`/api/v1/projects/${VALID_UUID}/milestones`)
      .send(validBody);
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe(ErrorCodes.NOT_FOUND);
  });
});

describe('PATCH /api/v1/milestones/:id', () => {
  it('returns 200 with updated milestone', async () => {
    const updated = { ...MILESTONE, title: 'Phase 2' };
    mockUpdate.mockResolvedValue(updated);
    const res = await request(app)
      .patch(`/api/v1/milestones/${VALID_UUID_2}`)
      .send({ title: 'Phase 2' });
    expect(res.status).toBe(200);
    expect(res.body.data.milestone.title).toBe('Phase 2');
    expect(mockUpdate).toHaveBeenCalledWith(VALID_UUID_2, 'user-1', expect.objectContaining({ title: 'Phase 2' }));
  });

  it('returns 200 when completed set to true', async () => {
    const updated = { ...MILESTONE, completed: true, completed_at: '2026-05-01T00:00:00Z' };
    mockUpdate.mockResolvedValue(updated);
    const res = await request(app)
      .patch(`/api/v1/milestones/${VALID_UUID_2}`)
      .send({ completed: true });
    expect(res.status).toBe(200);
    expect(mockUpdate).toHaveBeenCalledWith(VALID_UUID_2, 'user-1', expect.objectContaining({ completed: true }));
  });

  it('returns 400 VALIDATION_ERROR for empty body (route-level guard)', async () => {
    const res = await request(app)
      .patch(`/api/v1/milestones/${VALID_UUID_2}`)
      .send({});
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockUpdate).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR when completed is not boolean', async () => {
    const res = await request(app)
      .patch(`/api/v1/milestones/${VALID_UUID_2}`)
      .send({ completed: 'yes' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockUpdate).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for empty string title', async () => {
    const res = await request(app)
      .patch(`/api/v1/milestones/${VALID_UUID_2}`)
      .send({ title: '' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockUpdate).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for null title', async () => {
    const res = await request(app)
      .patch(`/api/v1/milestones/${VALID_UUID_2}`)
      .send({ title: null });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockUpdate).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for non-UUID id', async () => {
    const res = await request(app).patch('/api/v1/milestones/not-a-uuid').send({ title: 'X' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockUpdate).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for invalid due_date format', async () => {
    const res = await request(app)
      .patch(`/api/v1/milestones/${VALID_UUID_2}`)
      .send({ due_date: 'bad-date' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockUpdate).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for semantically invalid date (e.g. Feb 31)', async () => {
    const res = await request(app)
      .patch(`/api/v1/milestones/${VALID_UUID_2}`)
      .send({ due_date: '2026-02-31' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockUpdate).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for out-of-range year in due_date', async () => {
    const res = await request(app)
      .patch(`/api/v1/milestones/${VALID_UUID_2}`)
      .send({ due_date: '2200-01-01' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockUpdate).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for null position', async () => {
    const res = await request(app)
      .patch(`/api/v1/milestones/${VALID_UUID_2}`)
      .send({ position: null });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockUpdate).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for negative position', async () => {
    const res = await request(app)
      .patch(`/api/v1/milestones/${VALID_UUID_2}`)
      .send({ position: -1 });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockUpdate).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for position exceeding upper bound', async () => {
    const res = await request(app)
      .patch(`/api/v1/milestones/${VALID_UUID_2}`)
      .send({ position: 100_001 });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockUpdate).not.toHaveBeenCalled();
  });

  it('accepts null due_date to clear the field', async () => {
    mockUpdate.mockResolvedValue({ ...MILESTONE, due_date: null });
    const res = await request(app)
      .patch(`/api/v1/milestones/${VALID_UUID_2}`)
      .send({ due_date: null });
    expect(res.status).toBe(200);
    expect(mockUpdate).toHaveBeenCalledWith(VALID_UUID_2, 'user-1', expect.objectContaining({ due_date: null }));
  });

  it('accepts valid position', async () => {
    mockUpdate.mockResolvedValue({ ...MILESTONE, position: 2 });
    const res = await request(app)
      .patch(`/api/v1/milestones/${VALID_UUID_2}`)
      .send({ position: 2 });
    expect(res.status).toBe(200);
    expect(mockUpdate).toHaveBeenCalledWith(VALID_UUID_2, 'user-1', expect.objectContaining({ position: 2 }));
  });

  it('propagates service NOT_FOUND', async () => {
    mockUpdate.mockRejectedValue(new AppError('Milestone not found', 404, ErrorCodes.NOT_FOUND));
    const res = await request(app)
      .patch(`/api/v1/milestones/${VALID_UUID_2}`)
      .send({ title: 'X' });
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe(ErrorCodes.NOT_FOUND);
  });
});

describe('DELETE /api/v1/milestones/:id', () => {
  it('returns 204 on success', async () => {
    mockDelete.mockResolvedValue(undefined);
    const res = await request(app).delete(`/api/v1/milestones/${VALID_UUID_2}`);
    expect(res.status).toBe(204);
    expect(mockDelete).toHaveBeenCalledWith(VALID_UUID_2, 'user-1');
  });

  it('returns 400 VALIDATION_ERROR for non-UUID id', async () => {
    const res = await request(app).delete('/api/v1/milestones/not-a-uuid');
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(mockDelete).not.toHaveBeenCalled();
  });

  it('returns 404 NOT_FOUND when milestone missing', async () => {
    mockDelete.mockRejectedValue(new AppError('Milestone not found', 404, ErrorCodes.NOT_FOUND));
    const res = await request(app).delete(`/api/v1/milestones/${VALID_UUID_2}`);
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe(ErrorCodes.NOT_FOUND);
  });

  it('returns 500 DB_ERROR when deletion unconfirmed', async () => {
    mockDelete.mockRejectedValue(new AppError('Failed to confirm deletion', 500, ErrorCodes.DB_ERROR));
    const res = await request(app).delete(`/api/v1/milestones/${VALID_UUID_2}`);
    expect(res.status).toBe(500);
    expect(res.body.error.code).toBe(ErrorCodes.DB_ERROR);
  });
});
