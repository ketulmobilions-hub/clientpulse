import { Router, Request, Response, NextFunction } from 'express';
import { AppError } from '../middleware/errorHandler';
import { ErrorCodes } from '../errors/codes';
import { validateString } from '../utils/validation';
import { addToWaitlist } from '../services/waitlist.service';

const router = Router();

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

router.post('/', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const email = validateString(req.body?.email, 'email', 3, 254);
    if (!EMAIL_RE.test(email)) {
      throw new AppError('Invalid email address', 400, ErrorCodes.VALIDATION_ERROR);
    }

    const referrer = req.body?.referrer !== undefined
      ? validateString(req.body.referrer, 'referrer', 1, 500)
      : undefined;
    const utmSource = req.body?.utmSource !== undefined
      ? validateString(req.body.utmSource, 'utmSource', 1, 100)
      : undefined;

    await addToWaitlist({ email, referrer, utmSource });
    res.status(201).json({ success: true });
  } catch (err) {
    next(err);
  }
});

export default router;
