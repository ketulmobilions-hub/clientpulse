import { Resend } from 'resend';
import { env } from '../config/env';
import { AppError } from '../middleware/errorHandler';

const resend = new Resend(env.resendApiKey);

function escapeHtml(str: string): string {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

export async function sendMagicLinkEmail(
  to: string,
  clientName: string,
  magicLinkUrl: string,
): Promise<void> {
  try {
    const { error } = await resend.emails.send({
      from: env.resendFromEmail,
      to,
      subject: 'Your project update link',
      html: `<p>Hi ${escapeHtml(clientName)},</p><p>Click below to view your project updates:</p><p><a href="${magicLinkUrl}">View Updates</a></p><p>This link expires in 24 hours.</p>`,
    });

    if (error) {
      throw new AppError(`Email delivery failed: ${error.message}`, 502, 'EMAIL_ERROR');
    }
  } catch (err) {
    if (err instanceof AppError) throw err;
    throw new AppError('Email delivery failed', 502, 'EMAIL_ERROR');
  }
}
