import { Router, Request, Response, NextFunction } from 'express';
import { AppError } from '../middleware/errorHandler';
import { ErrorCodes } from '../errors/codes';
import { requireAuth } from '../middleware/auth.middleware';
import { validateString } from '../utils/validation';
import { getWorkspace, createWorkspace, updateWorkspace } from '../services/workspace.service';
import { inviteMember, listMembers, removeMember } from '../services/member.service';
import { deleteLogoByUrl } from '../services/storage.service';

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
          throw new AppError('logo_url must start with https://', 400, ErrorCodes.VALIDATION_ERROR);
        }
        updates.logo_url = url;
      }
    }

    if (Object.keys(updates).length === 0) {
      throw new AppError(
        'At least one field (name, logo_url) is required',
        400,
        ErrorCodes.VALIDATION_ERROR,
      );
    }

    // Capture old logo URL before update so we can clean it up from storage.
    let oldLogoUrl: string | null = null;
    if (updates.logo_url !== undefined) {
      const current = await getWorkspace(req.user!.id);
      oldLogoUrl = current.logo_url ?? null;
    }

    const workspace = await updateWorkspace(req.user!.id, updates);
    res.json({ success: true, data: { workspace } });

    // Non-fatal async cleanup: delete replaced logo from Supabase Storage.
    if (oldLogoUrl && oldLogoUrl !== (updates.logo_url ?? null)) {
      deleteLogoByUrl(oldLogoUrl).catch((err: Error) => {
        console.error('[storage] Failed to delete old logo:', err.message);
      });
    }
  } catch (err) {
    next(err);
  }
});

const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

router.post('/invite', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const email = validateString(req.body?.email, 'email', 1, 254);
    // Fix #9: validate email format
    if (!EMAIL_RE.test(email)) {
      throw new AppError('Invalid email address', 400, ErrorCodes.VALIDATION_ERROR);
    }
    const role = req.body?.role;
    if (role !== 'admin' && role !== 'member') {
      throw new AppError('role must be admin or member', 400, ErrorCodes.VALIDATION_ERROR);
    }
    const member = await inviteMember(req.user!.id, email, role);
    res.status(201).json({ success: true, data: { member } });
  } catch (err) {
    next(err);
  }
});

router.get('/members', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const members = await listMembers(req.user!.id);
    res.json({ success: true, data: { members } });
  } catch (err) {
    next(err);
  }
});

router.delete(
  '/members/:id',
  async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      // Fix #12: lowercase before test so uppercase UUIDs (valid per RFC 4122) are accepted
      const memberId = String(req.params.id).toLowerCase();
      if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/.test(memberId)) {
        throw new AppError('Invalid member id', 400, ErrorCodes.VALIDATION_ERROR);
      }
      await removeMember(req.user!.id, memberId);
      res.status(204).send();
    } catch (err) {
      next(err);
    }
  },
);

export default router;
