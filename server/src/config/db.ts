import { createClient } from '@supabase/supabase-js';
import { env } from './env';

// Public client — uses anon key, respects RLS. Safe for user-scoped queries.
export const supabase = createClient(env.supabaseUrl, env.supabaseAnonKey);
