import { supabaseAdmin } from '../config/adminDb';
import { AppError } from '../middleware/errorHandler';
import { ErrorCodes } from '../errors/codes';
import { env } from '../config/env';
import { Attachment } from './update.service';

const ATTACHMENTS_BUCKET = 'attachments';
const MAX_ATTACHMENTS_PER_UPDATE = 3;
export const MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024;

// Fix #2 (round 2): pin hostname to our Supabase project — prevents recording URLs from other
// hosts that happen to mirror the Supabase storage path structure.
const ATTACHMENTS_URL_PREFIX = `${env.supabaseUrl}/storage/v1/object/public/attachments/`;

const ATTACHMENT_COLUMNS =
  'id, update_id, file_name, file_url, file_size, mime_type, uploaded_by, created_at';

// Blocked extensions: executables, scripts, and web-renderable types that can carry payloads.
const BLOCKED_EXT =
  /\.(exe|sh|bat|cmd|ps1|vbs|js|mjs|cjs|ts|tsx|jsx|html|htm|php|asp|aspx|jsp|py|rb|pl|swift|go|java|class|jar|dll|so|dylib)$/i;

// Matches Supabase Storage public URL for the attachments bucket (used for path extraction).
const ATTACHMENTS_PUBLIC_PATH_RE = /\/storage\/v1\/object\/public\/attachments\/(.+)$/;

// Fix #5: accurate message when workspace is not found vs update not found.
async function assertUpdateOwnership(
  userId: string,
  updateId: string,
): Promise<{ id: string; project_id: string }> {
  const { data: wsData, error: wsError } = await supabaseAdmin
    .from('workspaces')
    .select('id')
    .eq('owner_id', userId)
    .is('deleted_at', null)
    .limit(1);

  if (wsError) {
    console.error('[attachment.service] assertUpdateOwnership workspace error:', wsError);
    throw new AppError('Failed to resolve workspace', 500, ErrorCodes.DB_ERROR);
  }
  if (!wsData || wsData.length === 0) {
    throw new AppError('Workspace not found', 404, ErrorCodes.NOT_FOUND);
  }

  const workspaceId = (wsData[0] as { id: string }).id;

  const { data: projectData, error: projectError } = await supabaseAdmin
    .from('projects')
    .select('id')
    .eq('workspace_id', workspaceId)
    .is('deleted_at', null);

  if (projectError) {
    console.error('[attachment.service] assertUpdateOwnership projects error:', projectError);
    throw new AppError('Failed to resolve projects', 500, ErrorCodes.DB_ERROR);
  }

  const projectIds = ((projectData ?? []) as { id: string }[]).map((p) => p.id);

  if (projectIds.length === 0) {
    throw new AppError('Update not found', 404, ErrorCodes.NOT_FOUND);
  }

  const { data: update, error: updateError } = await supabaseAdmin
    .from('updates')
    .select('id, project_id')
    .eq('id', updateId)
    .in('project_id', projectIds)
    .single();

  if (updateError || !update) {
    throw new AppError('Update not found', 404, ErrorCodes.NOT_FOUND);
  }

  return update as { id: string; project_id: string };
}

async function countAttachments(updateId: string): Promise<number> {
  const { count, error } = await supabaseAdmin
    .from('attachments')
    .select('*', { count: 'exact', head: true })
    .eq('update_id', updateId);

  if (error) {
    console.error('[attachment.service] countAttachments DB error:', error);
    throw new AppError('Failed to count attachments', 500, ErrorCodes.DB_ERROR);
  }
  return count ?? 0;
}

