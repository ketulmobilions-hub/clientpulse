import { supabaseAdmin } from '../config/adminDb';
import { AppError } from '../middleware/errorHandler';

const LOGOS_BUCKET = 'logos';

// SVG intentionally excluded: SVG can embed <script> tags and is an XSS vector when
// served from a public CDN URL and opened directly in the browser.
const ALLOWED_EXT = /\.(png|jpg|jpeg|gif|webp)$/i;

// Matches any Supabase Storage public URL for the logos bucket.
// Used to safely extract the storage path without depending on env at module load time.
const LOGOS_PUBLIC_PATH_RE = /\/storage\/v1\/object\/public\/logos\/(.+)$/;

export async function getUploadSignedUrl(userId: string, fileName: string) {
  if (!ALLOWED_EXT.test(fileName)) {
    throw new AppError(
      'Only image files are allowed (png, jpg, jpeg, gif, webp)',
      400,
      'VALIDATION_ERROR',
    );
  }

  const ext = fileName.split('.').pop()!.toLowerCase();
  const path = `${userId}/${Date.now()}.${ext}`;

  const { data, error } = await supabaseAdmin.storage
    .from(LOGOS_BUCKET)
    .createSignedUploadUrl(path);

  if (error || !data) {
    throw new AppError('Failed to generate upload URL', 500, 'STORAGE_ERROR');
  }

  const {
    data: { publicUrl },
  } = supabaseAdmin.storage.from(LOGOS_BUCKET).getPublicUrl(data.path);

  return { signedUrl: data.signedUrl, publicUrl, path: data.path };
}

export async function deleteLogoByUrl(logoUrl: string): Promise<void> {
  const match = LOGOS_PUBLIC_PATH_RE.exec(logoUrl);
  if (!match) return; // not a managed Supabase Storage URL, skip
  const path = decodeURIComponent(match[1]);
  const { error } = await supabaseAdmin.storage.from(LOGOS_BUCKET).remove([path]);
  if (error) {
    throw new Error(`Failed to delete storage object '${path}': ${error.message}`);
  }
}
