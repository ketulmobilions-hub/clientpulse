import { Router, Request, Response, NextFunction } from 'express';
import rateLimit from 'express-rate-limit';
import { AppError } from '../middleware/errorHandler';
import { ErrorCodes } from '../errors/codes';
import { validateString } from '../utils/validation';
import { SHARE_TOKEN_RE } from '../utils/token';
import { getPortalOverview, listPortalUpdates, createPortalComment } from '../services/portal.service';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// Async to allow timing normalization in the service; route-level rejection uses a small
// artificial delay to reduce the observable timing difference between format-invalid and
// DB-miss token rejections.
async function validateToken(token: string): Promise<void> {
  if (!SHARE_TOKEN_RE.test(token)) {
    await new Promise((resolve) => setTimeout(resolve, 5 + Math.random() * 10));
    throw new AppError('Invalid or expired token', 401, ErrorCodes.INVALID_TOKEN);
  }
}

function validateUuid(value: string, field: string): void {
  if (!UUID_RE.test(value)) {
    throw new AppError(`${field} must be a valid UUID`, 400, ErrorCodes.VALIDATION_ERROR);
  }
}

function parsePage(raw: unknown): number {
  const n = parseInt(String(raw ?? '1'), 10);
  if (!Number.isFinite(n) || n < 1) {
    throw new AppError('page must be a positive integer', 400, ErrorCodes.VALIDATION_ERROR);
  }
  return n;
}

function parseLimit(raw: unknown): number {
  const n = parseInt(String(raw ?? '20'), 10);
  if (!Number.isFinite(n) || n < 1 || n > 50) {
    throw new AppError('limit must be an integer between 1 and 50', 400, ErrorCodes.VALIDATION_ERROR);
  }
  return n;
}

// Tighter limiter for the comment POST: it creates DB rows and could trigger email notifications
const commentRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, error: { code: ErrorCodes.RATE_LIMITED, message: 'Too many comments, please try again later.' } },
});

export const portalRouter = Router();

portalRouter.get('/:token', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    await validateToken(req.params['token'] as string);
    const overview = await getPortalOverview(req.params['token'] as string);
    res.json({ success: true, data: overview });
  } catch (err) {
    next(err);
  }
});

portalRouter.get('/:token/updates', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    await validateToken(req.params['token'] as string);
    const page = parsePage(req.query['page']);
    const limit = parseLimit(req.query['limit']);
    const result = await listPortalUpdates(req.params['token'] as string, page, limit);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
});

portalRouter.post(
  '/:token/updates/:updateId/comments',
  commentRateLimit,
  async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      await validateToken(req.params['token'] as string);
      validateUuid(req.params['updateId'] as string, 'updateId');

      const author_name = validateString(req.body?.author_name, 'author_name', 1, 100);
      const body = validateString(req.body?.body, 'body', 1, 5000);

      let parent_id: string | undefined;
      if (req.body?.parent_id !== undefined && req.body.parent_id !== null) {
        validateUuid(req.body.parent_id, 'parent_id');
        parent_id = req.body.parent_id as string;
      }

      // Response wraps single resource as data.comment — consistent with all create endpoints
      // (agency getUpdate nests comments as data.comments[] inside the update; that is a different shape
      // for a full-fetch response and is intentional).
      const comment = await createPortalComment(
        req.params['token'] as string,
        req.params['updateId'] as string,
        { author_name, body, parent_id },
      );
      res.status(201).json({ success: true, data: { comment } });
    } catch (err) {
      next(err);
    }
  },
);
