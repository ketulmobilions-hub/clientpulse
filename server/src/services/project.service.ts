import { supabaseAdmin } from '../config/adminDb';
import { AppError } from '../middleware/errorHandler';

const PROJECT_COLUMNS =
  'id, workspace_id, name, description, client_name, client_email, status, share_token, start_date, expected_end_date, created_at, updated_at';

// Must be kept in sync with PROJECT_COLUMNS and the projects table schema.
// Run `supabase gen types typescript` to regenerate DB types when schema changes.
export interface Project {
  id: string;
  workspace_id: string;
  name: string;
  description: string | null;
  client_name: string;
  client_email: string;
  status: 'active' | 'completed' | 'archived';
  share_token: string;
  start_date: string | null;
  expected_end_date: string | null;
  created_at: string;
  updated_at: string;
}

export const VALID_STATUSES = ['active', 'completed', 'archived'] as const;
type ProjectStatus = (typeof VALID_STATUSES)[number];

async function getWorkspaceIdForUser(userId: string): Promise<string> {
  const { data, error } = await supabaseAdmin
    .from('workspaces')
    .select('id')
    .eq('owner_id', userId)
    .is('deleted_at', null)
    .limit(1);

  if (error) {
    console.error('[project.service] getWorkspaceIdForUser DB error:', error);
    throw new AppError('Failed to resolve workspace', 500, 'DB_ERROR');
  }
  if (!data || data.length === 0) {
    throw new AppError('Workspace not found', 404, 'WORKSPACE_NOT_FOUND');
  }

  return (data[0] as { id: string }).id;
}

export async function listProjects(userId: string): Promise<Project[]> {
  const workspaceId = await getWorkspaceIdForUser(userId);

  const { data, error } = await supabaseAdmin
    .from('projects')
    .select(PROJECT_COLUMNS)
    .eq('workspace_id', workspaceId)
    .is('deleted_at', null)
    .order('created_at', { ascending: false });

  if (error) {
    console.error('[project.service] listProjects DB error:', error);
    throw new AppError('Failed to fetch projects', 500, 'DB_ERROR');
  }

  return (data ?? []) as Project[];
}

export async function getProject(projectId: string, userId: string): Promise<Project> {
  const workspaceId = await getWorkspaceIdForUser(userId);

  const { data, error } = await supabaseAdmin
    .from('projects')
    .select(PROJECT_COLUMNS)
    .eq('id', projectId)
    .eq('workspace_id', workspaceId)
    .is('deleted_at', null)
    .single();

  if (error || !data) {
    if (error?.code !== 'PGRST116') {
      console.error('[project.service] getProject DB error:', error);
    }
    throw new AppError('Project not found', 404, 'NOT_FOUND');
  }

  return data as Project;
}

export async function createProject(
  userId: string,
  input: {
    name: string;
    description?: string;
    client_name: string;
    client_email: string;
    start_date?: string | null;
    expected_end_date?: string | null;
  },
): Promise<Project> {
  const workspaceId = await getWorkspaceIdForUser(userId);

  const { data, error } = await supabaseAdmin
    .from('projects')
    .insert({
      workspace_id: workspaceId,
      name: input.name,
      // Normalize empty/whitespace description to null at the service boundary
      description: input.description?.trim() || null,
      client_name: input.client_name,
      client_email: input.client_email,
      start_date: input.start_date ?? null,
      expected_end_date: input.expected_end_date ?? null,
    })
    .select(PROJECT_COLUMNS)
    .single();

  if (error || !data) {
    if (error?.code === '23514') {
      throw new AppError('client_email is not a valid email address', 400, 'VALIDATION_ERROR');
    }
    console.error('[project.service] createProject DB error:', error);
    throw new AppError('Failed to create project', 500, 'DB_ERROR');
  }

  return data as Project;
}

export async function updateProject(
  projectId: string,
  userId: string,
  updates: {
    name?: string;
    description?: string | null;
    client_name?: string;
    client_email?: string;
    status?: ProjectStatus;
    start_date?: string | null;
    expected_end_date?: string | null;
  },
): Promise<Project> {
  // Runtime status guard — TypeScript types are erased; callers beyond the route layer exist
  if (updates.status !== undefined && !(VALID_STATUSES as readonly string[]).includes(updates.status)) {
    throw new AppError(`status must be one of: ${VALID_STATUSES.join(', ')}`, 400, 'VALIDATION_ERROR');
  }

  const workspaceId = await getWorkspaceIdForUser(userId);

  const payload: Record<string, unknown> = {};

  if (updates.name !== undefined) payload.name = updates.name;
  // 'in' check distinguishes "field absent" from "field explicitly set to null/empty"
  if ('description' in updates) payload.description = updates.description?.trim() || null;
  if (updates.client_name !== undefined) payload.client_name = updates.client_name;
  if (updates.client_email !== undefined) payload.client_email = updates.client_email;
  if (updates.status !== undefined) payload.status = updates.status;
  if ('start_date' in updates) payload.start_date = updates.start_date ?? null;
  if ('expected_end_date' in updates) payload.expected_end_date = updates.expected_end_date ?? null;

  if (Object.keys(payload).length === 0) {
    throw new AppError('No fields to update', 400, 'VALIDATION_ERROR');
  }

  // Ownership enforced by workspace_id filter — no separate SELECT needed
  const { data, error } = await supabaseAdmin
    .from('projects')
    .update(payload)
    .eq('id', projectId)
    .eq('workspace_id', workspaceId)
    .is('deleted_at', null)
    .select(PROJECT_COLUMNS)
    .single();

  if (error || !data) {
    if (error?.code === '23514') {
      throw new AppError('client_email is not a valid email address', 400, 'VALIDATION_ERROR');
    }
    if (error?.code === 'PGRST116' || !data) {
      throw new AppError('Project not found', 404, 'NOT_FOUND');
    }
    console.error('[project.service] updateProject DB error:', error);
    throw new AppError('Failed to update project', 500, 'DB_ERROR');
  }

  return data as Project;
}

export async function archiveProject(projectId: string, userId: string): Promise<Project> {
  const workspaceId = await getWorkspaceIdForUser(userId);

  // Idempotent by design: archiving an already-archived project is a no-op.
  // Ownership enforced by workspace_id filter — no separate SELECT needed.
  const { data, error } = await supabaseAdmin
    .from('projects')
    .update({ status: 'archived' })
    .eq('id', projectId)
    .eq('workspace_id', workspaceId)
    .is('deleted_at', null)
    .select(PROJECT_COLUMNS)
    .single();

  if (error || !data) {
    if (error?.code === 'PGRST116' || !data) {
      throw new AppError('Project not found', 404, 'NOT_FOUND');
    }
    console.error('[project.service] archiveProject DB error:', error);
    throw new AppError('Failed to archive project', 500, 'DB_ERROR');
  }

  return data as Project;
}
