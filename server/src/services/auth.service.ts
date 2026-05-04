import jwt from 'jsonwebtoken';
import { supabase } from '../config/db';
import { supabaseAdmin } from '../config/adminDb';
import { env } from '../config/env';
import { AppError } from '../middleware/errorHandler';
import { ErrorCodes } from '../errors/codes';
import { sendMagicLinkEmail } from './email.service';

export interface RegisterResult {
  user: { id: string; email: string; name: string; role: string };
  workspaceId: string;
}

export interface LoginResult {
  token: string;
  user: { id: string; email: string; name: string; role: string; workspaceId: string };
}

export async function registerUser(
  email: string,
  password: string,
  name: string,
  workspaceName: string,
): Promise<RegisterResult> {
  const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
  });

  if (authError || !authData.user) {
    const isClientError = authError != null && (authError.status ?? 500) < 500;
    throw new AppError(
      'Registration failed',
      isClientError ? 400 : 500,
      isClientError ? ErrorCodes.REGISTRATION_ERROR : ErrorCodes.DB_ERROR,
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

  if (wsError || !workspace) {
    console.error('[AUTH] Workspace insert failed:', wsError?.message);
    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(authUserId);
    if (deleteError) {
      console.error('[AUTH] Rollback failed — orphaned auth user:', authUserId, deleteError.message);
    }
    throw new AppError('Registration failed', 500, ErrorCodes.DB_ERROR);
  }

  const { data: user, error: userError } = await supabaseAdmin
    .from('users')
    .insert({ id: authUserId, workspace_id: workspace.id, email, name, role: 'admin' })
    .select('id, email, name, role')
    .single();

  if (userError || !user) {
    console.error('[AUTH] User insert failed:', userError?.message);
    const { error: wsDeleteError } = await supabaseAdmin
      .from('workspaces')
      .delete()
      .eq('id', workspace.id);
    if (wsDeleteError) {
      console.error('[AUTH] Rollback failed — orphaned workspace:', workspace.id, wsDeleteError.message);
    }
    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(authUserId);
    if (deleteError) {
      console.error('[AUTH] Rollback failed — orphaned auth user:', authUserId, deleteError.message);
    }
    throw new AppError('Registration failed', 500, ErrorCodes.DB_ERROR);
  }

  return { user, workspaceId: workspace.id };
}

export async function loginUser(email: string, password: string): Promise<LoginResult> {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });

  if (error || !data.session) {
    throw new AppError('Invalid email or password', 401, ErrorCodes.INVALID_CREDENTIALS);
  }

  const { data: userRow, error: userError } = await supabaseAdmin
    .from('users')
    .select('id, email, name, role, workspace_id')
    .eq('id', data.user.id)
    .single();

  if (userError || !userRow) {
    const { error: signOutError } = await supabaseAdmin.auth.admin.signOut(data.session.access_token);
    if (signOutError) {
      console.error('[AUTH] Failed to revoke session for user without DB record:', data.user.id, signOutError.message);
    }
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
