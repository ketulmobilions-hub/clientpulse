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

    req.user = { id: data.user.id, email: data.user.email };
    next();
  } catch (err) {
    next(err);
  }
}
