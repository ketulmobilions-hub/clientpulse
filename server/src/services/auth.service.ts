import { createHash, randomBytes } from 'crypto';
import jwt from 'jsonwebtoken';
import { supabase } from '../config/db';
import { supabaseAdmin } from '../config/adminDb';
import { env } from '../config/env';
import { AppError } from '../middleware/errorHandler';
import { ErrorCodes } from '../errors/codes';
import { sendMagicLinkEmail, sendVerificationEmail } from './email.service';

const VERIFICATION_TOKEN_TTL_MS = 24 * 60 * 60 * 1000;
// Per-email cooldown so a single user can't trigger arbitrary Resend volume.
// Distinct from the IP-level rate limit on the route. Kept in sync with the
// client-side cooldown copy in verify_email_pending_screen.dart.
export const VERIFICATION_RESEND_COOLDOWN_MS = 60 * 1000;

// Tokens are stored as sha256 hashes — a DB compromise then leaks hashes,
// not live verification links. The raw token only ever exists in the email
// body and the URL the user clicks.
function hashToken(raw: string): string {
  return createHash('sha256').update(raw).digest('hex');
}

export interface RegisterResult {
  user: { id: string; email: string; name: string; role: string };
  workspaceId: string;
  requires_verification: true;
}

export interface LoginResult {
  token: string;
  user: { id: string; email: string; name: string; role: string; workspaceId: string };
}

export interface LoginRequiresVerificationResult {
  requires_verification: true;
  email: string;
}

export type LoginOutcome = LoginResult | LoginRequiresVerificationResult;

export interface VerifyEmailResult {
  verified: true;
  email: string;
}

async function issueVerificationToken(userId: string, email: string, name: string): Promise<void> {
  const rawToken = randomBytes(32).toString('hex');
  const tokenHash = hashToken(rawToken);
  const expiresAt = new Date(Date.now() + VERIFICATION_TOKEN_TTL_MS).toISOString();

  const { error: insertError } = await supabaseAdmin
    .from('verification_tokens')
    .insert({ token: tokenHash, user_id: userId, email, expires_at: expiresAt });

  if (insertError) {
    // 23505 = unique_violation. The migration-012 partial index on user_id
    // WHERE consumed_at IS NULL guarantees only one active token per user.
    // Treat the race as silent success — the prior in-flight request already
    // sent the email, this caller need not retry.
    if (insertError.code === '23505') return;
    throw new AppError('Failed to issue verification token', 500, ErrorCodes.DB_ERROR);
  }

  const verificationUrl = new URL('/verify-email', env.frontendBaseUrl);
  verificationUrl.searchParams.set('token', rawToken);
  await sendVerificationEmail(email, name, verificationUrl.toString());
}

