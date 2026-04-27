import { Router } from 'express';
import healthRouter from './health.routes';

const router = Router();

router.use('/health', healthRouter);

// Future routes mounted here:
// router.use('/auth', authRouter);
// router.use('/workspace', workspaceRouter);
// router.use('/projects', projectRouter);
// router.use('/updates', updateRouter);
// router.use('/milestones', milestoneRouter);
// router.use('/portal', portalRouter);

export default router;
