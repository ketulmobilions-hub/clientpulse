import { supabaseAdmin } from '../config/adminDb';
import { AppError } from '../middleware/errorHandler';
import { ErrorCodes } from '../errors/codes';
import {
  getWorkspaceIdForUser,
  assertProjectOwnership,
  getProjectIdsForWorkspace,
} from '../utils/ownership';
import { env } from '../config/env';
import { sendUpdateNotificationEmail } from './email.service';

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
  comment_count?: number;
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

/**
 * Atomically claims the notification slot for an update (sets notification_sent_at)
 * and sends the client email if a client_email exists on the project.
 *
 * Returns the ISO timestamp that was stamped, or null if another concurrent
 * request already claimed it (in which case no email is sent).
 *
 * Always stamps notification_sent_at when status becomes published — even if
 * client_email is absent — so later email additions don't trigger retroactive sends.
 */
async function sendPublishNotification(
  updateId: string,
  projectId: string,
  updateData: { title: string; body: string; category: string },
  context: string,
): Promise<string | null> {
  const stamp = new Date().toISOString();

  // Atomic claim: only the first concurrent writer wins (IS NULL guard).
  const { data: claimed } = await supabaseAdmin
    .from('updates')
    .update({ notification_sent_at: stamp })
    .eq('id', updateId)
    .is('notification_sent_at', null)
    .select('id')
    .maybeSingle();

  if (!claimed) return null; // another request already sent the notification

  // Filter soft-deleted projects so clients are not emailed about updates
  // belonging to a project the agency has deleted.
  const { data: project, error: projectError } = await supabaseAdmin
    .from('projects')
    .select('name, client_name, client_email, share_token')
    .eq('id', projectId)
    .is('deleted_at', null)
    .maybeSingle<{ name: string; client_name: string; client_email: string | null; share_token: string }>();

  if (projectError) {
    console.error(`[update.service] ${context} project fetch error:`, projectError);
    return stamp;
  }

  // Project soft-deleted (or hard-missing). Revert the notification claim so
  // a future send attempt — after restore from the dashboard or a manual DB
  // un-delete — can re-claim and email the client. Without the revert, the
  // notification_sent_at stamp would stick and the update would never go out
  // even after the project is restored.
  if (!project) {
    await supabaseAdmin
      .from('updates')
      .update({ notification_sent_at: null })
      .eq('id', updateId)
      .eq('notification_sent_at', stamp);
    console.info(`[update.service] ${context} project missing or soft-deleted — reverted notification claim, no email sent.`);
    return null;
  }

  if (!project.client_email) {
    console.info(`[update.service] ${context} no client_email — notification_sent_at stamped, no email sent.`);
    return stamp;
  }

  const baseUrl = env.frontendBaseUrl.replace(/\/$/, '');
  const portalUrl = `${baseUrl}/p/${project.share_token}`;
  const plainExcerpt = stripMarkdown(updateData.body);
  const excerpt = plainExcerpt.slice(0, 300) + (plainExcerpt.length > 300 ? '…' : '');

  try {
    await sendUpdateNotificationEmail(
      project.client_email,
      project.client_name,
      project.name,
      updateData.title,
      updateData.category,
      excerpt,
      portalUrl,
    );
  } catch (err) {
    console.error(`[update.service] ${context} notification email failed:`, err);
  }

  return stamp;
}