export async function registerUser(
  email: string,
  password: string,
  name: string,
  workspaceName: string,
): Promise<RegisterResult> {
  // email_confirm: false — caller must verify via the link emailed below.
  // Login + auth middleware enforce the gate.
  const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
    email,
    password,
    email_confirm: false,
  });

  if (authError || !authData.user) {
    const code = authError?.code;
    const rawMessage = typeof authError?.message === 'string' ? authError.message : '';
    const dupByCode = code === 'email_exists' || code === 'user_already_exists';
    // Message-based fallback: covers self-hosted/proxy variants that strip `code`.
    // Anchored regex avoids matching unrelated 4xx like "workspace name already
    // exists" that would otherwise misroute users to the duplicate-email UX.
    const dupByMessage =
      !code &&
      /\b(email|user)\b.*\balready\s+(been\s+)?(registered|exists)\b/i.test(rawMessage);
    if (dupByCode || dupByMessage) {
      throw new AppError(
        'An account with this email already exists',
        409,
        ErrorCodes.EMAIL_EXISTS,
      );
    }
    const isClientError = authError != null && (authError.status ?? 500) < 500;
    throw new AppError(
      isClientError ? rawMessage || 'Registration failed' : 'Registration failed',
      isClientError ? 400 : 500,
      // 5xx here is upstream auth/network, not DB — INTERNAL_ERROR keeps DB_ERROR
      // as a query-level signal so dashboards/triage point at the right system.
      isClientError ? ErrorCodes.REGISTRATION_ERROR : ErrorCodes.INTERNAL_ERROR,
    );
  }

  const authUserId = authData.user.id;

  const slug = workspaceName
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 63);

  const { data: workspace, error: wsError } = await supabaseAdmin
    .from('workspaces')
    .insert({ name: workspaceName, slug, owner_id: authUserId })
    .select('id')
    .single();

  // Rollback strategy: deleting the auth user cascades to workspaces.owner_id
  // and users.id (both ON DELETE CASCADE in migrations 001 + 003). One delete
  // call replaces the prior multi-step explicit cleanup, eliminating the
  // partial-failure orphan windows the previous code admitted to via console.error.
  async function rollbackAuthUser(reason: string): Promise<void> {
    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(authUserId);
    if (deleteError) {
      console.error(`[AUTH] Rollback failed (${reason}) — orphaned auth user:`, authUserId, deleteError.message);
    }
  }

  if (wsError || !workspace) {
    console.error('[AUTH] Workspace insert failed:', wsError?.message);
    await rollbackAuthUser('workspace_insert');
    throw new AppError('Registration failed', 500, ErrorCodes.DB_ERROR);
  }

  const { data: user, error: userError } = await supabaseAdmin
    .from('users')
    .insert({ id: authUserId, workspace_id: workspace.id, email, name, role: 'admin' })
    .select('id, email, name, role')
    .single();

  if (userError || !user) {
    console.error('[AUTH] User insert failed:', userError?.message);
    await rollbackAuthUser('user_insert');
    throw new AppError('Registration failed', 500, ErrorCodes.DB_ERROR);
  }

  // Issue verification token + send email. If this fails, roll back the entire
  // registration so the user can retry cleanly. Without rollback, the user exists
  // unverified with no email sent and no obvious recovery path.
  try {
    await issueVerificationToken(authUserId, email, name);
  } catch (verificationError) {
    console.error('[AUTH] Verification email failed during registration:', verificationError);
    await rollbackAuthUser('verification_email');
    throw verificationError instanceof AppError
      ? verificationError
      : new AppError('Registration failed', 500, ErrorCodes.INTERNAL_ERROR);
  }

  return { user, workspaceId: workspace.id, requires_verification: true };
}

export async function loginUser(email: string, password: string): Promise<LoginOutcome> {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });

  if (error || !data.session) {
    // Supabase's "Confirm email" dashboard setting causes signInWithPassword to
    // reject unverified users with `email_not_confirmed` (no session issued).
    // Surface that as requires_verification so the UI can route to verify-pending
    // instead of showing a misleading "Invalid email or password" banner.
    // Anchored regex avoids matching unrelated errors that happen to contain the
    // phrase ("MFA enrollment requires email confirmed first" etc.).
    const code = error?.code;
    const msg = typeof error?.message === 'string' ? error.message.trim() : '';
    if (code === 'email_not_confirmed' || /^email not confirmed\.?$/i.test(msg)) {
      return { requires_verification: true, email };
    }
    throw new AppError('Invalid email or password', 401, ErrorCodes.INVALID_CREDENTIALS);
  }

  // Defense-in-depth: even when "Confirm email" is OFF in the dashboard,
  // a session may be issued for an unconfirmed user. Our own gate. We do NOT
  // call supabase.auth.admin.signOut here — it only revokes the *refresh*
  // token, not the access token we just received. The mitigation is simpler:
  // never expose the access token in the response. Frontend never sees it,
  // so there is nothing to leak.
  if (!data.user.email_confirmed_at) {
    return { requires_verification: true, email: data.user.email ?? email };
  }

  const { data: userRow, error: userError } = await supabaseAdmin
    .from('users')
    .select('id, email, name, role, workspace_id')
    .eq('id', data.user.id)
    .single();

  if (userError || !userRow) {
    // Same reasoning as above — don't pretend signOut revokes the access token.
    // The token we hold expires per Supabase's session config (default 1h).
    // Caller never gets the token, so there's nothing the user can do with it.
    throw new AppError('Account setup incomplete — contact support', 500, ErrorCodes.DB_ERROR);
  }

  return {
    token: data.session.access_token,
    user: {
      id: userRow.id,
      email: userRow.email,
      name: userRow.name,
      role: userRow.role,
      workspaceId: userRow.workspace_id,
    },
  };
}

