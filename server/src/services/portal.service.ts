import { supabaseAdmin } from '../config/adminDb';
import { AppError } from '../middleware/errorHandler';
import { stripDangerousHtml } from './update.service';
import { SHARE_TOKEN_RE } from '../utils/token';

export interface PortalMilestone {
  id: string;
  title: string;
  due_date: string | null;
  completed: boolean;
  completed_at: string | null;
  position: number;
}

export interface PortalAttachment {
  id: string;
  file_name: string;
  file_url: string;
  file_size: number | null;
  mime_type: string | null;
  created_at: string;
}

export interface PortalUpdate {
  id: string;
  title: string;
  body: string;
  category: string;
  position: number;
  created_at: string;
  updated_at: string;
  attachments: PortalAttachment[];
}

export interface PortalComment {
  id: string;
  update_id: string;
  parent_id: string | null;
  author_type: 'client';
  author_name: string;
  body: string;
  created_at: string;
  updated_at: string;
}

export interface PortalOverview {
  workspace: { name: string; slug: string; logo_url: string | null };
  project: {
    id: string;
    name: string;
    description: string | null;
    client_name: string;
    status: string;
    start_date: string | null;
    expected_end_date: string | null;
  };
  milestones: PortalMilestone[];
  progress: { total: number; completed: number; percent: number };
}

export interface PortalUpdatesPage {
  updates: PortalUpdate[];
  pagination: { page: number; limit: number; total: number };
}

// Normalizes response time for invalid-format tokens to match DB-miss latency,
// reducing timing side-channel leakage on this public endpoint.
async function timingRejectInvalidToken(): Promise<never> {
  await new Promise((resolve) => setTimeout(resolve, 5 + Math.random() * 10));
  throw new AppError('Invalid or expired token', 401, 'INVALID_TOKEN');
}

async function resolveProjectId(shareToken: string): Promise<string> {
  if (!SHARE_TOKEN_RE.test(shareToken)) {
    return timingRejectInvalidToken();
  }

  const { data, error } = await supabaseAdmin
    .from('projects')
    .select('id')
    .eq('share_token', shareToken)
    .is('deleted_at', null)
    .single<{ id: string }>();

  if (error) {
    if (error.code === 'PGRST116') {
      throw new AppError('Invalid or expired token', 401, 'INVALID_TOKEN');
    }
    console.error('[portal.service] resolveProjectId DB error:', error);
    throw new AppError('Database error', 500, 'DB_ERROR');
  }

  if (!data?.id) {
    throw new AppError('Invalid or expired token', 401, 'INVALID_TOKEN');
  }

  return data.id;
}

export async function getPortalOverview(shareToken: string): Promise<PortalOverview> {
  if (!SHARE_TOKEN_RE.test(shareToken)) {
    return timingRejectInvalidToken();
  }

  const { data: projectRow, error: projectError } = await supabaseAdmin
    .from('projects')
    .select(
      'id, name, description, client_name, status, start_date, expected_end_date, workspaces(name, slug, logo_url)',
    )
    .eq('share_token', shareToken)
    .is('deleted_at', null)
    .single<{
      id: string;
      name: string;
      description: string | null;
      client_name: string;
      status: string;
      start_date: string | null;
      expected_end_date: string | null;
      workspaces: { name: string; slug: string; logo_url: string | null } | null;
    }>();

  if (projectError) {
    if (projectError.code === 'PGRST116') {
      throw new AppError('Invalid or expired token', 401, 'INVALID_TOKEN');
    }
    console.error('[portal.service] getPortalOverview project DB error:', projectError);
    throw new AppError('Database error', 500, 'DB_ERROR');
  }

  if (!projectRow) {
    throw new AppError('Invalid or expired token', 401, 'INVALID_TOKEN');
  }

  // Workspace join returns null for orphaned projects — guard before returning
  if (!projectRow.workspaces) {
    console.error('[portal.service] getPortalOverview: project has no workspace', { projectId: projectRow.id });
    throw new AppError('Database error', 500, 'DB_ERROR');
  }

  const { data: milestoneRows, error: milestoneError } = await supabaseAdmin
    .from('milestones')
    .select('id, title, due_date, completed, completed_at, position')
    .eq('project_id', projectRow.id)
    .order('position', { ascending: true });

  if (milestoneError) {
    console.error('[portal.service] getPortalOverview milestones DB error:', milestoneError);
    throw new AppError('Database error', 500, 'DB_ERROR');
  }

  const milestones = (milestoneRows ?? []) as PortalMilestone[];
  const completedCount = milestones.filter((m) => m.completed).length;
  const total = milestones.length;

  return {
    workspace: projectRow.workspaces,
    project: {
      id: projectRow.id,
      name: projectRow.name,
      description: projectRow.description,
      client_name: projectRow.client_name,
      status: projectRow.status,
      start_date: projectRow.start_date,
      expected_end_date: projectRow.expected_end_date,
    },
    milestones,
    progress: {
      total,
      completed: completedCount,
      percent: total > 0 ? Math.round((completedCount / total) * 100) : 0,
    },
  };
}

