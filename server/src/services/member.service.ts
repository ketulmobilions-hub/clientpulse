import { supabaseAdmin } from '../config/adminDb';
import { AppError } from '../middleware/errorHandler';
import { ErrorCodes } from '../errors/codes';
import { env } from '../config/env';
import { sendInviteEmail } from './email.service';

export interface Member {
  id: string;
  email: string;
  name: string;
  role: 'admin' | 'member';
  invited_at: string | null;
  created_at: string;
}

const MEMBER_COLUMNS = 'id, email, name, role, invited_at, created_at';

// Fix #9: return union type so callers get TS exhaustiveness on role checks
async function getCallerContext(
  userId: string,
): Promise<{ workspaceId: string; role: 'admin' | 'member' }> {
  const { data, error } = await supabaseAdmin
    .from('users')
    .select('workspace_id, role')
    .eq('id', userId)
    .is('deleted_at', null)
    .single();

  if (error?.code === 'PGRST116' || !data) {
    throw new AppError('User not found', 404, ErrorCodes.NOT_FOUND);
  }
  if (error) {
    throw new AppError('Database error', 500, ErrorCodes.DB_ERROR);
  }

  return { workspaceId: data.workspace_id, role: data.role as 'admin' | 'member' };
}

export async function inviteMember(
  userId: string,
  email: string,
  role: 'admin' | 'member',
): Promise<Member> {
  const { workspaceId, role: callerRole } = await getCallerContext(userId);

  if (callerRole !== 'admin') {
    throw new AppError('Only admins can invite members', 403, ErrorCodes.FORBIDDEN);
  }

  // Fix #5: normalize email case before all DB and auth operations
  const normalizedEmail = email.toLowerCase();

  const { data: existing, error: existingError } = await supabaseAdmin
    .from('users')
    .select('id, deleted_at')
    .eq('workspace_id', workspaceId)
    .eq('email', normalizedEmail)
    .maybeSingle();

  if (existingError) {
    throw new AppError('Database error', 500, ErrorCodes.DB_ERROR);
  }

  if (existing && !existing.deleted_at) {
    throw new AppError('Member already in workspace', 409, ErrorCodes.CONFLICT);
  }

  // Fix #6 + #2 + #3: purge soft-deleted row upfront so the fresh-invite path
  // always uses linkData.user.id — eliminates the id-mismatch problem entirely
  // and collapses the two invite paths into one.
  if (existing) {
    const { error: purgeError } = await supabaseAdmin
      .from('users')
      .delete()
      .eq('id', existing.id);

    if (purgeError) {
      throw new AppError('Failed to reinvite member', 500, ErrorCodes.DB_ERROR);
    }
  }

  // Fetch workspace name before generateLink so any failure here cannot orphan an auth user
  const { data: workspace, error: wsError } = await supabaseAdmin
    .from('workspaces')
    .select('name')
    .eq('id', workspaceId)
    .single();

  if (wsError || !workspace) {
    throw new AppError('Workspace not found', 404, ErrorCodes.NOT_FOUND);
  }

  const { data: linkData, error: linkError } = await supabaseAdmin.auth.admin.generateLink({
    type: 'invite',
    email: normalizedEmail,
    options: { redirectTo: env.appBaseUrl },
  });

  if (linkError || !linkData?.user) {
    throw new AppError('Failed to generate invite link', 500, ErrorCodes.DB_ERROR);
  }

  const { data: member, error: insertError } = await supabaseAdmin
    .from('users')
    .insert({
      id: linkData.user.id,
      workspace_id: workspaceId,
      email: normalizedEmail,
      role,
      invited_at: new Date().toISOString(),
    })
    .select(MEMBER_COLUMNS)
    .single();

  if (insertError || !member) {
    // Fix #4: deleteUser triggers ON DELETE CASCADE on the users row — one call handles both
    try {
      await supabaseAdmin.auth.admin.deleteUser(linkData.user.id);
    } catch (rollbackErr) {
      console.error('[INVITE] Auth user rollback failed:', linkData.user.id, rollbackErr);
    }
    if (insertError?.code === '23505') {
      throw new AppError('Member already in workspace', 409, ErrorCodes.CONFLICT);
    }
    throw new AppError('Failed to add member', 500, ErrorCodes.DB_ERROR);
  }

  try {
    await sendInviteEmail(normalizedEmail, workspace.name, linkData.properties.action_link);
  } catch (emailErr) {
    // Fix #8: INTERNAL_ERROR means a config/code defect (e.g. bad URL) — don't roll back the
    // DB write, let the real error propagate so operators can diagnose the config problem.
    if (emailErr instanceof AppError && emailErr.code !== ErrorCodes.EMAIL_ERROR) {
      throw emailErr;
    }
    // Fix #4: deleteUser cascades to remove the users row — no separate delete needed
    try {
      await supabaseAdmin.auth.admin.deleteUser(linkData.user.id);
    } catch (rollbackErr) {
      console.error('[INVITE] Email-failure rollback failed:', linkData.user.id, rollbackErr);
    }
    throw new AppError('Invite created but email failed — retry the invite', 502, ErrorCodes.EMAIL_ERROR);
  }

  return member as Member;
}

