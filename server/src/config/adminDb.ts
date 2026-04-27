import { createClient } from '@supabase/supabase-js';
import { env } from './env';

// ADMIN CLIENT — bypasses all RLS. Backend-only. Never import in routes/ or controllers/.
// Use only in: services/, middleware/, and internal scripts.
export const supabaseAdmin = createClient(env.supabaseUrl, env.supabaseServiceRoleKey);
