import { supabase } from '../config/db';
import { supabaseAdmin } from '../config/adminDb';
import { AppError } from '../middleware/errorHandler';

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
      isClientError ? 'REGISTRATION_ERROR' : 'DB_ERROR',
    );
  }

  const authUserId = authData.user.id;

  const { data: workspace, error: wsError } = await supabaseAdmin
    .from('workspaces')
    .insert({ name: workspaceName })
    .select('id')
    .single();

  if (wsError || !workspace) {
    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(authUserId);
    if (deleteError) {
      console.error('[AUTH] Rollback failed — orphaned auth user:', authUserId, deleteError.message);
    }
    throw new AppError('Registration failed', 500, 'DB_ERROR');
  }

  const { data: user, error: userError } = await supabaseAdmin
    .from('users')
    .insert({ id: authUserId, workspace_id: workspace.id, email, name, role: 'admin' })
    .select('id, email, name, role')
    .single();

  if (userError || !user) {
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
    throw new AppError('Registration failed', 500, 'DB_ERROR');
  }

  return { user, workspaceId: workspace.id };
}

export async function loginUser(email: string, password: string): Promise<LoginResult> {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });

  if (error || !data.session) {
    throw new AppError('Invalid email or password', 401, 'INVALID_CREDENTIALS');
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
    throw new AppError('Account setup incomplete — contact support', 500, 'DB_ERROR');
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
