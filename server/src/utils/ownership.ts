import { supabaseAdmin } from '../config/adminDb';
import { AppError } from '../middleware/errorHandler';

// Single workspace per user is an enforced invariant (one workspace per agency owner).
// limit(1) mirrors project.service.ts — consistent pattern across services.
export async function getWorkspaceIdForUser(userId: string, context: string): Promise<string> {
  const { data, error } = await supabaseAdmin
    .from('workspaces')
    .select('id')
    .eq('owner_id', userId)
    .is('deleted_at', null)
    .limit(1);

  if (error) {
    console.error(`[${context}] getWorkspaceIdForUser DB error:`, error);
    throw new AppError('Failed to resolve workspace', 500, 'DB_ERROR');
  }
  if (!data || data.length === 0) {
    throw new AppError('Workspace not found', 404, 'WORKSPACE_NOT_FOUND');
  }

  return (data[0] as { id: string }).id;
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
