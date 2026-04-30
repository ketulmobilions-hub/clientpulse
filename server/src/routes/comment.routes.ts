import { Router, Request, Response, NextFunction } from 'express';
import rateLimit from 'express-rate-limit';
import { AppError } from '../middleware/errorHandler';
import { requireAuth } from '../middleware/auth.middleware';
import { validateString } from '../utils/validation';
import { listComments, createAgencyComment } from '../services/update.service';

// #3: Rate-limit the comment POST to prevent email-notification abuse when Phase 5 lands.
// 20/15 min is looser than the portal's 5/15 min (agency is authenticated + trusted) but
// still prevents burst exhaustion of Resend's free-tier 100 emails/day quota.
const commentRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, error: { code: 'RATE_LIMITED', message: 'Too many comments, please try again later.' } },
});

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function validateUuid(value: string, field: string): void {
  if (!UUID_RE.test(value)) {
    throw new AppError(`${field} must be a valid UUID`, 400, 'VALIDATION_ERROR');
  }
}

// Mounted at /api/v1/updates/:updateId/comments — requires mergeParams: true
const commentRouter = Router({ mergeParams: true });
commentRouter.use(requireAuth);

commentRouter.get('/', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    validateUuid(req.params['updateId'] as string, 'updateId');
    const comments = await listComments(req.user!.id, req.params['updateId'] as string);
    res.json({ success: true, data: { comments } });
  } catch (err) {
    next(err);
  }
});

commentRouter.post('/', commentRateLimit, async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    validateUuid(req.params['updateId'] as string, 'updateId');

    const body = validateString(req.body?.body, 'body', 1, 5000);

    // #9: treat explicit null the same as omitted — mirrors portal.routes.ts behaviour.
    let parent_id: string | undefined;
    if (req.body?.parent_id !== undefined && req.body.parent_id !== null) {
      if (typeof req.body.parent_id !== 'string' || !UUID_RE.test(req.body.parent_id)) {
        throw new AppError('parent_id must be a valid UUID', 400, 'VALIDATION_ERROR');
      }
      parent_id = req.body.parent_id;
    }

    const comment = await createAgencyComment(req.user!.id, req.params['updateId'] as string, {
      body,
      parent_id,
    });
    res.status(201).json({ success: true, data: { comment } });
  } catch (err) {
    next(err);
  }
});

export default commentRouter;