export async function listPortalUpdates(
  shareToken: string,
  page: number,
  limit: number,
): Promise<PortalUpdatesPage> {
  const projectId = await resolveProjectId(shareToken);

  const offset = (page - 1) * limit;

  const [updatesResult, countResult] = await Promise.all([
    supabaseAdmin
      .from('updates')
      .select(
        'id, title, body, category, position, created_at, updated_at, attachments(id, file_name, file_url, file_size, mime_type, created_at)',
      )
      .eq('project_id', projectId)
      .eq('status', 'published')
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1),
    supabaseAdmin
      .from('updates')
      .select('id', { count: 'exact', head: true })
      .eq('project_id', projectId)
      .eq('status', 'published'),
  ]);

  if (updatesResult.error) {
    console.error('[portal.service] listPortalUpdates DB error:', updatesResult.error);
    throw new AppError('Database error', 500, 'DB_ERROR');
  }
  if (countResult.error) {
    console.error('[portal.service] listPortalUpdates count DB error:', countResult.error);
    throw new AppError('Database error', 500, 'DB_ERROR');
  }

  // Sanitize body on read as a second layer of defense against stored XSS
  const updates = (updatesResult.data ?? []).map((row: unknown) => {
    const r = row as PortalUpdate;
    return { ...r, body: stripDangerousHtml(r.body) };
  });

  const total = countResult.count ?? 0;

  return { updates, pagination: { page, limit, total } };
}

export async function createPortalComment(
  shareToken: string,
  updateId: string,
  input: { author_name: string; body: string; parent_id?: string },
): Promise<PortalComment> {
  const projectId = await resolveProjectId(shareToken);

  // Verify update belongs to this project and is published
  const { data: updateRow, error: updateError } = await supabaseAdmin
    .from('updates')
    .select('id')
    .eq('id', updateId)
    .eq('project_id', projectId)
    .eq('status', 'published')
    .single<{ id: string }>();

  if (updateError) {
    if (updateError.code === 'PGRST116') {
      throw new AppError('Update not found', 404, 'NOT_FOUND');
    }
    console.error('[portal.service] createPortalComment update lookup DB error:', updateError);
    throw new AppError('Database error', 500, 'DB_ERROR');
  }

  if (!updateRow) {
    throw new AppError('Update not found', 404, 'NOT_FOUND');
  }

  // Validate parent_id: must belong to this update AND be a top-level comment (no nesting beyond depth 1)
  if (input.parent_id !== undefined) {
    const { data: parentRow, error: parentError } = await supabaseAdmin
      .from('comments')
      .select('id, parent_id')
      .eq('id', input.parent_id)
      .eq('update_id', updateId)
      .single<{ id: string; parent_id: string | null }>();

    if (parentError) {
      if (parentError.code === 'PGRST116') {
        throw new AppError('Parent comment not found', 404, 'NOT_FOUND');
      }
      console.error('[portal.service] createPortalComment parent lookup DB error:', parentError);
      throw new AppError('Database error', 500, 'DB_ERROR');
    }

    if (!parentRow) {
      throw new AppError('Parent comment not found', 404, 'NOT_FOUND');
    }

    // Enforce max depth of 1: parent must be a top-level comment
    if (parentRow.parent_id !== null) {
      throw new AppError('Replies can only be made to top-level comments', 400, 'VALIDATION_ERROR');
    }
  }

  const { data: comment, error: insertError } = await supabaseAdmin
    .from('comments')
    .insert({
      update_id: updateId,
      author_type: 'client',
      author_id: null,
      author_name: stripDangerousHtml(input.author_name),
      body: stripDangerousHtml(input.body),
      parent_id: input.parent_id ?? null,
    })
    .select('id, update_id, parent_id, author_type, author_name, body, created_at, updated_at')
    .single();

  if (insertError || !comment) {
    console.error('[portal.service] createPortalComment insert DB error:', insertError);
    throw new AppError('Failed to create comment', 500, 'DB_ERROR');
  }

  return comment as PortalComment;
}
