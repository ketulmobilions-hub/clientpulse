import dotenv from 'dotenv';

if (process.env['NODE_ENV'] !== 'production' && process.env['NODE_ENV'] !== 'test') {
  dotenv.config();
}

function required(key: string): string {
  const value = process.env[key];
  if (!value) throw new Error(`Missing required env var: ${key}`);
  return value;
}

function parsePort(): number {
  const raw = process.env['PORT'] ?? '3000';
  const port = parseInt(raw, 10);
  if (isNaN(port) || port < 1 || port > 65535) {
    throw new Error(`Invalid PORT value: "${raw}". Must be an integer between 1 and 65535.`);
  }
  return port;
}

function parseAllowedOrigins(): string[] {
  const raw = process.env['ALLOWED_ORIGINS'] ?? '';
  return raw.split(',').map((o) => o.trim()).filter(Boolean);
}

const jwtSecret = required('JWT_SECRET');
if (jwtSecret.length < 32) {
  throw new Error('JWT_SECRET must be at least 32 characters long');
}

export const env = {
  nodeEnv: process.env['NODE_ENV'] ?? 'development',
  port: parsePort(),
  allowedOrigins: parseAllowedOrigins(),
  supabaseUrl: required('SUPABASE_URL'),
  supabaseAnonKey: required('SUPABASE_ANON_KEY'),
  supabaseServiceRoleKey: required('SUPABASE_SERVICE_ROLE_KEY'),
  resendApiKey: required('RESEND_API_KEY'),
  jwtSecret,
};
