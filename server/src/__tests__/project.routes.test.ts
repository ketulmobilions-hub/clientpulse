jest.mock('express-rate-limit', () => jest.fn(() => (_req: unknown, _res: unknown, next: () => void) => next()));
jest.mock('../middleware/auth.middleware', () => ({
  requireAuth: (req: { user?: { id: string; email: string } }, _res: unknown, next: () => void) => {
    req.user = { id: 'user-1', email: 'pm@agency.com' };
    next();
  },
}));
jest.mock('../services/project.service');

import request from 'supertest';
import app from '../app';
import * as projectService from '../services/project.service';
import { AppError } from '../middleware/errorHandler';

const mockList = projectService.listProjects as jest.Mock;
const mockGet = projectService.getProject as jest.Mock;
const mockCreate = projectService.createProject as jest.Mock;
const mockUpdate = projectService.updateProject as jest.Mock;
const mockArchive = projectService.archiveProject as jest.Mock;

// Restore the const export that jest.mock wipes out
(projectService as unknown as Record<string, unknown>)['VALID_STATUSES'] = [
  'active',
  'completed',
  'archived',
];

const VALID_UUID = '12345678-1234-1234-1234-123456789012';

const PROJECT = {
  id: VALID_UUID,
  workspace_id: 'ws-1',
  name: 'Alpha',
  description: null,
  client_name: 'Acme',
  client_email: 'client@acme.com',
  status: 'active',
  share_token: 'tok123',
  created_at: '2026-01-01T00:00:00Z',
  updated_at: '2026-01-01T00:00:00Z',
};

beforeEach(() => jest.clearAllMocks());

describe('GET /api/v1/projects', () => {
  it('returns 200 with project list', async () => {
    mockList.mockResolvedValue([PROJECT]);
    const res = await request(app).get('/api/v1/projects');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ success: true, data: { projects: [PROJECT] } });
    expect(mockList).toHaveBeenCalledWith('user-1');
  });

  it('propagates service errors', async () => {
    mockList.mockRejectedValue(new AppError('Workspace not found', 404, 'WORKSPACE_NOT_FOUND'));
    const res = await request(app).get('/api/v1/projects');
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('WORKSPACE_NOT_FOUND');
  });
});

