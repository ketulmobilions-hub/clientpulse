import { Router, Request, Response, NextFunction } from 'express';
import { AppError } from '../middleware/errorHandler';
import { ErrorCodes } from '../errors/codes';
import { requireAuth } from '../middleware/auth.middleware';
import { validateString } from '../utils/validation';
import { getUploadSignedUrl, deleteLogoByUrl } from '../services/storage.service';
import { getWorkspace } from '../services/workspace.service';

const router = Router();

router.use(requireAuth);

// Logos are stored at `${userId}/${timestamp}.${ext}` — used to verify ownership.
const LOGOS_PATH_RE = /\/storage\/v1\/object\/public\/logos\/(.+)$/;

router.post(
  '/signed-url',
  async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        throw new AppError('Authentication required', 401, ErrorCodes.UNAUTHORIZED);
      }

      const fileName = validateString(req.body?.file_name, 'file_name', 1, 255);

      // Only workspace owners may upload logos. getWorkspace queries by owner_id,
      // so members (non-owners) receive a 404 here.
      await getWorkspace(req.user.id);

      const { signedUrl, publicUrl, path } = await getUploadSignedUrl(req.user.id, fileName);
      res.json({ success: true, data: { signedUrl, publicUrl, path } });
    } catch (err) {
      next(err);
    }
  },
);

router.delete(
  '/logo',
  async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        throw new AppError('Authentication required', 401, ErrorCodes.UNAUTHORIZED);
      }

      const logoUrl = validateString(req.body?.logo_url, 'logo_url', 1, 2048);

      // Verify the path belongs to this user before deleting.
      const match = LOGOS_PATH_RE.exec(logoUrl);
      if (match) {
        const storagePath = decodeURIComponent(match[1]);
        if (!storagePath.startsWith(`${req.user.id}/`)) {
          throw new AppError('Cannot delete a logo that does not belong to you', 403, ErrorCodes.FORBIDDEN);
        }
      }

      // Verify workspace ownership (defence in depth).
      await getWorkspace(req.user.id);

      await deleteLogoByUrl(logoUrl);
      res.status(204).send();
    } catch (err) {
      next(err);
    }
  },
);

export default router;
