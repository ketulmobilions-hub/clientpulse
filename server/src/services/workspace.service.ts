import { supabaseAdmin } from '../config/adminDb';
import { AppError } from '../middleware/errorHandler';

const WORKSPACE_COLUMNS = 'id, name, slug, owner_id, logo_url, created_at, updated_at';

function generateSlug(name: string): string {
  const slug = name
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .slice(0, 63)
    .replace(/^-|-$/g, ''); // strip after slice to avoid trailing dash from truncation

  if (slug.length < 2) {
    throw new AppError(
      'Workspace name must contain at least 2 alphanumeric characters',
      400,
      'VALIDATION_ERROR',
    );
  }

  return slug;
}

export async function getWorkspace(userId: string) {
  const { data, error } = await supabaseAdmin
    .from('workspaces')
    .select(WORKSPACE_COLUMNS)
    .eq('owner_id', userId)
    .is('deleted_at', null)
    .single();

  if (error || !data) {
    throw new AppError('Workspace not found', 404, 'NOT_FOUND');
  }

  return data;
}

export async function createWorkspace(userId: string, name: string) {
  const { data: existing } = await supabaseAdmin
    .from('workspaces')
    .select('id')
    .eq('owner_id', userId)
    .is('deleted_at', null)
    .single();

  if (existing) {
    throw new AppError('Workspace already exists', 409, 'CONFLICT');
  }

  const baseSlug = generateSlug(name);

  for (let attempt = 0; attempt < 10; attempt++) {
    const slug = attempt === 0 ? baseSlug : `${baseSlug}-${attempt + 1}`.slice(0, 63);
    const { data, error } = await supabaseAdmin
      .from('workspaces')
      .insert({ name, slug, owner_id: userId })
      .select(WORKSPACE_COLUMNS)
      .single();

    if (!error) return data;
    if (error.code !== '23505') {
      throw new AppError('Failed to create workspace', 500, 'DB_ERROR');
    }
  }

  throw new AppError('Could not generate unique workspace slug', 500, 'INTERNAL_ERROR');
}

export async function updateWorkspace(
  userId: string,
  updates: { name?: string; logo_url?: string | null },
) {
  const payload: Record<string, unknown> = {};

  if ('logo_url' in updates) {
    payload.logo_url = updates.logo_url ?? null;
  }

  if (updates.name !== undefined) {
    const baseSlug = generateSlug(updates.name);
    payload.name = updates.name;

    const { data: current } = await supabaseAdmin
      .from('workspaces')
      .select('slug')
      .eq('owner_id', userId)
      .is('deleted_at', null)
      .single();

    if (!current) {
      throw new AppError('Workspace not found', 404, 'NOT_FOUND');
    }

    if (current.slug !== baseSlug) {
      for (let attempt = 0; attempt < 10; attempt++) {
        const slug = attempt === 0 ? baseSlug : `${baseSlug}-${attempt + 1}`.slice(0, 63);
        const { data, error } = await supabaseAdmin
          .from('workspaces')
          .update({ ...payload, slug })
          .eq('owner_id', userId)
          .is('deleted_at', null)
          .select(WORKSPACE_COLUMNS)
          .single();

        if (!error) return data;
        if (error.code !== '23505') {
          throw new AppError('Failed to update workspace', 500, 'DB_ERROR');
        }
      }
      throw new AppError('Could not generate unique workspace slug', 500, 'INTERNAL_ERROR');
    }
  }

  if (Object.keys(payload).length === 0) {
    throw new AppError('No fields to update', 400, 'VALIDATION_ERROR');
  }

  const { data, error } = await supabaseAdmin
    .from('workspaces')
    .update(payload)
    .eq('owner_id', userId)
    .is('deleted_at', null)
    .select(WORKSPACE_COLUMNS)
    .single();

  if (error || !data) {
    throw new AppError('Workspace not found', 404, 'NOT_FOUND');
  }

  return data;
}
