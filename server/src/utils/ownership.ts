import { supabaseAdmin } from '../config/adminDb';
import { AppError } from '../middleware/errorHandler';

// Resolves the workspace for a user — either as the workspace owner or as an invited member.
// Owner path: workspaces.owner_id = userId.
// Member path: users.id = userId → workspace_id (for users with role 'admin' | 'member').
export async function getWorkspaceIdForUser(userId: string, context: string): Promise<string> {
  const { data: ownerData, error: ownerError } = await supabaseAdmin
    .from('workspaces')
    .select('id')
    .eq('owner_id', userId)
    .is('deleted_at', null)
    .limit(1);

  if (ownerError) {
    console.error(`[${context}] getWorkspaceIdForUser owner lookup DB error:`, ownerError);
    throw new AppError('Failed to resolve workspace', 500, 'DB_ERROR');
  }
  if (ownerData && ownerData.length > 0) {
    return (ownerData[0] as { id: string }).id;
  }

  // Not an owner — check if the user is an invited member.
  const { data: memberData, error: memberError } = await supabaseAdmin
    .from('users')
    .select('workspace_id')
    .eq('id', userId)
    .maybeSingle<{ workspace_id: string }>();

  if (memberError) {
    console.error(`[${context}] getWorkspaceIdForUser member lookup DB error:`, memberError);
    throw new AppError('Failed to resolve workspace', 500, 'DB_ERROR');
  }
  if (!memberData) {
    throw new AppError('Workspace not found', 404, 'WORKSPACE_NOT_FOUND');
  }

  // Verify the workspace is still active (not soft-deleted).
  const { data: wsData, error: wsError } = await supabaseAdmin
    .from('workspaces')
    .select('id')
    .eq('id', memberData.workspace_id)
    .is('deleted_at', null)
    .maybeSingle<{ id: string }>();

  if (wsError) {
    console.error(`[${context}] getWorkspaceIdForUser workspace verify DB error:`, wsError);
    throw new AppError('Failed to resolve workspace', 500, 'DB_ERROR');
  }
  if (!wsData) {
    throw new AppError('Workspace not found', 404, 'WORKSPACE_NOT_FOUND');
  }

  return wsData.id;
}

export async function assertProjectOwnership(
  projectId: string,
  userId: string,
  context: string,
): Promise<void> {
  const workspaceId = await getWorkspaceIdForUser(userId, context);

  const { data, error } = await supabaseAdmin
    .from('projects')
    .select('id')
    .eq('id', projectId)
    .eq('workspace_id', workspaceId)
    .is('deleted_at', null)
    .single();

  if (error) {
    if (error.code !== 'PGRST116') {
      console.error(`[${context}] assertProjectOwnership DB error:`, error);
      throw new AppError('Failed to verify project ownership', 500, 'DB_ERROR');
    }
    throw new AppError('Project not found', 404, 'NOT_FOUND');
  }
  if (!data) {
    throw new AppError('Project not found', 404, 'NOT_FOUND');
  }
}

export async function getProjectIdsForWorkspace(
  workspaceId: string,
  context: string,
): Promise<string[]> {
  const { data, error } = await supabaseAdmin
    .from('projects')
    .select('id')
    .eq('workspace_id', workspaceId)
    .is('deleted_at', null);

  if (error) {
    console.error(`[${context}] getProjectIdsForWorkspace DB error:`, error);
    throw new AppError('Failed to resolve projects', 500, 'DB_ERROR');
  }

  return ((data ?? []) as { id: string }[]).map((p) => p.id);
}
