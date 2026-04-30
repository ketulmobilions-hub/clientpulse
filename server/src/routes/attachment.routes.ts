import { Router, Request, Response, NextFunction } from 'express';
import { AppError } from '../middleware/errorHandler';
import { requireAuth } from '../middleware/auth.middleware';
import { validateString } from '../utils/validation';
import {
  generateAttachmentSignedUrl,
  saveAttachment,
  deleteAttachment,
  MAX_FILE_SIZE_BYTES,
} from '../services/attachment.service';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function validateUuid(value: string, field: string): void {
  if (!UUID_RE.test(value)) {
    throw new AppError(`${field} must be a valid UUID`, 400, 'VALIDATION_ERROR');
  }
}

// Mounted at /api/v1/updates/:updateId — mergeParams exposes :updateId from parent
export const updateAttachmentRouter = Router({ mergeParams: true });
updateAttachmentRouter.use(requireAuth);

updateAttachmentRouter.post(
  '/attachments/signed-url',
  async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const updateId = req.params['updateId'] as string;
      validateUuid(updateId, 'updateId');

      const fileName = validateString(req.body?.file_name, 'file_name', 1, 255);
      const mimeType = validateString(req.body?.mime_type, 'mime_type', 1, 100);

      const result = await generateAttachmentSignedUrl(req.user!.id, updateId, fileName, mimeType);
      res.status(201).json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  },
);

updateAttachmentRouter.post(
  '/attachments',
  async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const updateId = req.params['updateId'] as string;
      validateUuid(updateId, 'updateId');

      const file_url = validateString(req.body?.file_url, 'file_url', 1, 2000);
      const file_name = validateString(req.body?.file_name, 'file_name', 1, 255);
      const file_mime_type = validateString(req.body?.mime_type, 'mime_type', 1, 100);

      const rawSize = req.body?.file_size;
      if (typeof rawSize !== 'number' || !Number.isFinite(rawSize) || rawSize <= 0) {
        throw new AppError('file_size must be a positive number', 400, 'VALIDATION_ERROR');
      }
      if (rawSize > MAX_FILE_SIZE_BYTES) {
        throw new AppError('File exceeds 10 MB limit', 400, 'FILE_TOO_LARGE');
      }
      const file_size = rawSize as number;

      const attachment = await saveAttachment(req.user!.id, updateId, {
        file_url,
        file_name,
        file_size,
        mime_type: file_mime_type,
      });
      res.status(201).json({ success: true, data: { attachment } });
    } catch (err) {
      next(err);
    }
  },
);

// Mounted at /api/v1/attachments
export const attachmentRouter = Router();
attachmentRouter.use(requireAuth);

attachmentRouter.delete(
  '/:id',
  async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      validateUuid(req.params['id'] as string, 'id');
      await deleteAttachment(req.user!.id, req.params['id'] as string);
      res.status(204).send();
    } catch (err) {
      next(err);
    }
  },
);
