import { supabaseAdmin } from '../config/adminDb';
import { AppError } from '../middleware/errorHandler';
import {
  getWorkspaceIdForUser,
  assertProjectOwnership,
  getProjectIdsForWorkspace,
} from '../utils/ownership';

const MILESTONE_COLUMNS =
  'id, project_id, title, due_date, completed, completed_at, position, created_at, updated_at';

const CONTEXT = 'milestone.service';

export interface Milestone {
  id: string;
  project_id: string;
  title: string;
  due_date: string | null;
  completed: boolean;
  completed_at: string | null;
  position: number;
  created_at: string;
  updated_at: string;
}

export async function listMilestones(projectId: string, userId: string): Promise<Milestone[]> {
  await assertProjectOwnership(projectId, userId, CONTEXT);

  const { data, error } = await supabaseAdmin
    .from('milestones')
    .select(MILESTONE_COLUMNS)
    .eq('project_id', projectId)
    .order('position', { ascending: true });

  if (error) {
    console.error('[milestone.service] listMilestones DB error:', error);
    throw new AppError('Failed to fetch milestones', 500, 'DB_ERROR');
  }

  return (data ?? []) as Milestone[];
}

export async function createMilestone(
  projectId: string,
  userId: string,
  input: {
    title: string;
    due_date?: string | null;
    position?: number;
  },
): Promise<Milestone> {
  await assertProjectOwnership(projectId, userId, CONTEXT);

  const { data, error } = await supabaseAdmin
    .from('milestones')
    .insert({
      project_id: projectId,
      title: input.title,
      due_date: input.due_date ?? null,
      position: input.position ?? 0,
    })
    .select(MILESTONE_COLUMNS)
    .single();

  if (error || !data) {
    console.error('[milestone.service] createMilestone DB error:', error);
    throw new AppError('Failed to create milestone', 500, 'DB_ERROR');
  }

  return data as Milestone;
}

export async function updateMilestone(
  milestoneId: string,
  userId: string,
  changes: {
    title?: string;
    due_date?: string | null;
    completed?: boolean;
    position?: number;
  },
): Promise<Milestone> {
  // Issue 2 fix: validate before any DB calls
  const hasChanges =
    changes.title !== undefined ||
    'due_date' in changes ||
    changes.completed !== undefined ||
    changes.position !== undefined;

  if (!hasChanges) {
    throw new AppError('No fields to update', 400, 'VALIDATION_ERROR');
  }

  const workspaceId = await getWorkspaceIdForUser(userId, CONTEXT);
  const projectIds = await getProjectIdsForWorkspace(workspaceId, CONTEXT);

  if (projectIds.length === 0) {
    throw new AppError('Milestone not found', 404, 'NOT_FOUND');
  }

  const payload: Record<string, unknown> = {};
  if (changes.title !== undefined) payload.title = changes.title;
  if ('due_date' in changes) payload.due_date = changes.due_date ?? null;
  if (changes.position !== undefined) payload.position = changes.position;

  if (changes.completed !== undefined) {
    payload.completed = changes.completed;

    if (changes.completed === false) {
      payload.completed_at = null;
    } else {
      // Issue 4 fix: only set completed_at when transitioning false → true.
      // Fetch current state to avoid overwriting the original completion timestamp
      // on idempotent re-submissions.
      const { data: current, error: fetchError } = await supabaseAdmin
        .from('milestones')
        .select('completed')
        .eq('id', milestoneId)
        .in('project_id', projectIds)
        .single();

      if (fetchError) {
        console.error('[milestone.service] updateMilestone fetch-current DB error:', fetchError);
        throw new AppError('Failed to verify milestone state', 500, 'DB_ERROR');
      }
      if (!current) {
        // Milestone vanished between fetch and update (extreme race) — update below
        // will return PGRST116 and throw NOT_FOUND. Don't set completed_at on a phantom row.
      } else if (!(current as { completed: boolean }).completed) {
        payload.completed_at = new Date().toISOString();
      }
      // If already completed: completed_at stays untouched in DB.
      // NOTE: non-atomic — two concurrent false→true PATCHes could each see completed=false
      // and both set completed_at, with the later write winning. Acceptable at this scale.
    }
  }

  const { data, error } = await supabaseAdmin
    .from('milestones')
    .update(payload)
    .eq('id', milestoneId)
    .in('project_id', projectIds)
    .select(MILESTONE_COLUMNS)
    .single();

  if (error) {
    if (error.code === 'PGRST116') {
      throw new AppError('Milestone not found', 404, 'NOT_FOUND');
    }
    console.error('[milestone.service] updateMilestone DB error:', error);
    throw new AppError('Failed to update milestone', 500, 'DB_ERROR');
  }
  if (!data) {
    console.error('[milestone.service] updateMilestone returned null data without error');
    throw new AppError('Failed to update milestone', 500, 'DB_ERROR');
  }

  return data as Milestone;
}

export async function deleteMilestone(milestoneId: string, userId: string): Promise<void> {
  const workspaceId = await getWorkspaceIdForUser(userId, CONTEXT);
  const projectIds = await getProjectIdsForWorkspace(workspaceId, CONTEXT);

  if (projectIds.length === 0) {
    throw new AppError('Milestone not found', 404, 'NOT_FOUND');
  }

  const { error, count } = await supabaseAdmin
    .from('milestones')
    .delete({ count: 'exact' })
    .eq('id', milestoneId)
    .in('project_id', projectIds);

  if (error) {
    console.error('[milestone.service] deleteMilestone DB error:', error);
    throw new AppError('Failed to delete milestone', 500, 'DB_ERROR');
  }

  if (count === null) {
    console.error('[milestone.service] deleteMilestone returned null count — deletion unconfirmed');
    throw new AppError('Failed to confirm deletion', 500, 'DB_ERROR');
  }

  if (count === 0) {
    throw new AppError('Milestone not found', 404, 'NOT_FOUND');
  }
}
