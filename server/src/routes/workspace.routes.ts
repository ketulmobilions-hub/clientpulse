import { Router, Request, Response, NextFunction } from 'express';
import { AppError } from '../middleware/errorHandler';
import { requireAuth } from '../middleware/auth.middleware';
import { validateString } from '../utils/validation';
import { getWorkspace, createWorkspace, updateWorkspace } from '../services/workspace.service';

const router = Router();

router.use(requireAuth);

router.get('/', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const workspace = await getWorkspace(req.user!.id);
    res.json({ success: true, data: { workspace } });
  } catch (err) {
    next(err);
  }
});

router.post('/', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const name = validateString(req.body?.name, 'name', 1, 100);
    const workspace = await createWorkspace(req.user!.id, name);
    res.status(201).json({ success: true, data: { workspace } });
  } catch (err) {
    next(err);
  }
});

router.patch('/', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const updates: { name?: string; logo_url?: string | null } = {};

    if (req.body?.name !== undefined) {
      updates.name = validateString(req.body.name, 'name', 1, 100);
    }

    if (req.body?.logo_url !== undefined) {
      if (req.body.logo_url === null) {
        updates.logo_url = null;
      } else {
        const url = validateString(req.body.logo_url, 'logo_url', 1, 2048);
        if (!/^https:\/\//.test(url)) {
          throw new AppError('logo_url must start with https://', 400, 'VALIDATION_ERROR');
        }
        updates.logo_url = url;
      }
    }

    if (Object.keys(updates).length === 0) {
      throw new AppError(
        'At least one field (name, logo_url) is required',
        400,
        'VALIDATION_ERROR',
      );
    }

    const workspace = await updateWorkspace(req.user!.id, updates);
    res.json({ success: true, data: { workspace } });
  } catch (err) {
    next(err);
  }
});

export default router;
