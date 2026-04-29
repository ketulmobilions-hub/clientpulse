import { Router } from 'express';
import healthRouter from './health.routes';
import authRouter from './auth.routes';
import workspaceRouter from './workspace.routes';
import projectRouter from './project.routes';
import storageRouter from './storage.routes';
import { projectUpdateRouter, updateRouter } from './update.routes';

const router = Router();

router.use('/health', healthRouter);
router.use('/auth', authRouter);
router.use('/workspace', workspaceRouter);
router.use('/projects', projectRouter);
router.use('/projects/:projectId/updates', projectUpdateRouter);
router.use('/updates', updateRouter);
router.use('/storage', storageRouter);

// Future routes mounted here:
// router.use('/milestones', milestoneRouter);
// router.use('/portal', portalRouter);

export default router;