export async function verifyEmailToken(token: string): Promise<VerifyEmailResult> {
  // Hash before lookup — DB stores sha256(token), URL carries raw token.
  const tokenHash = hashToken(token);

  // SELECT first (no mutation) so we know the user_id to confirm. Must guard
  // against expired / consumed here so re-clicks on a stale link still surface
  // the right "already verified" path below.
  const { data: row, error } = await supabaseAdmin
    .from('verification_tokens')
    .select('user_id, email, consumed_at, expires_at')
    .eq('token', tokenHash)
    .maybeSingle();

  if (error) {
    console.error('[AUTH] verifyEmailToken DB error:', error);
    throw new AppError('Database error', 500, ErrorCodes.DB_ERROR);
  }

  if (!row) {
    throw new AppError('Verification link is invalid or expired', 400, ErrorCodes.INVALID_TOKEN);
  }

  // Re-clicks on a verified link return success idempotently. The user is
  // already confirmed; no need to call the auth admin API again.
  if (row.consumed_at) {
    return { verified: true, email: row.email };
  }

  if (new Date(row.expires_at).getTime() <= Date.now()) {
    throw new AppError('Verification link is invalid or expired', 400, ErrorCodes.INVALID_TOKEN);
  }

  // CONFIRM FIRST, then mark consumed. Earlier (consume-then-confirm) ordering
  // could lock users out: if updateUserById failed, the token row was already
  // consumed and any retry hit the "already consumed" branch above without ever
  // flipping email_confirm. Since email_confirm:true is idempotent on
  // already-confirmed users, doing it before the consume is safe even on retry.
  const { error: confirmError } = await supabaseAdmin.auth.admin.updateUserById(row.user_id, {
    email_confirm: true,
  });

  if (confirmError) {
    console.error('[AUTH] updateUserById email_confirm failed:', confirmError.message);
    throw new AppError('Failed to verify email', 500, ErrorCodes.INTERNAL_ERROR);
  }

  // Atomic single-use: only the writer that flips consumed_at from NULL wins.
  // A second concurrent verify-click loses the UPDATE race but the user is
  // already confirmed by the call above, so it doesn't matter.
  const { error: consumeError } = await supabaseAdmin
    .from('verification_tokens')
    .update({ consumed_at: new Date().toISOString() })
    .eq('token', tokenHash)
    .is('consumed_at', null);

  if (consumeError) {
    console.error('[AUTH] verifyEmailToken consume update error:', consumeError.message);
    // Best-effort — user is already confirmed, so don't fail the request. The
    // unconsumed token will simply expire on its own.
  }

  return { verified: true, email: row.email };
}

