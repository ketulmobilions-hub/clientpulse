import { Request, Response, NextFunction } from 'express';
import { supabase } from '../config/db';
import { AppError } from './errorHandler';
import { ErrorCodes } from '../errors/codes';

export async function requireAuth(req: Request, _res: Response, next: NextFunction): Promise<void> {
  try {
    const authHeader = req.headers['authorization'];
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new AppError('Authentication required', 401, ErrorCodes.UNAUTHORIZED);
    }

    const token = authHeader.slice(7);
    const { data, error } = await supabase.auth.getUser(token);

    if (error || !data.user || !data.user.email) {
      throw new AppError('Invalid or expired token', 401, ErrorCodes.UNAUTHORIZED);
    }

    // Defense-in-depth: login already returns requires_verification before
    // issuing a JWT, so this branch is unreachable in the normal flow. It
    // catches stale tokens minted before email verification was enabled or
    // for accounts whose email_confirmed_at was administratively cleared.
    // Treat undefined and null identically — Supabase has been known to omit
    // the field rather than return null on some auth responses.
    if (data.user.email_confirmed_at == null) {
      throw new AppError(
        'Please verify your email before continuing',
        403,
        ErrorCodes.EMAIL_NOT_VERIFIED,
      );
    }

    req.user = { id: data.user.id, email: data.user.email };
    next();
  } catch (err) {
    next(err);
  }
}
