import { Router, Request, Response, NextFunction } from 'express';
import { AppError } from '../middleware/errorHandler';
import { requireAuth } from '../middleware/auth.middleware';
import { validateString } from '../utils/validation';
import {
  listProjects,
  getProject,
  createProject,
  updateProject,
  archiveProject,
  VALID_STATUSES,
} from '../services/project.service';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function validateUuid(value: string, field: string): void {
  if (!UUID_RE.test(value)) {
    throw new AppError(`${field} must be a valid UUID`, 400, 'VALIDATION_ERROR');
  }
}

function validateEmail(value: string, field: string): void {
  if (!EMAIL_RE.test(value)) {
    throw new AppError(`${field} must be a valid email address`, 400, 'VALIDATION_ERROR');
  }
}

const router = Router();

router.use(requireAuth);

router.get('/', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const projects = await listProjects(req.user!.id);
    res.json({ success: true, data: { projects } });
  } catch (err) {
    next(err);
  }
});

router.post('/', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const name = validateString(req.body?.name, 'name', 1, 100);
    const client_name = validateString(req.body?.client_name, 'client_name', 1, 100);
    const client_email = validateString(req.body?.client_email, 'client_email', 1, 254);
    validateEmail(client_email, 'client_email');

    const description =
      req.body?.description !== undefined
        ? validateString(req.body.description, 'description', 1, 1000)
        : undefined;

    const project = await createProject(req.user!.id, {
      name,
      description,
      client_name,
      client_email,
    });
    res.status(201).json({ success: true, data: { project } });
  } catch (err) {
    next(err);
  }
});

router.get('/:id', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    validateUuid(req.params['id'] as string, 'id');
    const project = await getProject(req.params['id'] as string, req.user!.id);
    res.json({ success: true, data: { project } });
  } catch (err) {
    next(err);
  }
});

router.patch('/:id', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    validateUuid(req.params['id'] as string, 'id');

    const updates: Parameters<typeof updateProject>[2] = {};

    if (req.body?.name !== undefined) {
      updates.name = validateString(req.body.name, 'name', 1, 100);
    }
    if (req.body?.client_name !== undefined) {
      updates.client_name = validateString(req.body.client_name, 'client_name', 1, 100);
    }
    if (req.body?.client_email !== undefined) {
      const email = validateString(req.body.client_email, 'client_email', 1, 254);
      validateEmail(email, 'client_email');
      updates.client_email = email;
    }
    // 'in' check (not !== undefined) to distinguish "not sent" from "explicitly null/empty"
    if ('description' in (req.body ?? {})) {
      updates.description =
        req.body.description === null
          ? null
          : validateString(req.body.description, 'description', 1, 1000);
    }
    if (req.body?.status !== undefined) {
      if (!(VALID_STATUSES as readonly string[]).includes(req.body.status)) {
        throw new AppError(
          `status must be one of: ${VALID_STATUSES.join(', ')}`,
          400,
          'VALIDATION_ERROR',
        );
      }
      updates.status = req.body.status;
    }

    const project = await updateProject(req.params['id'] as string, req.user!.id, updates);
    res.json({ success: true, data: { project } });
  } catch (err) {
    next(err);
  }
});

// Returns 200 with the archived project. Soft-archive (status change), not hard delete —
// returning the updated resource is more informative than 204 with no body.
router.delete('/:id', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    validateUuid(req.params['id'] as string, 'id');
    const project = await archiveProject(req.params['id'] as string, req.user!.id);
    res.json({ success: true, data: { project } });
  } catch (err) {
    next(err);
  }
});

export default router;
