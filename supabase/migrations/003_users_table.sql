-- users: agency team members linked to Supabase Auth + a workspace
-- Referenced by auth.service.ts on registration and login.

CREATE TABLE users (
  id           UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  workspace_id UUID        NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  email        TEXT        NOT NULL,
  name         TEXT        NOT NULL DEFAULT '',
  role         TEXT        NOT NULL DEFAULT 'member'
                           CHECK (role IN ('admin', 'member')),
  -- set for invited members; NULL for the workspace creator
  invited_at   TIMESTAMPTZ,
  deleted_at   TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- One active email per workspace (ignores soft-deleted rows)
CREATE UNIQUE INDEX ON users(workspace_id, email) WHERE deleted_at IS NULL;
CREATE INDEX ON users(workspace_id);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Backend uses service role → bypasses RLS entirely.
-- Policy guards against direct anon/authenticated Supabase client calls.
CREATE POLICY users_workspace_member ON users
  FOR ALL TO authenticated
  USING  (workspace_id IN (SELECT get_user_workspace_ids()))
  WITH CHECK (workspace_id IN (SELECT get_user_workspace_ids()));

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE users TO authenticated;

CREATE TRIGGER set_updated_at_users
  BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
