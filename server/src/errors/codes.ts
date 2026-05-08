// ErrorCodes is the single source of truth for all API error codes.
// The ErrorCode union type enforces valid codes at every AppError call site —
// unknown strings (e.g. typos) are rejected by TypeScript at compile time.
// Note: string literals matching a union member are still assignable in TypeScript
// (structural typing), so `new AppError('...', 400, 'NOT_FOUND')` compiles just as
// `new AppError('...', 400, ErrorCodes.NOT_FOUND)` does. Prefer ErrorCodes.* to get
// rename-refactor safety from your editor's find-references tooling.
export const ErrorCodes = {
  // Auth
  UNAUTHORIZED: 'UNAUTHORIZED',
  INVALID_CREDENTIALS: 'INVALID_CREDENTIALS',
  INVALID_TOKEN: 'INVALID_TOKEN',

  // Access
  FORBIDDEN: 'FORBIDDEN',

  // Validation
  VALIDATION_ERROR: 'VALIDATION_ERROR',
  FILE_TOO_LARGE: 'FILE_TOO_LARGE',
  INVALID_FILE_TYPE: 'INVALID_FILE_TYPE',
  MAX_ATTACHMENTS: 'MAX_ATTACHMENTS',

  // Resources — use NOT_FOUND for all missing-resource 404s across all entity types.
  // One consistent code keeps client error handling simple.
  NOT_FOUND: 'NOT_FOUND',
  CONFLICT: 'CONFLICT',

  // Rate limiting
  RATE_LIMITED: 'RATE_LIMITED',

  // Server / DB
  // DB_ERROR: query-level failure — a Supabase/Postgres operation returned an error.
  // DB_UNAVAILABLE: health-check only — the DB cannot be reached at all (503).
  // INTERNAL_ERROR: programmer/config error or unexpected catch-all (not DB-specific).
  // STORAGE_ERROR: Supabase Storage operation failure.
  DB_ERROR: 'DB_ERROR',
  DB_UNAVAILABLE: 'DB_UNAVAILABLE',
  INTERNAL_ERROR: 'INTERNAL_ERROR',
  STORAGE_ERROR: 'STORAGE_ERROR',

  // Email
  EMAIL_ERROR: 'EMAIL_ERROR',

  // Registration
  REGISTRATION_ERROR: 'REGISTRATION_ERROR',
  // EMAIL_EXISTS is intentionally distinct from CONFLICT so the client can
  // drive duplicate-email-specific UX (e.g. "Sign in instead" CTA, prefill email).
  EMAIL_EXISTS: 'EMAIL_EXISTS',
} as const;

export type ErrorCode = (typeof ErrorCodes)[keyof typeof ErrorCodes];
