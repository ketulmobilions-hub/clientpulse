import { supabaseAdmin } from '../config/adminDb';
import { AppError } from '../middleware/errorHandler';
import { ErrorCodes } from '../errors/codes';

export interface WaitlistEntry {
  email: string;
  referrer?: string;
  utmSource?: string;
}

export async function addToWaitlist(entry: WaitlistEntry): Promise<void> {
  const { error } = await supabaseAdmin
    .from('waitlist')
    .insert({
      email: entry.email.toLowerCase(),
      referrer: entry.referrer ?? null,
      utm_source: entry.utmSource ?? null,
    });

  // Duplicate email is silent — return success either way to avoid email enumeration.
  if (error && error.code !== '23505') {
    throw new AppError('Failed to record waitlist entry', 500, ErrorCodes.DB_ERROR);
  }
}
