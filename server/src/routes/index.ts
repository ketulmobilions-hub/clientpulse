import { Router } from 'express';
import healthRouter from './health.routes';
import authRouter from './auth.routes';

const router = Router();

router.use('/health', healthRouter);
router.use('/auth', authRouter);

// Future routes mounted here:
// router.use('/workspace', workspaceRouter);
// router.use('/projects', projectRouter);
// router.use('/updates', updateRouter);
// router.use('/milestones', milestoneRouter);
// router.use('/portal', portalRouter);

export default router;
