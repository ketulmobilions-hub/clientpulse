-- Hardening pass on verification_tokens (issue #46 follow-up).
-- Code review found: oversized columns, no RLS guard, dead index, race window
-- where two concurrent /resend-verification requests could both insert tokens
-- and send two emails. This migration tightens all four.

-- 1. Length caps. Tokens are sha256 hex (64 chars); emails are RFC-bounded at 254.
--    USING clause is no-op casts; existing rows fit comfortably.
ALTER TABLE verification_tokens
  ALTER COLUMN token TYPE VARCHAR(128) USING token::VARCHAR(128),
  ALTER COLUMN email TYPE VARCHAR(254) USING email::VARCHAR(254);

-- 2. Defense-in-depth RLS. Service role bypasses RLS, so this changes nothing
--    for the backend. It guarantees that if anon/authenticated keys ever touch
--    this table accidentally (misconfigured RPC, future schema exposure), they
--    get zero rows back instead of leaking unconsumed tokens.
ALTER TABLE verification_tokens ENABLE ROW LEVEL SECURITY;
-- No policies = service-role-only access.

-- 3. Drop dead index. The original partial index was on expires_at WHERE
--    consumed_at IS NULL, but no query filters by expires_at without also
--    filtering by token (which uses the PK index). Costs writes for nothing.
DROP INDEX IF EXISTS verification_tokens_expires_at_idx;

-- 4. Race-safe single-active-token-per-user. Without this, two concurrent
--    /resend-verification requests could both pass the cooldown check, both
--    invalidate prior tokens, both insert new rows, and both send emails.
--    The unique partial index makes the second insert fail with 23505;
--    backend treats that as silent success.
CREATE UNIQUE INDEX verification_tokens_one_active_per_user
  ON verification_tokens(user_id)
  WHERE consumed_at IS NULL;