export async function generateAttachmentSignedUrl(
  userId: string,
  updateId: string,
  fileName: string,
  mimeType: string,
): Promise<{ signedUrl: string; publicUrl: string; path: string }> {
  await assertUpdateOwnership(userId, updateId);

  const currentCount = await countAttachments(updateId);
  if (currentCount >= MAX_ATTACHMENTS_PER_UPDATE) {
    throw new AppError(
      `Maximum ${MAX_ATTACHMENTS_PER_UPDATE} attachments allowed per update`,
      409,
      ErrorCodes.MAX_ATTACHMENTS,
    );
  }

  if (BLOCKED_EXT.test(fileName)) {
    throw new AppError('File type not allowed', 400, ErrorCodes.INVALID_FILE_TYPE);
  }

  // Fix #7: reject filenames whose printable content is entirely special characters.
  if (!/[a-zA-Z0-9]/.test(fileName)) {
    throw new AppError(
      'file_name must contain at least one alphanumeric character',
      400,
      ErrorCodes.VALIDATION_ERROR,
    );
  }

  const sanitizedName = fileName.replace(/[^a-zA-Z0-9._-]/g, '_');
  const path = `${userId}/${updateId}/${Date.now()}-${sanitizedName}`;

  const { data, error } = await supabaseAdmin.storage
    .from(ATTACHMENTS_BUCKET)
    .createSignedUploadUrl(path);

  if (error || !data) {
    console.error('[attachment.service] generateAttachmentSignedUrl storage error:', error);
    throw new AppError('Failed to generate upload URL', 500, ErrorCodes.STORAGE_ERROR);
  }

  const {
    data: { publicUrl },
  } = supabaseAdmin.storage.from(ATTACHMENTS_BUCKET).getPublicUrl(data.path);

  return { signedUrl: data.signedUrl, publicUrl, path: data.path };
}

export async function saveAttachment(
  userId: string,
  updateId: string,
  input: { file_url: string; file_name: string; file_size: number; mime_type: string },
): Promise<Attachment> {
  await assertUpdateOwnership(userId, updateId);

  const currentCount = await countAttachments(updateId);
  if (currentCount >= MAX_ATTACHMENTS_PER_UPDATE) {
    throw new AppError(
      `Maximum ${MAX_ATTACHMENTS_PER_UPDATE} attachments allowed per update`,
      409,
      ErrorCodes.MAX_ATTACHMENTS,
    );
  }

  if (input.file_size > MAX_FILE_SIZE_BYTES) {
    throw new AppError('File exceeds 10 MB limit', 400, ErrorCodes.FILE_TOO_LARGE);
  }

  // Fix #2: block dangerous extensions even if caller bypasses the signed-URL flow.
  if (BLOCKED_EXT.test(input.file_name)) {
    throw new AppError('File type not allowed', 400, ErrorCodes.INVALID_FILE_TYPE);
  }

  // Fix #7: reject filenames with no alphanumeric content.
  if (!/[a-zA-Z0-9]/.test(input.file_name)) {
    throw new AppError(
      'file_name must contain at least one alphanumeric character',
      400,
      ErrorCodes.VALIDATION_ERROR,
    );
  }

  // Fix #6 + round-2 fix #2: reject URLs that don't point to our Supabase project's
  // attachments bucket. Hostname is pinned to env.supabaseUrl, preventing callers from
  // recording arbitrary external URLs or URLs from other Supabase projects.
  if (!input.file_url.startsWith(ATTACHMENTS_URL_PREFIX)) {
    throw new AppError('file_url must be a valid attachment storage URL', 400, ErrorCodes.VALIDATION_ERROR);
  }

  const { data, error } = await supabaseAdmin
    .from('attachments')
    .insert({
      update_id: updateId,
      file_name: input.file_name,
      file_url: input.file_url,
      file_size: input.file_size,
      mime_type: input.mime_type,
      uploaded_by: userId,
    })
    .select(ATTACHMENT_COLUMNS)
    .single();

  if (error) {
    // Fix #1 + round-2 fix #3: DB trigger raises CP001 (custom SQLSTATE) when concurrent inserts
    // exceed the 3-attachment cap. Using a custom class code avoids false positives from
    // other P0001 (plpgsql) exceptions that might exist on this table in the future.
    if (error.code === 'CP001') {
      throw new AppError(
        `Maximum ${MAX_ATTACHMENTS_PER_UPDATE} attachments allowed per update`,
        409,
        ErrorCodes.MAX_ATTACHMENTS,
      );
    }
    console.error('[attachment.service] saveAttachment DB error:', error);
    throw new AppError('Failed to save attachment', 500, ErrorCodes.DB_ERROR);
  }
  if (!data) {
    throw new AppError('Failed to save attachment', 500, ErrorCodes.DB_ERROR);
  }

  return data as Attachment;
}

