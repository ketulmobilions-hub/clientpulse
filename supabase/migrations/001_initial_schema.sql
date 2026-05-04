-- ClientPulse initial schema
-- Run in Supabase Dashboard → SQL Editor

-- ────────────────────────────────────────────────────────────
-- Extensions
-- ────────────────────────────────────────────────────────────

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ────────────────────────────────────────────────────────────
-- Functions (plpgsql — no table deps at definition time)
-- ────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION trigger_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Blocks setting used_at when token is already consumed (prevents race-condition re-use)
CREATE OR REPLACE FUNCTION prevent_magic_link_reuse()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.used_at IS NOT NULL THEN
    RAISE EXCEPTION 'magic_link token has already been used';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- On new magic link insert: mark any existing active tokens for same (project, email) as used
-- This ensures only one active token exists per client per project at any time
CREATE OR REPLACE FUNCTION invalidate_previous_magic_links()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE magic_links
  SET used_at = now()
  WHERE project_id = NEW.project_id
    AND email      = NEW.email
    AND used_at    IS NULL
    AND expires_at > now()
    AND id         != NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ────────────────────────────────────────────────────────────
-- Tables
-- ────────────────────────────────────────────────────────────

CREATE TABLE workspaces (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT        NOT NULL,
  -- lowercase alphanumeric + hyphens, 2–63 chars, no leading/trailing hyphen
  slug       TEXT        UNIQUE NOT NULL
                         CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$' AND length(slug) BETWEEN 2 AND 63),
  owner_id   UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE projects (
  id                     UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id           UUID        NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  name                   TEXT        NOT NULL,
  description            TEXT,
  client_name            TEXT        NOT NULL,
  client_email           TEXT        NOT NULL
                                     CHECK (client_email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  status                 TEXT        NOT NULL DEFAULT 'active'
                                     CHECK (status IN ('active', 'completed', 'archived')),
  share_token            TEXT        UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(32), 'hex'),
  -- updated on every token rotation so clients can detect stale bookmarks
  share_token_rotated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at             TIMESTAMPTZ,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE milestones (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id   UUID        NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  title        TEXT        NOT NULL,
  due_date     DATE,
  completed    BOOLEAN     NOT NULL DEFAULT false,
  completed_at TIMESTAMPTZ,
  position     INTEGER     NOT NULL DEFAULT 0,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT completed_at_consistency CHECK (
    (completed = false AND completed_at IS NULL) OR
    (completed = true  AND completed_at IS NOT NULL)
  )
);

CREATE TABLE updates (
  id                   UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id           UUID        NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  -- ON DELETE CASCADE: deleting an agency user removes their update posts
  author_id            UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title                TEXT        NOT NULL,
  body                 TEXT        NOT NULL,
  -- draft updates are invisible to clients; publish explicitly
  status               TEXT        NOT NULL DEFAULT 'draft'
                                   CHECK (status IN ('draft', 'published')),
  position             INTEGER     NOT NULL DEFAULT 0,
  -- set when email notification is sent; NULL = not yet notified
  notification_sent_at TIMESTAMPTZ,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE attachments (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  -- exactly one of update_id / milestone_id must be set
  update_id    UUID        REFERENCES updates(id) ON DELETE CASCADE,
  milestone_id UUID        REFERENCES milestones(id) ON DELETE CASCADE,
  file_name    TEXT        NOT NULL,
  -- must be an https URL (Supabase Storage signed/public URL)
  file_url     TEXT        NOT NULL CHECK (file_url ~ '^https://'),
  file_size    BIGINT,
  mime_type    TEXT,
  -- nullable: SET NULL when uploader account is deleted; attachment stays with the project
  uploaded_by  UUID        REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT attachment_target_check CHECK (
    (update_id IS NOT NULL AND milestone_id IS NULL) OR
    (update_id IS NULL     AND milestone_id IS NOT NULL)
  )
);

CREATE TABLE comments (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  update_id   UUID        NOT NULL REFERENCES updates(id) ON DELETE CASCADE,
  -- self-referential for threaded replies; NULL = top-level comment
  parent_id   UUID        REFERENCES comments(id) ON DELETE CASCADE,
  -- nullable: agency author; SET NULL on user delete (comment body preserved)
  author_id   UUID        REFERENCES auth.users(id) ON DELETE SET NULL,
  author_type TEXT        NOT NULL CHECK (author_type IN ('agency', 'client')),
  author_name TEXT        NOT NULL,
  body        TEXT        NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  -- agency comments must have a traceable author_id
  CONSTRAINT agency_author_has_id CHECK (
    author_type != 'agency' OR author_id IS NOT NULL
  )
);

CREATE TABLE magic_links (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id    UUID        NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  token         TEXT        UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(32), 'hex'),
  email         TEXT        NOT NULL,
  client_name   TEXT,
  expires_at    TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '24 hours'),
  -- set by application when token is consumed; trigger blocks re-use
  used_at       TIMESTAMPTZ,
  -- set after Resend confirms delivery; NULL = email not yet sent or delivery failed
  email_sent_at TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Tracks when a client first viewed each update (one row per update per client email)
CREATE TABLE update_views (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  update_id    UUID        NOT NULL REFERENCES updates(id) ON DELETE CASCADE,
  client_email TEXT        NOT NULL,
  viewed_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ────────────────────────────────────────────────────────────
-- SQL helper function (defined after workspaces table exists)
-- STABLE + SECURITY DEFINER: planner caches result per query → avoids per-row subquery in RLS
-- ────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION get_user_workspace_ids()
RETURNS SETOF UUID
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id FROM workspaces WHERE owner_id = auth.uid() AND deleted_at IS NULL
$$;

-- ────────────────────────────────────────────────────────────
-- Indexes
-- ────────────────────────────────────────────────────────────

CREATE INDEX ON workspaces(owner_id);
CREATE INDEX ON workspaces(deleted_at) WHERE deleted_at IS NULL;

CREATE INDEX ON projects(workspace_id);
CREATE INDEX ON projects(share_token);
CREATE INDEX ON projects(client_email);
CREATE INDEX ON projects(deleted_at) WHERE deleted_at IS NULL;

CREATE INDEX ON milestones(project_id);
CREATE INDEX ON milestones(project_id, completed);

CREATE INDEX ON updates(project_id);
CREATE INDEX ON updates(project_id, created_at DESC);

CREATE INDEX ON attachments(update_id);
CREATE INDEX ON attachments(milestone_id);

CREATE INDEX ON comments(update_id);
CREATE INDEX ON comments(parent_id);

CREATE INDEX ON magic_links(token);
CREATE INDEX ON magic_links(project_id);
CREATE INDEX ON magic_links(email);

-- One view record per update per client email (tracks first view only)
CREATE UNIQUE INDEX ON update_views(update_id, client_email);
CREATE INDEX ON update_views(update_id);

-- ────────────────────────────────────────────────────────────
-- updated_at triggers
-- ────────────────────────────────────────────────────────────

CREATE TRIGGER set_updated_at_workspaces
  BEFORE UPDATE ON workspaces FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

CREATE TRIGGER set_updated_at_projects
  BEFORE UPDATE ON projects FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

CREATE TRIGGER set_updated_at_milestones
  BEFORE UPDATE ON milestones FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

CREATE TRIGGER set_updated_at_updates
  BEFORE UPDATE ON updates FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

CREATE TRIGGER set_updated_at_comments
  BEFORE UPDATE ON comments FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

-- ────────────────────────────────────────────────────────────
-- Magic link integrity triggers
-- ────────────────────────────────────────────────────────────

CREATE TRIGGER enforce_magic_link_single_use
  BEFORE UPDATE OF used_at ON magic_links
  FOR EACH ROW EXECUTE FUNCTION prevent_magic_link_reuse();

CREATE TRIGGER before_magic_link_insert_invalidate_previous
  BEFORE INSERT ON magic_links
  FOR EACH ROW EXECUTE FUNCTION invalidate_previous_magic_links();

-- ────────────────────────────────────────────────────────────
-- Row Level Security
-- Note: backend uses service role key → bypasses RLS entirely.
-- Policies guard against any direct anon/authenticated Supabase client calls.
-- ────────────────────────────────────────────────────────────

ALTER TABLE workspaces   ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects     ENABLE ROW LEVEL SECURITY;
ALTER TABLE milestones   ENABLE ROW LEVEL SECURITY;
ALTER TABLE updates      ENABLE ROW LEVEL SECURITY;
ALTER TABLE attachments  ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments     ENABLE ROW LEVEL SECURITY;
ALTER TABLE magic_links  ENABLE ROW LEVEL SECURITY;
ALTER TABLE update_views ENABLE ROW LEVEL SECURITY;

-- workspaces: owner sees their own non-deleted workspace
CREATE POLICY workspaces_owner ON workspaces
  FOR ALL TO authenticated
  USING  (owner_id = auth.uid() AND deleted_at IS NULL)
  WITH CHECK (owner_id = auth.uid());

-- projects: via workspace ownership (get_user_workspace_ids cached per query)
CREATE POLICY projects_workspace_owner ON projects
  FOR ALL TO authenticated
  USING  (workspace_id IN (SELECT get_user_workspace_ids()) AND deleted_at IS NULL)
  WITH CHECK (workspace_id IN (SELECT get_user_workspace_ids()));

-- milestones: via project → workspace
CREATE POLICY milestones_workspace_owner ON milestones
  FOR ALL TO authenticated
  USING (project_id IN (
    SELECT id FROM projects
    WHERE workspace_id IN (SELECT get_user_workspace_ids()) AND deleted_at IS NULL
  ))
  WITH CHECK (project_id IN (
    SELECT id FROM projects
    WHERE workspace_id IN (SELECT get_user_workspace_ids()) AND deleted_at IS NULL
  ));

-- updates: via project → workspace
CREATE POLICY updates_workspace_owner ON updates
  FOR ALL TO authenticated
  USING (project_id IN (
    SELECT id FROM projects
    WHERE workspace_id IN (SELECT get_user_workspace_ids()) AND deleted_at IS NULL
  ))
  WITH CHECK (project_id IN (
    SELECT id FROM projects
    WHERE workspace_id IN (SELECT get_user_workspace_ids()) AND deleted_at IS NULL
  ));

-- attachments: via update → project → workspace OR milestone → project → workspace
CREATE POLICY attachments_workspace_owner ON attachments
  FOR ALL TO authenticated
  USING (
    (update_id IS NOT NULL AND update_id IN (
      SELECT u.id FROM updates u
      JOIN projects p ON p.id = u.project_id
      WHERE p.workspace_id IN (SELECT get_user_workspace_ids()) AND p.deleted_at IS NULL
    )) OR
    (milestone_id IS NOT NULL AND milestone_id IN (
      SELECT m.id FROM milestones m
      JOIN projects p ON p.id = m.project_id
      WHERE p.workspace_id IN (SELECT get_user_workspace_ids()) AND p.deleted_at IS NULL
    ))
  )
  WITH CHECK (
    (update_id IS NOT NULL AND update_id IN (
      SELECT u.id FROM updates u
      JOIN projects p ON p.id = u.project_id
      WHERE p.workspace_id IN (SELECT get_user_workspace_ids()) AND p.deleted_at IS NULL
    )) OR
    (milestone_id IS NOT NULL AND milestone_id IN (
      SELECT m.id FROM milestones m
      JOIN projects p ON p.id = m.project_id
      WHERE p.workspace_id IN (SELECT get_user_workspace_ids()) AND p.deleted_at IS NULL
    ))
  );

-- comments: via update → project → workspace
CREATE POLICY comments_workspace_owner ON comments
  FOR ALL TO authenticated
  USING (update_id IN (
    SELECT u.id FROM updates u
    JOIN projects p ON p.id = u.project_id
    WHERE p.workspace_id IN (SELECT get_user_workspace_ids()) AND p.deleted_at IS NULL
  ))
  WITH CHECK (update_id IN (
    SELECT u.id FROM updates u
    JOIN projects p ON p.id = u.project_id
    WHERE p.workspace_id IN (SELECT get_user_workspace_ids()) AND p.deleted_at IS NULL
  ));

-- magic_links: via project → workspace
CREATE POLICY magic_links_workspace_owner ON magic_links
  FOR ALL TO authenticated
  USING (project_id IN (
    SELECT id FROM projects
    WHERE workspace_id IN (SELECT get_user_workspace_ids()) AND deleted_at IS NULL
  ))
  WITH CHECK (project_id IN (
    SELECT id FROM projects
    WHERE workspace_id IN (SELECT get_user_workspace_ids()) AND deleted_at IS NULL
  ));

-- update_views: via update → project → workspace
CREATE POLICY update_views_workspace_owner ON update_views
  FOR ALL TO authenticated
  USING (update_id IN (
    SELECT u.id FROM updates u
    JOIN projects p ON p.id = u.project_id
    WHERE p.workspace_id IN (SELECT get_user_workspace_ids()) AND p.deleted_at IS NULL
  ))
  WITH CHECK (update_id IN (
    SELECT u.id FROM updates u
    JOIN projects p ON p.id = u.project_id
    WHERE p.workspace_id IN (SELECT get_user_workspace_ids()) AND p.deleted_at IS NULL
  ));

-- ────────────────────────────────────────────────────────────
-- Grants
-- Required: RLS policies are unreachable without table-level privileges.
-- Without these, authenticated role gets "permission denied" instead of an RLS denial.
-- ────────────────────────────────────────────────────────────

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE workspaces   TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE projects     TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE milestones   TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE updates      TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE attachments  TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE comments     TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE magic_links  TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE update_views TO authenticated;
