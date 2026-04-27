import { Router, Request, Response, NextFunction } from 'express';
import { AppError } from '../middleware/errorHandler';
import { registerUser, loginUser } from '../services/auth.service';

const router = Router();

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function validateString(value: unknown, field: string, min = 1, max = 100): string {
  if (typeof value !== 'string') {
    throw new AppError(`${field} must be a string`, 400, 'VALIDATION_ERROR');
  }
  const trimmed = value.trim();
  if (trimmed.length < min) {
    throw new AppError(`${field} is required`, 400, 'VALIDATION_ERROR');
  }
  if (trimmed.length > max) {
    throw new AppError(`${field} must be at most ${max} characters`, 400, 'VALIDATION_ERROR');
  }
  return trimmed;
}

router.post('/register', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const email = validateString(req.body?.email, 'email');
    const password = validateString(req.body?.password, 'password', 8, 128);
    const name = validateString(req.body?.name, 'name');
    const workspaceName = validateString(req.body?.workspaceName, 'workspaceName');

    if (!EMAIL_RE.test(email)) {
      throw new AppError('Invalid email address', 400, 'VALIDATION_ERROR');
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
      throw new AppError('Invalid email address', 400, 'VALIDATION_ERROR');
    }

    const result = await loginUser(email, password);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
});

export default router;
