import { Router } from 'express';
import healthRouter from './health.routes';
import authRouter from './auth.routes';
import workspaceRouter from './workspace.routes';
import projectRouter from './project.routes';
import storageRouter from './storage.routes';
import { projectUpdateRouter, updateRouter } from './update.routes';
import { updateAttachmentRouter, attachmentRouter } from './attachment.routes';
import { projectMilestoneRouter, milestoneRouter } from './milestone.routes';
import { portalRouter } from './portal.routes';
import commentRouter from './comment.routes';
import waitlistRouter from './waitlist.routes';

const router = Router();

router.use('/health', healthRouter);
router.use('/auth', authRouter);
router.use('/workspace', workspaceRouter);
router.use('/projects', projectRouter);
router.use('/projects/:projectId/updates', projectUpdateRouter);
router.use('/updates', updateRouter);
// updateAttachmentRouter matches /updates/:updateId/* — a distinct path prefix from
// /updates (updateRouter). Requests to /updates/:id/attachments/* are matched here
// directly; they never reach updateRouter because /:id in updateRouter only captures
// a single path segment. validateUuid in the handler rejects non-UUID :updateId values.
router.use('/updates/:updateId/comments', commentRouter);
router.use('/updates/:updateId', updateAttachmentRouter);
router.use('/attachments', attachmentRouter);
router.use('/storage', storageRouter);

router.use('/projects/:projectId/milestones', projectMilestoneRouter);
router.use('/milestones', milestoneRouter);

router.use('/portal', portalRouter);

router.use('/waitlist', waitlistRouter);

export default router;
