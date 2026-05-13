import { Router, Request, Response, NextFunction } from 'express';
import { requireAuth } from '../middleware/auth.middleware';
import { AppError } from '../middleware/errorHandler';
import { ErrorCodes } from '../errors/codes';
import { validateString } from '../utils/validation';
import {
  registerUser,
  loginUser,
  generateMagicLink,
  verifyMagicLink,
  verifyEmailToken,
  resendVerification,
} from '../services/auth.service';

const router = Router();

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

router.post('/register', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const email = validateString(req.body?.email, 'email');
    const password = validateString(req.body?.password, 'password', 8, 128);
    const name = validateString(req.body?.name, 'name');
    const workspaceName = validateString(req.body?.workspaceName, 'workspaceName');

    if (!EMAIL_RE.test(email)) {
      throw new AppError('Invalid email address', 400, ErrorCodes.VALIDATION_ERROR);
    }

    const result = await registerUser(email, password, name, workspaceName);
    res.status(201).json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
});

router.post('/login', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const email = validateString(req.body?.email, 'email');
    const password = validateString(req.body?.password, 'password', 8, 128);

    if (!EMAIL_RE.test(email)) {
      throw new AppError('Invalid email address', 400, ErrorCodes.VALIDATION_ERROR);
    }

    const result = await loginUser(email, password);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
});

router.post('/magic-link', requireAuth, async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const projectId = validateString(req.body?.projectId, 'projectId');
    if (!UUID_RE.test(projectId)) {
      throw new AppError('projectId must be a valid UUID', 400, ErrorCodes.VALIDATION_ERROR);
    }
    const email = validateString(req.body?.email, 'email');
    if (!EMAIL_RE.test(email)) {
      throw new AppError('Invalid email address', 400, ErrorCodes.VALIDATION_ERROR);
    }
    const clientName = req.body?.clientName !== undefined
      ? validateString(req.body.clientName, 'clientName', 1, 100)
      : undefined;

    const result = await generateMagicLink(projectId, email, clientName, req.user!.id);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
});

router.get('/magic-link/verify', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const token = req.query['token'];
    if (typeof token !== 'string' || token.trim().length === 0) {
      throw new AppError('token query param is required', 400, ErrorCodes.VALIDATION_ERROR);
    }

    const result = await verifyMagicLink(token.trim());
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
});

router.get('/verify-email', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const token = req.query['token'];
    if (typeof token !== 'string' || token.trim().length === 0) {
      throw new AppError('token query param is required', 400, ErrorCodes.VALIDATION_ERROR);
    }
    const result = await verifyEmailToken(token.trim());
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
});

router.post('/resend-verification', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const email = validateString(req.body?.email, 'email');
    if (!EMAIL_RE.test(email)) {
      throw new AppError('Invalid email address', 400, ErrorCodes.VALIDATION_ERROR);
    }
    const result = await resendVerification(email);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
});

export default router;
