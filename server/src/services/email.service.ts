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

export async function sendInviteEmail(
  to: string,
  workspaceName: string,
  inviteUrl: string,
): Promise<void> {
  if (!/^https:\/\//.test(inviteUrl)) {
    throw new AppError('Invalid invite URL', 500, 'INTERNAL_ERROR');
  }

  try {
    const { error } = await resend.emails.send({
      from: env.resendFromEmail,
      to,
      subject: `You've been invited to ${escapeHtml(workspaceName)} on ClientPulse`,
      html: `<p>You've been invited to join <strong>${escapeHtml(workspaceName)}</strong> on ClientPulse.</p><p><a href="${escapeHtml(inviteUrl)}">Accept Invitation</a></p><p>This link expires in 7 days.</p>`,
    });

    if (error) {
      throw new AppError(`Email delivery failed: ${error.message}`, 502, 'EMAIL_ERROR');
    }
  } catch (err) {
    if (err instanceof AppError) throw err;
    throw new AppError('Email delivery failed', 502, 'EMAIL_ERROR');
  }
}

const CATEGORY_LABELS: Record<string, string> = {
  progress: 'Progress Update',
  milestone: 'Milestone Reached',
  deliverable: 'Deliverable Shared',
  blocker: 'Blocker',
  input_needed: 'Input Needed',
};

export async function sendUpdateNotificationEmail(
  to: string,
  clientName: string,
  projectName: string,
  updateTitle: string,
  category: string,
  bodyExcerpt: string,
  portalUrl: string,
): Promise<void> {
  const allowLocalhost = env.nodeEnv !== 'production';
  const validUrl = /^https:\/\//.test(portalUrl) || (allowLocalhost && /^http:\/\/localhost/.test(portalUrl));
  if (!validUrl) {
    throw new AppError('Invalid portal URL', 500, 'INTERNAL_ERROR');
  }

  const categoryLabel = CATEGORY_LABELS[category];
  if (!categoryLabel) {
    console.warn(`[email.service] sendUpdateNotificationEmail: unknown category "${category}"`);
  }
  const displayCategory = categoryLabel ?? 'Update';

  try {
    const { error } = await resend.emails.send({
      from: env.resendFromEmail,
      to,
      subject: `New update on ${escapeHtml(projectName)}: ${escapeHtml(updateTitle)}`,
      html: [
        `<p>Hi ${escapeHtml(clientName)},</p>`,
        `<p>There's a new update on your project <strong>${escapeHtml(projectName)}</strong>.</p>`,
        `<p><span style="background:#e0f2fe;color:#0369a1;padding:2px 8px;border-radius:4px;font-size:12px;font-weight:600;">${escapeHtml(displayCategory)}</span></p>`,
        `<h2 style="margin:16px 0 8px;font-size:18px;">${escapeHtml(updateTitle)}</h2>`,
        `<p style="color:#374151;">${escapeHtml(bodyExcerpt)}</p>`,
        `<p style="margin-top:24px;"><a href="${escapeHtml(portalUrl)}" style="background:#0ea5e9;color:#fff;padding:10px 20px;border-radius:6px;text-decoration:none;font-weight:600;">View Update</a></p>`,
      ].join(''),
    });

    if (error) {
      throw new AppError(`Email delivery failed: ${error.message}`, 502, 'EMAIL_ERROR');
    }
  } catch (err) {
    if (err instanceof AppError) throw err;
    throw new AppError('Email delivery failed', 502, 'EMAIL_ERROR');
  }
}

export async function sendMagicLinkEmail(
  to: string,
  clientName: string,
  magicLinkUrl: string,
): Promise<void> {
  if (!/^https:\/\//.test(magicLinkUrl)) {
    throw new AppError('Invalid magic link URL', 500, 'INTERNAL_ERROR');
  }

  try {
    const { error } = await resend.emails.send({
      from: env.resendFromEmail,
      to,
      subject: 'Your project update link',
      html: `<p>Hi ${escapeHtml(clientName)},</p><p>Click below to view your project updates:</p><p><a href="${escapeHtml(magicLinkUrl)}">View Updates</a></p><p>This link expires in 24 hours.</p>`,
    });

    if (error) {
      throw new AppError(`Email delivery failed: ${error.message}`, 502, 'EMAIL_ERROR');
    }
  } catch (err) {
    if (err instanceof AppError) throw err;
    throw new AppError('Email delivery failed', 502, 'EMAIL_ERROR');
  }
}
