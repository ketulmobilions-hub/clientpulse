import { Request, Response, NextFunction } from 'express';
import jwt, { JwtPayload } from 'jsonwebtoken';
import { supabaseAdmin } from '../config/adminDb';
import { env } from '../config/env';
import { AppError } from './errorHandler';

export interface PortalJwtPayload extends JwtPayload {
  type: 'portal';
  projectId: string;
  email?: string;
  clientName?: string;
}

function rejectPortal(res: Response, message: string, statusCode: number, code: string): never {
  res.set('WWW-Authenticate', 'Bearer realm="ClientPulse Portal"');
  throw new AppError(message, statusCode, code);
}

function isPortalPayload(payload: unknown): payload is PortalJwtPayload {
  return (
    typeof payload === 'object' &&
    payload !== null &&
    !Array.isArray(payload) &&
    (payload as Record<string, unknown>)['type'] === 'portal' &&
    typeof (payload as Record<string, unknown>)['projectId'] === 'string' &&
    (payload as Record<string, unknown>)['projectId'] !== ''
  );
}

const SHARE_TOKEN_RE = /^[a-f0-9]{32,128}$/;

export async function requirePortal(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const authHeader = req.headers['authorization'];
    // Bearer header takes priority over cookie; cookie takes priority over share_token.
    // Treat bare "Bearer" (no token) as empty string to trigger INVALID_TOKEN, not UNAUTHORIZED.
    const bearerToken = authHeader
      ? authHeader.startsWith('Bearer ') ? authHeader.slice(7)
        : authHeader === 'Bearer' ? ''
        : undefined
      : undefined;
    const cookieToken = req.signedCookies?.portal_token as string | undefined;
    const shareToken =
      typeof req.query['share_token'] === 'string' ? req.query['share_token'] : undefined;

    const jwtToken = bearerToken !== undefined ? bearerToken : cookieToken;

    if (jwtToken !== undefined) {
      let payload: unknown;
      try {
        payload = jwt.verify(jwtToken, env.jwtSecret, {
          algorithms: ['HS256'],
          maxAge: '7d',
        });
      } catch {
        console.warn('[PORTAL_AUTH] JWT verification failed', {
          requestId: req.id,
          ip: req.ip,
          source: bearerToken !== undefined ? 'bearer' : 'cookie',
        });
        rejectPortal(res, 'Invalid or expired token', 401, 'INVALID_TOKEN');
      }

      if (!isPortalPayload(payload)) {
        console.warn('[PORTAL_AUTH] JWT payload invalid or wrong type', {
          requestId: req.id,
          ip: req.ip,
        });
        rejectPortal(res, 'Invalid token type', 401, 'INVALID_TOKEN');
      }

      req.portal = {
        projectId: payload.projectId,
        ...(payload.email !== undefined && { email: payload.email }),
        ...(payload.clientName !== undefined && { clientName: payload.clientName }),
      };
      next();
      return;
    }

    if (shareToken) {
      if (!SHARE_TOKEN_RE.test(shareToken)) {
        console.warn('[PORTAL_AUTH] share_token failed format check', {
          requestId: req.id,
          ip: req.ip,
        });
        rejectPortal(res, 'Invalid or expired token', 401, 'INVALID_TOKEN');
      }

      const { data: project, error } = await supabaseAdmin
        .from('projects')
        .select('id')
        .eq('share_token', shareToken)
        .is('deleted_at', null)
        .single<{ id: string }>();

      if (error) {
        if (error.code === 'PGRST116') {
          console.warn('[PORTAL_AUTH] share_token not found', {
            requestId: req.id,
            ip: req.ip,
          });
          rejectPortal(res, 'Invalid or expired token', 401, 'INVALID_TOKEN');
        }
        console.error('[PORTAL_AUTH] DB error during share_token lookup', {
          requestId: req.id,
          ip: req.ip,
          code: error.code,
        });
        throw new AppError('Database error', 500, 'DB_ERROR');
      }

      if (!project?.id) {
        rejectPortal(res, 'Invalid or expired token', 401, 'INVALID_TOKEN');
      }

      req.portal = { projectId: project.id };
      next();
      return;
    }

    rejectPortal(res, 'Authentication required', 401, 'UNAUTHORIZED');
  } catch (err) {
    next(err);
  }
}
