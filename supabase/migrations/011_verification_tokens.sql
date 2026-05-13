-- Email verification tokens for agency signups (issue #46).
-- Custom token flow (not Supabase generateLink): mints a 64-char random token, stores it
-- here, sends a branded clientpulse.dev link via Resend. Backend consumes the token and
-- flips auth.users.email_confirmed_at.
--
-- Single-use enforced via consumed_at IS NULL guard in the verify UPDATE. Cascade-delete
-- on auth.users keeps cleanup automatic if a user is hard-deleted (rollback during
-- registration or admin action).

CREATE TABLE verification_tokens (
  token         TEXT PRIMARY KEY,
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email         TEXT NOT NULL,
  expires_at    TIMESTAMPTZ NOT NULL,
  consumed_at   TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Lookup-by-user supports the resend cooldown check (find latest unconsumed for a user).
CREATE INDEX verification_tokens_user_id_idx ON verification_tokens(user_id);

-- Partial index for the verify path: only unconsumed tokens are interesting.
CREATE INDEX verification_tokens_expires_at_idx
  ON verification_tokens(expires_at)
  WHERE consumed_at IS NULL;

-- Backend uses service role (bypasses RLS), so no policy is required. Documenting
-- the table as service-role-only for any future contributor who tries to expose it.
COMMENT ON TABLE verification_tokens IS 'Service-role only. Single-use email verification tokens for agency signups.';
