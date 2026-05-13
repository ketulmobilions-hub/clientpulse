import { Router, Request, Response } from 'express';
import { supabaseAdmin } from '../config/adminDb';
import { ErrorCodes } from '../errors/codes';

const router = Router();

router.get('/', async (_req: Request, res: Response) => {
  // No-store guards against intermediate caches; ETag is disabled app-wide
  // in app.ts so res.json() won't trigger conditional 304s on this endpoint.
  res.set('Cache-Control', 'no-store, max-age=0');

  const { error } = await supabaseAdmin
    .from('workspaces')
    .select('count', { count: 'exact', head: true });

  if (error) {
    res.status(503).json({
      success: false,
      error: { code: ErrorCodes.DB_UNAVAILABLE, message: 'Database is not reachable' },
    });
    return;
  }

  res.json({ success: true, message: 'ClientPulse API is running' });
});

export default router;
