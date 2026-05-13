import { Router, Request, Response, NextFunction } from 'express';
import { AppError } from '../middleware/errorHandler';
import { ErrorCodes } from '../errors/codes';
import { requireAuth } from '../middleware/auth.middleware';
import { validateString } from '../utils/validation';
import {
  listProjects,
  getProject,
  createProject,
  updateProject,
  archiveProject,
  unarchiveProject,
  deleteProject,
  VALID_STATUSES,
} from '../services/project.service';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

function validateDate(value: unknown, field: string): string {
  if (typeof value !== 'string' || !DATE_RE.test(value)) {
    throw new AppError(`${field} must be a date in YYYY-MM-DD format`, 400, ErrorCodes.VALIDATION_ERROR);
  }
  // Guard against calendar-invalid dates like Feb 30 or month 13.
  // Append T00:00:00Z to force UTC parse, then verify the ISO string round-trips.
  const parsed = new Date(`${value}T00:00:00Z`);
  if (isNaN(parsed.getTime()) || parsed.toISOString().slice(0, 10) !== value) {
    throw new AppError(`${field} is not a valid calendar date`, 400, ErrorCodes.VALIDATION_ERROR);
  }
  return value;
}

function validateDateOrdering(start: string | undefined | null, end: string | undefined | null): void {
  if (start && end && end < start) {
    throw new AppError('expected_end_date must be on or after start_date', 400, ErrorCodes.VALIDATION_ERROR);
  }
}

function validateUuid(value: string, field: string): void {
  if (!UUID_RE.test(value)) {
    throw new AppError(`${field} must be a valid UUID`, 400, ErrorCodes.VALIDATION_ERROR);
  }
}

function validateEmail(value: string, field: string): void {
  if (!EMAIL_RE.test(value)) {
    throw new AppError(`${field} must be a valid email address`, 400, ErrorCodes.VALIDATION_ERROR);
  }
}

const router = Router();

router.use(requireAuth);

router.get('/', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const raw = req.query['include_archived'];
    // Accept only the strings 'true' / 'false' / undefined. Anything else is a client bug.
    let includeArchived = false;
    if (raw !== undefined) {
      if (raw === 'true') includeArchived = true;
      else if (raw === 'false') includeArchived = false;
      else {
        throw new AppError(
          'include_archived must be "true" or "false"',
          400,
          ErrorCodes.VALIDATION_ERROR,
        );
      }
    }
    const projects = await listProjects(req.user!.id, { includeArchived });
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
      req.body?.description !== undefined && req.body.description !== null
        ? validateString(req.body.description, 'description', 1, 1000)
        : undefined;

    const start_date =
      req.body?.start_date !== undefined ? validateDate(req.body.start_date, 'start_date') : undefined;
    const expected_end_date =
      req.body?.expected_end_date !== undefined
        ? validateDate(req.body.expected_end_date, 'expected_end_date')
        : undefined;

    validateDateOrdering(start_date, expected_end_date);

    const project = await createProject(req.user!.id, {
      name,
      description,
      client_name,
      client_email,
      start_date,
      expected_end_date,
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
          ErrorCodes.VALIDATION_ERROR,
        );
      }
      updates.status = req.body.status;
    }
    if ('start_date' in (req.body ?? {})) {
      updates.start_date =
        req.body.start_date === null ? null : validateDate(req.body.start_date, 'start_date');
    }
    if ('expected_end_date' in (req.body ?? {})) {
      updates.expected_end_date =
        req.body.expected_end_date === null
          ? null
          : validateDate(req.body.expected_end_date, 'expected_end_date');
    }

    validateDateOrdering(
      'start_date' in updates ? updates.start_date ?? undefined : undefined,
      'expected_end_date' in updates ? updates.expected_end_date ?? undefined : undefined,
    );

    const project = await updateProject(req.params['id'] as string, req.user!.id, updates);
    res.json({ success: true, data: { project } });
  } catch (err) {
    next(err);
  }
});

// Soft-delete via deleted_at. Hides project from every read path (list/detail/portal).
// Recoverable from DB only — UI offers no restore. Returns 200 with the deleted project
// so the client can confirm what was removed.
//
// API SEMANTIC CHANGE (2026-05-12): this verb previously soft-archived
// (status='archived'). Archive now lives at POST /:id/archive. Pinned client
// builds that called DELETE expecting archive will SOFT-DELETE instead. The
// User-Agent header is logged so QA can spot a stale client during launch
// week. Remove the warning once analytics confirm no legacy traffic.
router.delete('/:id', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    validateUuid(req.params['id'] as string, 'id');
    const ua = req.get('user-agent') ?? 'unknown';
    console.warn('[project.routes] DELETE /:id soft-deletes (was archive) ua=%s id=%s', ua, req.params['id']);
    const project = await deleteProject(req.params['id'] as string, req.user!.id);
    res.json({ success: true, data: { project } });
  } catch (err) {
    next(err);
  }
});

// Soft-archive (status='archived'). Hidden from default list, portal still accessible,
// reversible via /unarchive.
router.post('/:id/archive', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    validateUuid(req.params['id'] as string, 'id');
    const project = await archiveProject(req.params['id'] as string, req.user!.id);
    res.json({ success: true, data: { project } });
  } catch (err) {
    next(err);
  }
});

router.post('/:id/unarchive', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    validateUuid(req.params['id'] as string, 'id');
    const project = await unarchiveProject(req.params['id'] as string, req.user!.id);
    res.json({ success: true, data: { project } });
  } catch (err) {
    next(err);
  }
});

export default router;