// Fix #3: resolve full ownership chain (workspace → projects → updates) BEFORE fetching the
// attachment row. The attachment fetch is then filtered by `update_id IN (userUpdateIds)`,
// preventing information disclosure about attachments in other workspaces.
//
// Fix #4: idempotent on concurrent deletes (count=0 → 204, not 404); null count → 500.
export async function deleteAttachment(userId: string, attachmentId: string): Promise<void> {
  const { data: wsData, error: wsError } = await supabaseAdmin
    .from('workspaces')
    .select('id')
    .eq('owner_id', userId)
    .is('deleted_at', null)
    .limit(1);

  if (wsError) {
    console.error('[attachment.service] deleteAttachment workspace error:', wsError);
    throw new AppError('Failed to resolve workspace', 500, ErrorCodes.DB_ERROR);
  }
  if (!wsData || wsData.length === 0) {
    throw new AppError('Attachment not found', 404, ErrorCodes.NOT_FOUND);
  }

  const workspaceId = (wsData[0] as { id: string }).id;

  const { data: projectData, error: projectError } = await supabaseAdmin
    .from('projects')
    .select('id')
    .eq('workspace_id', workspaceId)
    .is('deleted_at', null);

  if (projectError) {
    console.error('[attachment.service] deleteAttachment projects error:', projectError);
    throw new AppError('Failed to resolve projects', 500, ErrorCodes.DB_ERROR);
  }

  const projectIds = ((projectData ?? []) as { id: string }[]).map((p) => p.id);
  if (projectIds.length === 0) {
    throw new AppError('Attachment not found', 404, ErrorCodes.NOT_FOUND);
  }

  const { data: updateData, error: updateError } = await supabaseAdmin
    .from('updates')
    .select('id')
    .in('project_id', projectIds);

  if (updateError) {
    console.error('[attachment.service] deleteAttachment updates error:', updateError);
    throw new AppError('Failed to resolve updates', 500, ErrorCodes.DB_ERROR);
  }

  const updateIds = ((updateData ?? []) as { id: string }[]).map((u) => u.id);
  if (updateIds.length === 0) {
    throw new AppError('Attachment not found', 404, ErrorCodes.NOT_FOUND);
  }

  // Ownership-filtered fetch: only returns the attachment if it belongs to this user's workspace.
  const { data: attachment, error: fetchError } = await supabaseAdmin
    .from('attachments')
    .select('id, file_url')
    .eq('id', attachmentId)
    .in('update_id', updateIds)
    .single();

  if (fetchError || !attachment) {
    throw new AppError('Attachment not found', 404, ErrorCodes.NOT_FOUND);
  }

  const fileUrl = (attachment as { file_url: string }).file_url;

  // Fix #4 (round 2): delete DB record before storage. If DB fails, storage is untouched
  // (fully consistent). Storage orphans (file remains after record is gone) are preferable
  // to broken records (record points to a deleted file).
  const { error: deleteError, count } = await supabaseAdmin
    .from('attachments')
    .delete({ count: 'exact' })
    .eq('id', attachmentId);

  if (deleteError) {
    console.error('[attachment.service] deleteAttachment DB error:', deleteError);
    throw new AppError('Failed to delete attachment', 500, ErrorCodes.DB_ERROR);
  }

  if (count === null) {
    console.error('[attachment.service] deleteAttachment returned null count — deletion unconfirmed');
    throw new AppError('Failed to confirm deletion', 500, ErrorCodes.DB_ERROR);
  }

  // Delete storage file after DB record is confirmed gone.
  const match = ATTACHMENTS_PUBLIC_PATH_RE.exec(fileUrl);
  if (match) {
    const storagePath = decodeURIComponent(match[1]);
    const { error: storageError } = await supabaseAdmin.storage
      .from(ATTACHMENTS_BUCKET)
      .remove([storagePath]);
    if (storageError) {
      console.warn(
        '[attachment.service] deleteAttachment storage delete failed (file may be orphaned):',
        storageError,
      );
    }
  }
  // count === 0 means a concurrent request already deleted the record — idempotent, return 204.
}