function stripMarkdown(text: string): string {
  return text
    .replace(/!\[[^\]]*\]\([^)]*\)/g, '')         // images
    .replace(/\[([^\]]+)\]\([^)]*\)/g, '$1')       // links → label text
    .replace(/`{3}[\s\S]*?`{3}/g, '')              // fenced code blocks
    .replace(/`[^`]*`/g, '')                        // inline code
    .replace(/#{1,6}\s+/g, '')                      // headings
    .replace(/\*\*(.+?)\*\*/g, '$1')               // bold **
    .replace(/__(.+?)__/g, '$1')                    // bold __
    .replace(/\*(.+?)\*/g, '$1')                    // italic *
    .replace(/_(.+?)_/g, '$1')                      // italic _
    .replace(/^\s*[-*+]\s+/gm, '')                  // unordered list markers
    .replace(/^\s*\d+\.\s+/gm, '')                  // ordered list markers
    .replace(/^\s*>\s*/gm, '')                       // blockquotes
    .replace(/\n{2,}/g, ' ')                         // blank lines → space
    .replace(/\n/g, ' ')                             // remaining newlines → space
    .trim();
}

// Strips <script>, <iframe>, <object>, <embed> tags and inline event handlers
// from Markdown body content before persistence.
export function stripDangerousHtml(content: string): string {
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
    throw new AppError('Failed to create update', 500, ErrorCodes.DB_ERROR);
  }

  if (data.status === 'published') {
    const notificationSentAt = await sendPublishNotification(data.id, projectId, data, 'createUpdate');
    return { ...(data as Update), notification_sent_at: notificationSentAt ?? data.notification_sent_at };
  }

  return data as Update;
}

export async function listUpdates(userId: string, projectId: string): Promise<Update[]> {
  await assertProjectOwnership(projectId, userId, CONTEXT);

  // Note: updates table has no deleted_at column. If soft-delete is added in a future
  // migration, add .is('deleted_at', null) here to match project.service.ts pattern.
  const { data, error } = await supabaseAdmin
    .from('updates')
    .select(`${UPDATE_COLUMNS}, attachments(count), comments(count)`)
    .eq('project_id', projectId)
    .order('created_at', { ascending: false });

  if (error) {
    console.error('[update.service] listUpdates DB error:', error);
    throw new AppError('Failed to fetch updates', 500, ErrorCodes.DB_ERROR);
  }

  return (data ?? []).map((row: Record<string, unknown>) => {
    const { attachments, comments, ...rest } = row;
    const attachCount = (attachments as Array<{ count: number | string }> | null)?.[0];
    const an = attachCount !== undefined ? Number(attachCount.count) : NaN;
    const commentCount = (comments as Array<{ count: number | string }> | null)?.[0];
    const cn = commentCount !== undefined ? Number(commentCount.count) : NaN;
    return {
      ...rest,
      attachment_count: Number.isFinite(an) ? an : 0,
      comment_count: Number.isFinite(cn) ? cn : 0,
    } as Update;
  });
}

export async function getUpdate(
  userId: string,
  updateId: string,
): Promise<Update & { attachments: Attachment[]; comments: Comment[] }> {
  const workspaceId = await getWorkspaceIdForUser(userId, CONTEXT);
  const projectIds = await getProjectIdsForWorkspace(workspaceId, CONTEXT);

  if (projectIds.length === 0) {
    throw new AppError('Update not found', 404, ErrorCodes.NOT_FOUND);
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
    throw new AppError('Update not found', 404, ErrorCodes.NOT_FOUND);
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
    throw new AppError('Failed to fetch attachments', 500, ErrorCodes.DB_ERROR);
  }
  if (commentsResult.error) {
    console.error('[update.service] getUpdate comments DB error:', commentsResult.error);
    throw new AppError('Failed to fetch comments', 500, ErrorCodes.DB_ERROR);
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
    throw new AppError('No fields to update', 400, ErrorCodes.VALIDATION_ERROR);
  }

  const projectIds = await getProjectIdsForWorkspace(workspaceId, CONTEXT);

  if (projectIds.length === 0) {
    throw new AppError('Update not found', 404, ErrorCodes.NOT_FOUND);
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
      throw new AppError('Update not found', 404, ErrorCodes.NOT_FOUND);
    }
    console.error('[update.service] editUpdate DB error:', error);
    throw new AppError('Failed to update update', 500, ErrorCodes.DB_ERROR);
  }
  if (!data) {
    console.error('[update.service] editUpdate returned null data without error');
    throw new AppError('Failed to update update', 500, ErrorCodes.DB_ERROR);
  }

  if (changes.status === 'published') {
    const notificationSentAt = await sendPublishNotification(data.id, data.project_id, data, 'editUpdate');
    return { ...(data as Update), notification_sent_at: notificationSentAt ?? data.notification_sent_at };
  }

  return data as Update;
}

export async function listComments(userId: string, updateId: string): Promise<Comment[]> {
  const workspaceId = await getWorkspaceIdForUser(userId, CONTEXT);
  const projectIds = await getProjectIdsForWorkspace(workspaceId, CONTEXT);

  // #2: projectIds.length === 0 guard is intentional and consistent with editUpdate/deleteUpdate.
  // It avoids an empty .in() call (which PostgREST may reject) at the cost of a slight timing
  // difference vs. the normal not-found path. Auth is required, so the attack surface is limited.
  if (projectIds.length === 0) {
    throw new AppError('Update not found', 404, ErrorCodes.NOT_FOUND);
  }

  // #1: Agency can comment on updates of any status (draft or published) — they own the content
  // and use comments for internal review. Client portal restricts to published only.
  const { data: updateRow, error: updateError } = await supabaseAdmin
    .from('updates')
    .select('id')
    .eq('id', updateId)
    .in('project_id', projectIds)
    .single<{ id: string }>();

  if (!updateRow) {
    if (updateError && updateError.code !== 'PGRST116') {
      console.error('[update.service] listComments update lookup DB error:', updateError);
      throw new AppError('Failed to fetch comments', 500, ErrorCodes.DB_ERROR);
    }
    throw new AppError('Update not found', 404, ErrorCodes.NOT_FOUND);
  }

  const { data, error } = await supabaseAdmin
    .from('comments')
    .select(COMMENT_COLUMNS)
    .eq('update_id', updateId)
    .order('created_at', { ascending: true });

  if (error) {
    console.error('[update.service] listComments DB error:', error);
    throw new AppError('Failed to fetch comments', 500, ErrorCodes.DB_ERROR);
  }

  return (data ?? []) as Comment[];
}

export async function createAgencyComment(
  userId: string,
  updateId: string,
  input: { body: string; parent_id?: string },
): Promise<Comment> {
  const workspaceId = await getWorkspaceIdForUser(userId, CONTEXT);
  const projectIds = await getProjectIdsForWorkspace(workspaceId, CONTEXT);

  if (projectIds.length === 0) {
    throw new AppError('Update not found', 404, ErrorCodes.NOT_FOUND);
  }

  // Agency can comment on any owned update regardless of status (see listComments note above).
  const { data: updateRow, error: updateError } = await supabaseAdmin
    .from('updates')
    .select('id')
    .eq('id', updateId)
    .in('project_id', projectIds)
    .single<{ id: string }>();

  if (!updateRow) {
    if (updateError && updateError.code !== 'PGRST116') {
      console.error('[update.service] createAgencyComment update lookup DB error:', updateError);
      throw new AppError('Database error', 500, ErrorCodes.DB_ERROR);
    }
    throw new AppError('Update not found', 404, ErrorCodes.NOT_FOUND);
  }

  if (input.parent_id !== undefined) {
    const { data: parentRow, error: parentError } = await supabaseAdmin
      .from('comments')
      .select('id, parent_id')
      .eq('id', input.parent_id)
      .eq('update_id', updateId)
      .single<{ id: string; parent_id: string | null }>();

    if (parentError || !parentRow) {
      if (!parentError || parentError.code === 'PGRST116') {
        throw new AppError('Parent comment not found', 404, ErrorCodes.NOT_FOUND);
      }
      console.error('[update.service] createAgencyComment parent lookup DB error:', parentError);
      throw new AppError('Database error', 500, ErrorCodes.DB_ERROR);
    }

    if (parentRow.parent_id !== null) {
      throw new AppError('Replies can only be made to top-level comments', 400, ErrorCodes.VALIDATION_ERROR);
    }
  }

  // #5: Resolve author_name from users table. Log and use a safe fallback on any DB failure
  // rather than exposing the raw userId UUID as author_name in stored comments.
  const { data: userRow, error: userError } = await supabaseAdmin
    .from('users')
    .select('name, email')
    .eq('id', userId)
    .single<{ name: string | null; email: string }>();

  if (userError && userError.code !== 'PGRST116') {
    console.error('[update.service] createAgencyComment user lookup DB error:', userError);
  }

  const authorName = userRow?.name ?? userRow?.email ?? 'Team Member';

  const { data: comment, error: insertError } = await supabaseAdmin
    .from('comments')
    .insert({
      update_id: updateId,
      author_type: 'agency',
      author_id: userId,
      author_name: stripDangerousHtml(authorName),
      body: stripDangerousHtml(input.body),
      parent_id: input.parent_id ?? null,
    })
    .select(COMMENT_COLUMNS)
    .single();

  if (insertError || !comment) {
    console.error('[update.service] createAgencyComment insert DB error:', insertError);
    throw new AppError('Failed to create comment', 500, ErrorCodes.DB_ERROR);
  }

  return comment as Comment;
}

export async function deleteUpdate(userId: string, updateId: string): Promise<void> {
  const workspaceId = await getWorkspaceIdForUser(userId, CONTEXT);
  const projectIds = await getProjectIdsForWorkspace(workspaceId, CONTEXT);

  if (projectIds.length === 0) {
    throw new AppError('Update not found', 404, ErrorCodes.NOT_FOUND);
  }

  const { error, count } = await supabaseAdmin
    .from('updates')
    .delete({ count: 'exact' })
    .eq('id', updateId)
    .in('project_id', projectIds);

  if (error) {
    console.error('[update.service] deleteUpdate DB error:', error);
    throw new AppError('Failed to delete update', 500, ErrorCodes.DB_ERROR);
  }

  if (count === null) {
    console.error('[update.service] deleteUpdate returned null count — deletion unconfirmed');
    throw new AppError('Failed to confirm deletion', 500, ErrorCodes.DB_ERROR);
  }

  if (count === 0) {
    throw new AppError('Update not found', 404, ErrorCodes.NOT_FOUND);
  }
}
