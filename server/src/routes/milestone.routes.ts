import { Router, Request, Response, NextFunction } from 'express';
import { AppError } from '../middleware/errorHandler';
import { requireAuth } from '../middleware/auth.middleware';
import { validateString } from '../utils/validation';
import {
  listMilestones,
  createMilestone,
  updateMilestone,
  deleteMilestone,
} from '../services/milestone.service';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function validateUuid(value: string, field: string): void {
  if (!UUID_RE.test(value)) {
    throw new AppError(`${field} must be a valid UUID`, 400, 'VALIDATION_ERROR');
  }
}

function validateDueDate(value: unknown, field: string): string | null {
  if (value === null) return null;
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    throw new AppError(`${field} must be a date string in YYYY-MM-DD format`, 400, 'VALIDATION_ERROR');
  }
  // Parse manually — JS Date rolls over invalid dates (e.g. Feb 31 → Mar 3) so isNaN() alone is unreliable.
  const [yearStr, monthStr, dayStr] = value.split('-');
  const year = parseInt(yearStr, 10);
  const month = parseInt(monthStr, 10);
  const day = parseInt(dayStr, 10);

  if (year < 2000 || year > 2100) {
    throw new AppError(`${field} year must be between 2000 and 2100`, 400, 'VALIDATION_ERROR');
  }
  if (month < 1 || month > 12) {
    throw new AppError(`${field} must be a valid calendar date`, 400, 'VALIDATION_ERROR');
  }
  // new Date(year, month, 0) = day-0 of the next month = last day of `month` (months are 0-indexed in Date ctor)
  const daysInMonth = new Date(year, month, 0).getDate();
  if (day < 1 || day > daysInMonth) {
    throw new AppError(`${field} must be a valid calendar date`, 400, 'VALIDATION_ERROR');
  }
  return value;
}

function validatePosition(value: unknown): number {
  if (value === null || typeof value !== 'number') {
    throw new AppError('position must be a non-negative integer no greater than 100000', 400, 'VALIDATION_ERROR');
  }
  const pos = Number(value);
  if (!Number.isInteger(pos) || pos < 0 || pos > 100_000) {
    throw new AppError('position must be a non-negative integer no greater than 100000', 400, 'VALIDATION_ERROR');
  }
  return pos;
}

// Mounted at /api/v1/projects/:projectId/milestones — requires mergeParams: true
export const projectMilestoneRouter = Router({ mergeParams: true });
projectMilestoneRouter.use(requireAuth);

projectMilestoneRouter.get('/', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    validateUuid(req.params['projectId'] as string, 'projectId');
    const milestones = await listMilestones(req.params['projectId'] as string, req.user!.id);
    res.json({ success: true, data: { milestones } });
  } catch (err) {
    next(err);
  }
});

projectMilestoneRouter.post('/', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    validateUuid(req.params['projectId'] as string, 'projectId');

    const title = validateString(req.body?.title, 'title', 1, 200);

    let due_date: string | null | undefined;
    if (req.body?.due_date !== undefined) {
      due_date = validateDueDate(req.body.due_date, 'due_date');
    }

    let position: number | undefined;
    if (req.body?.position !== undefined) {
      position = validatePosition(req.body.position);
    }

    const milestone = await createMilestone(req.params['projectId'] as string, req.user!.id, {
      title,
      due_date,
      position,
    });
    res.status(201).json({ success: true, data: { milestone } });
  } catch (err) {
    next(err);
  }
});

// Mounted at /api/v1/milestones
// PATCH/DELETE use .in('project_id', projectIds) ownership — no projectId in URL.
// list/create use assertProjectOwnership — projectId known from URL.
export const milestoneRouter = Router();
milestoneRouter.use(requireAuth);

milestoneRouter.patch('/:id', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    validateUuid(req.params['id'] as string, 'id');

    const changes: Parameters<typeof updateMilestone>[2] = {};

    if (req.body?.title !== undefined) {
      changes.title = validateString(req.body.title, 'title', 1, 200);
    }

    if ('due_date' in (req.body ?? {})) {
      changes.due_date = validateDueDate(req.body.due_date, 'due_date');
    }

    if (req.body?.completed !== undefined) {
      if (typeof req.body.completed !== 'boolean') {
        throw new AppError('completed must be a boolean', 400, 'VALIDATION_ERROR');
      }
      changes.completed = req.body.completed;
    }

    if (req.body?.position !== undefined) {
      changes.position = validatePosition(req.body.position);
    }

    // Issue 11: guard against empty payload before hitting the service
    if (Object.keys(changes).length === 0) {
      throw new AppError('No fields to update', 400, 'VALIDATION_ERROR');
    }

    const milestone = await updateMilestone(req.params['id'] as string, req.user!.id, changes);
    res.json({ success: true, data: { milestone } });
  } catch (err) {
    next(err);
  }
});

milestoneRouter.delete('/:id', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    validateUuid(req.params['id'] as string, 'id');
    await deleteMilestone(req.params['id'] as string, req.user!.id);
    res.status(204).send();
  } catch (err) {
    next(err);
  }
});
