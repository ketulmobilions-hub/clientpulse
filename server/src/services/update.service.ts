import { supabaseAdmin } from '../config/adminDb';
import { AppError } from '../middleware/errorHandler';
import {
  getWorkspaceIdForUser,
  assertProjectOwnership,
  getProjectIdsForWorkspace,
} from '../utils/ownership';

const UPDATE_COLUMNS =
  'id, project_id, author_id, title, body, status, category, position, notification_sent_at, created_at, updated_at';
const ATTACHMENT_COLUMNS =
  'id, update_id, file_name, file_url, file_size, mime_type, uploaded_by, created_at';
const COMMENT_COLUMNS =
  'id, update_id, parent_id, author_id, author_type, author_name, body, created_at, updated_at';

export interface Update {
  id: string;
  project_id: string;
  author_id: string;
  title: string;
  body: string;
  status: 'draft' | 'published';
  category: 'progress' | 'milestone' | 'deliverable' | 'blocker' | 'input_needed';
  position: number;
  notification_sent_at: string | null;
  created_at: string;
  updated_at: string;
  attachment_count?: number;
}

export interface Attachment {
  id: string;
  update_id: string;
  file_name: string;
  file_url: string;
  file_size: number | null;
  mime_type: string | null;
  uploaded_by: string | null;
  created_at: string;
}

export interface Comment {
  id: string;
  update_id: string;
  parent_id: string | null;
  author_id: string | null;
  author_type: 'agency' | 'client';
  author_name: string;
  body: string;
  created_at: string;
  updated_at: string;
}

export const VALID_UPDATE_STATUSES = ['draft', 'published'] as const;
export const VALID_UPDATE_CATEGORIES = ['progress', 'milestone', 'deliverable', 'blocker', 'input_needed'] as const;

const CONTEXT = 'update.service';

// Strips <script>, <iframe>, <object>, <embed> tags and inline event handlers
// from Markdown body content before persistence.
function stripDangerousHtml(content: string): string {
  return content
    .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
    .replace(/<\s*\/?\s*(iframe|object|embed)[^>]*>/gi, '')
    .replace(/\s+on\w+\s*=\s*(?:"[^"]*"|'[^']*'|[^\s>]*)/gi, '')
    // Neutralise dangerous URI schemes in Markdown links — [text](scheme:...)
    .replace(/(\[([^\]]*)\]\s*\(\s*)(javascript|vbscript|data):[^)]*(\))/gi, '$1#$4');
}

export async function createUpdate(
  userId: string,
  projectId: string,
  input: {
    title: string;
    body: string;
    category?: 'progress' | 'milestone' | 'deliverable' | 'blocker' | 'input_needed';
    status?: 'draft' | 'published';
  },
): Promise<Update> {
  await assertProjectOwnership(projectId, userId, CONTEXT);

  const { data, error } = await supabaseAdmin
    .from('updates')
    .insert({
      project_id: projectId,
      author_id: userId,
      title: input.title,
      body: stripDangerousHtml(input.body),
      category: input.category ?? 'progress',
      status: input.status ?? 'draft',
    })
    .select(UPDATE_COLUMNS)
    .single();

  if (error || !data) {
    console.error('[update.service] createUpdate DB error:', error);
    throw new AppError('Failed to create update', 500, 'DB_ERROR');
  }

  return data as Update;
}

export async function listUpdates(userId: string, projectId: string): Promise<Update[]> {
  await assertProjectOwnership(projectId, userId, CONTEXT);

  // Note: updates table has no deleted_at column. If soft-delete is added in a future
  // migration, add .is('deleted_at', null) here to match project.service.ts pattern.
  const { data, error } = await supabaseAdmin
    .from('updates')
    .select(`${UPDATE_COLUMNS}, attachments(count)`)
    .eq('project_id', projectId)
    .order('created_at', { ascending: false });

  if (error) {
    console.error('[update.service] listUpdates DB error:', error);
    throw new AppError('Failed to fetch updates', 500, 'DB_ERROR');
  }

  return (data ?? []).map((row: Record<string, unknown>) => {
    const { attachments, ...rest } = row;
    const countEntry = (attachments as Array<{ count: number | string }> | null)?.[0];
    const n = countEntry !== undefined ? Number(countEntry.count) : NaN;
    return { ...rest, attachment_count: Number.isFinite(n) ? n : 0 } as Update;
  });
}