describe('POST /api/v1/projects', () => {
  const validBody = { name: 'Beta', client_name: 'Globex', client_email: 'hi@globex.com' };

  it('returns 201 with created project', async () => {
    mockCreate.mockResolvedValue(PROJECT);
    const res = await request(app).post('/api/v1/projects').send(validBody);
    expect(res.status).toBe(201);
    expect(res.body).toEqual({ success: true, data: { project: PROJECT } });
  });

  it('returns 400 VALIDATION_ERROR when name missing', async () => {
    const res = await request(app)
      .post('/api/v1/projects')
      .send({ client_name: 'Acme', client_email: 'a@b.com' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(mockCreate).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR when client_name missing', async () => {
    const res = await request(app)
      .post('/api/v1/projects')
      .send({ name: 'X', client_email: 'a@b.com' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
  });

  it('returns 400 VALIDATION_ERROR when client_email missing', async () => {
    const res = await request(app)
      .post('/api/v1/projects')
      .send({ name: 'X', client_name: 'Y' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
  });

  it('returns 400 VALIDATION_ERROR for invalid email format', async () => {
    const res = await request(app)
      .post('/api/v1/projects')
      .send({ ...validBody, client_email: 'notanemail' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(mockCreate).not.toHaveBeenCalled();
  });

  it('rejects email with no domain part', async () => {
    const res = await request(app)
      .post('/api/v1/projects')
      .send({ ...validBody, client_email: 'user@' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
  });

  it('passes optional description to service', async () => {
    mockCreate.mockResolvedValue(PROJECT);
    await request(app)
      .post('/api/v1/projects')
      .send({ ...validBody, description: 'A project' });
    expect(mockCreate).toHaveBeenCalledWith('user-1', expect.objectContaining({ description: 'A project' }));
  });

  it('propagates service VALIDATION_ERROR', async () => {
    mockCreate.mockRejectedValue(
      new AppError('client_email is not a valid email address', 400, 'VALIDATION_ERROR'),
    );
    const res = await request(app).post('/api/v1/projects').send(validBody);
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
  });
});

describe('GET /api/v1/projects/:id', () => {
  it('returns 200 with project', async () => {
    mockGet.mockResolvedValue(PROJECT);
    const res = await request(app).get(`/api/v1/projects/${VALID_UUID}`);
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ success: true, data: { project: PROJECT } });
    expect(mockGet).toHaveBeenCalledWith(VALID_UUID, 'user-1');
  });

  it('returns 400 VALIDATION_ERROR for non-UUID id', async () => {
    const res = await request(app).get('/api/v1/projects/not-a-uuid');
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(mockGet).not.toHaveBeenCalled();
  });

  it('returns 404 NOT_FOUND when project missing', async () => {
    mockGet.mockRejectedValue(new AppError('Project not found', 404, 'NOT_FOUND'));
    const res = await request(app).get(`/api/v1/projects/${VALID_UUID}`);
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('NOT_FOUND');
  });
});

describe('PATCH /api/v1/projects/:id', () => {
  it('returns 200 with updated project', async () => {
    mockUpdate.mockResolvedValue({ ...PROJECT, name: 'Gamma' });
    const res = await request(app).patch(`/api/v1/projects/${VALID_UUID}`).send({ name: 'Gamma' });
    expect(res.status).toBe(200);
    expect(res.body.data.project.name).toBe('Gamma');
  });

  it('returns 400 VALIDATION_ERROR for non-UUID id', async () => {
    const res = await request(app).patch('/api/v1/projects/not-a-uuid').send({ name: 'X' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(mockUpdate).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for unknown status', async () => {
    const res = await request(app)
      .patch(`/api/v1/projects/${VALID_UUID}`)
      .send({ status: 'deleted' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(mockUpdate).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_ERROR for invalid email format in PATCH', async () => {
    const res = await request(app)
      .patch(`/api/v1/projects/${VALID_UUID}`)
      .send({ client_email: 'notanemail' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(mockUpdate).not.toHaveBeenCalled();
  });

  it('accepts null description to clear it', async () => {
    mockUpdate.mockResolvedValue({ ...PROJECT, description: null });
    const res = await request(app)
      .patch(`/api/v1/projects/${VALID_UUID}`)
      .send({ description: null });
    expect(res.status).toBe(200);
    expect(mockUpdate).toHaveBeenCalledWith(
      VALID_UUID,
      'user-1',
      expect.objectContaining({ description: null }),
    );
  });

  it('accepts all valid status values', async () => {
    for (const status of ['active', 'completed', 'archived']) {
      jest.clearAllMocks();
      // Restore VALID_STATUSES after clearAllMocks wipes module state
      (projectService as unknown as Record<string, unknown>)['VALID_STATUSES'] = [
        'active', 'completed', 'archived',
      ];
      mockUpdate.mockResolvedValue({ ...PROJECT, status });
      const res = await request(app).patch(`/api/v1/projects/${VALID_UUID}`).send({ status });
      expect(res.status).toBe(200);
    }
  });
});

describe('DELETE /api/v1/projects/:id', () => {
  it('returns 200 with archived project', async () => {
    mockArchive.mockResolvedValue({ ...PROJECT, status: 'archived' });
    const res = await request(app).delete(`/api/v1/projects/${VALID_UUID}`);
    expect(res.status).toBe(200);
    expect(res.body.data.project.status).toBe('archived');
    expect(mockArchive).toHaveBeenCalledWith(VALID_UUID, 'user-1');
  });

  it('returns 400 VALIDATION_ERROR for non-UUID id', async () => {
    const res = await request(app).delete('/api/v1/projects/not-a-uuid');
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(mockArchive).not.toHaveBeenCalled();
  });

  it('returns 404 NOT_FOUND when project missing', async () => {
    mockArchive.mockRejectedValue(new AppError('Project not found', 404, 'NOT_FOUND'));
    const res = await request(app).delete(`/api/v1/projects/${VALID_UUID}`);
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('NOT_FOUND');
  });
});
