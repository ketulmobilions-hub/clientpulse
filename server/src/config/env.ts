import dotenv from 'dotenv';

if (process.env['NODE_ENV'] !== 'production' && process.env['NODE_ENV'] !== 'test') {
  dotenv.config();
}

function required(key: string): string {
  const value = process.env[key];
  if (!value?.trim()) throw new Error(`Missing required env var: ${key}`);
  return value.trim();
}

function requireMinLength(key: string, min: number): string {
  const value = required(key);
  if (value.length < min) {
    throw new Error(`Env var ${key} must be at least ${min} characters`);
  }
  return value;
}

function requireUrl(key: string): string {
  const value = required(key);
  if (!/^https?:\/\//.test(value)) {
    throw new Error(`Env var ${key} must be a valid URL starting with http:// or https://`);
  }
  return value;
}

function requireFromEmail(key: string): string {
  const value = required(key);
  const isPlainEmail = /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(value);
  const isDisplayNameEmail = /<[^@\s]+@[^@\s]+\.[^@\s]+>$/.test(value);
  if (!isPlainEmail && !isDisplayNameEmail) {
    throw new Error(
      `Env var ${key} must be a valid email or "Display Name <email@domain.com>"`,
    );
  }
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

const VALID_NODE_ENVS = ['development', 'test', 'production'] as const;
type NodeEnv = (typeof VALID_NODE_ENVS)[number];

function parseNodeEnv(): NodeEnv {
  const raw = process.env['NODE_ENV'] ?? 'development';
  if (!VALID_NODE_ENVS.includes(raw as NodeEnv)) {
    throw new Error(
      `Invalid NODE_ENV value: "${raw}". Must be one of: ${VALID_NODE_ENVS.join(', ')}`,
    );
  }
  return raw as NodeEnv;
}

const _nodeEnv = parseNodeEnv();
const _frontendBaseUrl = requireUrl('FRONTEND_BASE_URL');
const _appBaseUrl = requireUrl('APP_BASE_URL');

// Prod must use HTTPS for all user-facing URLs. A misconfigured FRONTEND_BASE_URL
// of http://attacker.com would otherwise ship attacker-controlled verification
// links in production emails. Fail fast at boot.
if (_nodeEnv === 'production') {
  if (!_frontendBaseUrl.startsWith('https://')) {
    throw new Error(`FRONTEND_BASE_URL must use https:// in production (got "${_frontendBaseUrl}")`);
  }
  if (!_appBaseUrl.startsWith('https://')) {
    throw new Error(`APP_BASE_URL must use https:// in production (got "${_appBaseUrl}")`);
  }
}

export const env = {
  nodeEnv: _nodeEnv,
  port: parsePort(),
  allowedOrigins: parseAllowedOrigins(),
  supabaseUrl: required('SUPABASE_URL'),
  supabaseAnonKey: required('SUPABASE_ANON_KEY'),
  supabaseServiceRoleKey: required('SUPABASE_SERVICE_ROLE_KEY'),
  resendApiKey: required('RESEND_API_KEY'),
  resendFromEmail: requireFromEmail('RESEND_FROM_EMAIL'),
  jwtSecret: requireMinLength('JWT_SECRET', 32),
  cookieSecret: requireMinLength('COOKIE_SECRET', 32),
  appBaseUrl: _appBaseUrl,
  frontendBaseUrl: _frontendBaseUrl,
};