export async function getUpdate(
  userId: string,
  updateId: string,
): Promise<Update & { attachments: Attachment[]; comments: Comment[] }> {
  const workspaceId = await getWorkspaceIdForUser(userId, CONTEXT);
  const projectIds = await getProjectIdsForWorkspace(workspaceId, CONTEXT);

  if (projectIds.length === 0) {
    throw new AppError('Update not found', 404, 'NOT_FOUND');
  }

  // Ownership enforced via .in('project_id', projectIds) — avoids unreliable
  // PostgREST joined-table filter (.eq on relation) which does not act as a WHERE clause.
  const { data: updateRow, error: updateError } = await supabaseAdmin
    .from('updates')
    .select(UPDATE_COLUMNS)
    .eq('id', updateId)
    .in('project_id', projectIds)
    .single();

  if (updateError || !updateRow) {
    if (updateError?.code !== 'PGRST116') {
      console.error('[update.service] getUpdate DB error:', updateError);
    }
    throw new AppError('Update not found', 404, 'NOT_FOUND');
  }

  const [attachmentsResult, commentsResult] = await Promise.all([
    supabaseAdmin.from('attachments').select(ATTACHMENT_COLUMNS).eq('update_id', updateId),
    supabaseAdmin
      .from('comments')
      .select(COMMENT_COLUMNS)
      .eq('update_id', updateId)
      .order('created_at', { ascending: true }),
  ]);

  if (attachmentsResult.error) {
    console.error('[update.service] getUpdate attachments DB error:', attachmentsResult.error);
    throw new AppError('Failed to fetch attachments', 500, 'DB_ERROR');
  }
  if (commentsResult.error) {
    console.error('[update.service] getUpdate comments DB error:', commentsResult.error);
    throw new AppError('Failed to fetch comments', 500, 'DB_ERROR');
  }

  return {
    ...(updateRow as Update),
    attachments: (attachmentsResult.data ?? []) as Attachment[],
    comments: (commentsResult.data ?? []) as Comment[],
  };
}

export async function editUpdate(
  userId: string,
  updateId: string,
  changes: {
    title?: string;
    body?: string;
    category?: 'progress' | 'milestone' | 'deliverable' | 'blocker' | 'input_needed';
    status?: 'draft' | 'published';
    position?: number;
  },
): Promise<Update> {
  const workspaceId = await getWorkspaceIdForUser(userId, CONTEXT);

  const payload: Record<string, unknown> = {};
  if (changes.title !== undefined) payload.title = changes.title;
  if (changes.body !== undefined) payload.body = stripDangerousHtml(changes.body);
  if (changes.category !== undefined) payload.category = changes.category;
  if (changes.status !== undefined) payload.status = changes.status;
  if (changes.position !== undefined) payload.position = changes.position;

  if (Object.keys(payload).length === 0) {
    throw new AppError('No fields to update', 400, 'VALIDATION_ERROR');
  }

  const projectIds = await getProjectIdsForWorkspace(workspaceId, CONTEXT);

  if (projectIds.length === 0) {
    throw new AppError('Update not found', 404, 'NOT_FOUND');
  }

  const { data, error } = await supabaseAdmin
    .from('updates')
    .update(payload)
    .eq('id', updateId)
    .in('project_id', projectIds)
    .select(UPDATE_COLUMNS)
    .single();

  if (error) {
    if (error.code === 'PGRST116') {
      throw new AppError('Update not found', 404, 'NOT_FOUND');
    }
    console.error('[update.service] editUpdate DB error:', error);
    throw new AppError('Failed to update update', 500, 'DB_ERROR');
  }
  if (!data) {
    console.error('[update.service] editUpdate returned null data without error');
    throw new AppError('Failed to update update', 500, 'DB_ERROR');
  }

  return data as Update;
}

export async function deleteUpdate(userId: string, updateId: string): Promise<void> {
  const workspaceId = await getWorkspaceIdForUser(userId, CONTEXT);
  const projectIds = await getProjectIdsForWorkspace(workspaceId, CONTEXT);

  if (projectIds.length === 0) {
    throw new AppError('Update not found', 404, 'NOT_FOUND');
  }

  const { error, count } = await supabaseAdmin
    .from('updates')
    .delete({ count: 'exact' })
    .eq('id', updateId)
    .in('project_id', projectIds);

  if (error) {
    console.error('[update.service] deleteUpdate DB error:', error);
    throw new AppError('Failed to delete update', 500, 'DB_ERROR');
  }

  if (count === null) {
    console.error('[update.service] deleteUpdate returned null count — deletion unconfirmed');
    throw new AppError('Failed to confirm deletion', 500, 'DB_ERROR');
  }

  if (count === 0) {
    throw new AppError('Update not found', 404, 'NOT_FOUND');
  }
}