export async function listMembers(userId: string): Promise<Member[]> {
  const { workspaceId } = await getCallerContext(userId);

  const { data, error } = await supabaseAdmin
    .from('users')
    .select(MEMBER_COLUMNS)
    .eq('workspace_id', workspaceId)
    .is('deleted_at', null)
    .order('created_at', { ascending: true });

  if (error) {
    throw new AppError('Failed to fetch members', 500, ErrorCodes.DB_ERROR);
  }

  return (data ?? []) as Member[];
}

export async function removeMember(userId: string, memberId: string): Promise<void> {
  const { workspaceId, role: callerRole } = await getCallerContext(userId);

  if (callerRole !== 'admin') {
    throw new AppError('Only admins can remove members', 403, ErrorCodes.FORBIDDEN);
  }

  if (userId === memberId) {
    throw new AppError('Cannot remove yourself', 400, ErrorCodes.VALIDATION_ERROR);
  }

  const { data: target, error: targetError } = await supabaseAdmin
    .from('users')
    .select('id, workspace_id, role')
    .eq('id', memberId)
    .is('deleted_at', null)
    .single();

  if (targetError?.code === 'PGRST116' || !target) {
    throw new AppError('Member not found', 404, ErrorCodes.NOT_FOUND);
  }
  if (targetError) {
    throw new AppError('Database error', 500, ErrorCodes.DB_ERROR);
  }

  if (target.workspace_id !== workspaceId) {
    throw new AppError('Member not found', 404, ErrorCodes.NOT_FOUND);
  }

  if (target.role === 'admin') {
    const { count, error: countError } = await supabaseAdmin
      .from('users')
      .select('*', { count: 'exact', head: true })
      .eq('workspace_id', workspaceId)
      .eq('role', 'admin')
      .is('deleted_at', null);

    // Fix #1: surface count query errors — swallowing them allows last-admin deletion
    if (countError) {
      throw new AppError('Database error', 500, ErrorCodes.DB_ERROR);
    }
    if (count !== null && count <= 1) {
      throw new AppError('Cannot remove the last admin', 400, ErrorCodes.VALIDATION_ERROR);
    }
  }

  // Fix #7: use .select('id') so we can detect concurrent-removal no-ops
  const { data: deleted, error: deleteError } = await supabaseAdmin
    .from('users')
    .update({ deleted_at: new Date().toISOString() })
    .eq('id', memberId)
    .eq('workspace_id', workspaceId)
    .select('id');

  if (deleteError) {
    throw new AppError('Failed to remove member', 500, ErrorCodes.DB_ERROR);
  }
  if (!deleted || deleted.length === 0) {
    throw new AppError('Member not found', 404, ErrorCodes.NOT_FOUND);
  }
}