export async function resendVerification(email: string): Promise<{ sent: true }> {
  // Always return { sent: true } from this function. Any internal branch that
  // skips the actual send (missing user, already verified, cooldown) returns
  // the same success shape. The endpoint MUST NOT be a positive existence
  // oracle — the IP rate limit on /auth/* is the only public-facing throttle.
  const normalizedEmail = email.toLowerCase().trim();

  // Direct auth.users lookup via service role + auth schema. Avoids the
  // listUsers() pagination bug (default 50 per page misses real users past
  // page 1) and the visible timing leak from a full-table scan.
  const { data: authUser, error: lookupError } = await supabaseAdmin
    .schema('auth')
    .from('users')
    .select('id, email_confirmed_at')
    .ilike('email', normalizedEmail)
    .maybeSingle();

  if (lookupError) {
    // Real DB error — log and bail with success so callers can't infer.
    console.error('[AUTH] resendVerification auth.users lookup error:', lookupError.message);
    return { sent: true };
  }

  if (!authUser || authUser.email_confirmed_at) {
    return { sent: true };
  }

  // Per-email cooldown (60s). Enforced silently — no 429 response, no error
  // shape leak. Either we send or we don't, both look identical to the caller.
  const { data: latest } = await supabaseAdmin
    .from('verification_tokens')
    .select('created_at')
    .eq('user_id', authUser.id)
    .is('consumed_at', null)
    .order('created_at', { ascending: false })
    .limit(1)
    .maybeSingle();

  if (latest) {
    const ageMs = Date.now() - new Date(latest.created_at).getTime();
    if (ageMs < VERIFICATION_RESEND_COOLDOWN_MS) {
      return { sent: true };
    }
  }

  // Invalidate any prior unconsumed tokens so an old email becomes inert.
  await supabaseAdmin
    .from('verification_tokens')
    .update({ consumed_at: new Date().toISOString() })
    .eq('user_id', authUser.id)
    .is('consumed_at', null);

  // Look up the user's display name for the greeting; fall back to "there".
  const { data: userRow } = await supabaseAdmin
    .from('users')
    .select('name')
    .eq('id', authUser.id)
    .maybeSingle();

  try {
    await issueVerificationToken(authUser.id, email, userRow?.name ?? 'there');
  } catch (err) {
    // Email service failure must not surface to the caller — that would itself
    // be a positive-existence oracle ("if Resend errors, the email exists").
    console.error('[AUTH] resendVerification issue token error:', err);
  }

  return { sent: true };
}

export interface MagicLinkResult {
  sent: true;
}

export interface PortalTokenResult {
  token: string;
}

export async function generateMagicLink(
  projectId: string,
  email: string,
  clientName: string | undefined,
  userId: string,
): Promise<MagicLinkResult> {
  const { data: project, error: projectError } = await supabaseAdmin
    .from('projects')
    .select('id, workspace_id')
    .eq('id', projectId)
    .is('deleted_at', null)
    .single();

  if (projectError || !project) {
    throw new AppError('Project not found', 404, ErrorCodes.NOT_FOUND);
  }

  const { data: workspace, error: wsError } = await supabaseAdmin
    .from('workspaces')
    .select('id')
    .eq('id', project.workspace_id)
    .eq('owner_id', userId)
    .is('deleted_at', null)
    .single();

  if (wsError || !workspace) {
    throw new AppError('Access denied', 403, ErrorCodes.FORBIDDEN);
  }

  const { data: link, error: insertError } = await supabaseAdmin
    .from('magic_links')
    .insert({ project_id: projectId, email, client_name: clientName ?? null })
    .select('id, token')
    .single();

  if (insertError || !link) {
    throw new AppError('Failed to generate magic link', 500, ErrorCodes.DB_ERROR);
  }

  const magicLinkUrl = `${env.appBaseUrl}/p/verify?token=${encodeURIComponent(link.token)}`;

  await sendMagicLinkEmail(email, clientName ?? 'there', magicLinkUrl);

  const { error: sentAtError } = await supabaseAdmin
    .from('magic_links')
    .update({ email_sent_at: new Date().toISOString() })
    .eq('id', link.id);

  if (sentAtError) {
    console.error('[MAGIC_LINK] email_sent_at update failed for link', link.id, sentAtError.message);
  }

  return { sent: true };
}

export async function verifyMagicLink(token: string): Promise<PortalTokenResult> {
  const { data: link, error } = await supabaseAdmin
    .from('magic_links')
    .update({ used_at: new Date().toISOString() })
    .eq('token', token)
    .is('used_at', null)
    .gt('expires_at', new Date().toISOString())
    .select('id, project_id, email, client_name')
    .single();

  if (error) {
    if (error.code === 'PGRST116') {
      throw new AppError('Invalid or expired magic link', 401, ErrorCodes.INVALID_TOKEN);
    }
    throw new AppError('Database error', 500, ErrorCodes.DB_ERROR);
  }

  if (!link) {
    throw new AppError('Invalid or expired magic link', 401, ErrorCodes.INVALID_TOKEN);
  }

  const portalToken = jwt.sign(
    {
      type: 'portal',
      projectId: link.project_id,
      email: link.email,
      clientName: link.client_name ?? undefined,
    },
    env.jwtSecret,
    { expiresIn: '7d' },
  );

  return { token: portalToken };
}
