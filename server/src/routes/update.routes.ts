import { Router, Request, Response, NextFunction } from 'express';
import { AppError } from '../middleware/errorHandler';
import { requireAuth } from '../middleware/auth.middleware';
import { validateString } from '../utils/validation';
import {
  createUpdate,
  listUpdates,
  getUpdate,
  editUpdate,
  deleteUpdate,
  VALID_UPDATE_STATUSES,
  VALID_UPDATE_CATEGORIES,
} from '../services/update.service';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function validateUuid(value: string, field: string): void {
  if (!UUID_RE.test(value)) {
    throw new AppError(`${field} must be a valid UUID`, 400, 'VALIDATION_ERROR');
  }
}

// Mounted at /api/v1/projects/:projectId/updates — requires mergeParams: true
export const projectUpdateRouter = Router({ mergeParams: true });
projectUpdateRouter.use(requireAuth);

projectUpdateRouter.post('/', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    validateUuid(req.params['projectId'] as string, 'projectId');

    const title = validateString(req.body?.title, 'title', 1, 200);
    const body = validateString(req.body?.body, 'body', 1, 10000);

    let category: 'progress' | 'milestone' | 'deliverable' | 'blocker' | 'input_needed' | undefined;
    if (req.body?.category !== undefined) {
      if (!(VALID_UPDATE_CATEGORIES as readonly string[]).includes(req.body.category)) {
        throw new AppError(
          `category must be one of: ${VALID_UPDATE_CATEGORIES.join(', ')}`,
          400,
          'VALIDATION_ERROR',
        );
      }
      category = req.body.category;
    }

    let status: 'draft' | 'published' | undefined;
    if (req.body?.status !== undefined) {
      if (!(VALID_UPDATE_STATUSES as readonly string[]).includes(req.body.status)) {
        throw new AppError(
          `status must be one of: ${VALID_UPDATE_STATUSES.join(', ')}`,
          400,
          'VALIDATION_ERROR',
        );
      }
      status = req.body.status;
    }

    const update = await createUpdate(req.user!.id, req.params['projectId'] as string, {
      title,
      body,
      category,
      status,
    });
    res.status(201).json({ success: true, data: { update } });
  } catch (err) {
    next(err);
  }
});

projectUpdateRouter.get('/', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    validateUuid(req.params['projectId'] as string, 'projectId');
    const updates = await listUpdates(req.user!.id, req.params['projectId'] as string);
    res.json({ success: true, data: { updates } });
  } catch (err) {
    next(err);
  }
});

// Mounted at /api/v1/updates
export const updateRouter = Router();
updateRouter.use(requireAuth);

updateRouter.get('/:id', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    validateUuid(req.params['id'] as string, 'id');
    const update = await getUpdate(req.user!.id, req.params['id'] as string);
    res.json({ success: true, data: { update } });
  } catch (err) {
    next(err);
  }
});

updateRouter.patch('/:id', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    validateUuid(req.params['id'] as string, 'id');

    const changes: Parameters<typeof editUpdate>[2] = {};

    if (req.body?.title !== undefined) {
      changes.title = validateString(req.body.title, 'title', 1, 200);
    }
    if (req.body?.body !== undefined) {
      changes.body = validateString(req.body.body, 'body', 1, 10000);
    }
    if (req.body?.category !== undefined) {
      if (!(VALID_UPDATE_CATEGORIES as readonly string[]).includes(req.body.category)) {
        throw new AppError(
          `category must be one of: ${VALID_UPDATE_CATEGORIES.join(', ')}`,
          400,
          'VALIDATION_ERROR',
        );
      }
      changes.category = req.body.category;
    }
    if (req.body?.status !== undefined) {
      if (!(VALID_UPDATE_STATUSES as readonly string[]).includes(req.body.status)) {
        throw new AppError(
          `status must be one of: ${VALID_UPDATE_STATUSES.join(', ')}`,
          400,
          'VALIDATION_ERROR',
        );
      }
      changes.status = req.body.status;
    }

    if (req.body?.position !== undefined) {
      const pos = Number(req.body.position);
      if (!Number.isInteger(pos) || pos < 0) {
        throw new AppError('position must be a non-negative integer', 400, 'VALIDATION_ERROR');
      }
      changes.position = pos;
    }

    const update = await editUpdate(req.user!.id, req.params['id'] as string, changes);
    res.json({ success: true, data: { update } });
  } catch (err) {
    next(err);
  }
});

updateRouter.delete('/:id', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    validateUuid(req.params['id'] as string, 'id');
    await deleteUpdate(req.user!.id, req.params['id'] as string);
    res.status(204).send();
  } catch (err) {
    next(err);
  }
});
