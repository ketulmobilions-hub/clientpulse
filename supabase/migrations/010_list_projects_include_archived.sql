-- Adds an optional `p_include_archived` parameter to list_projects_with_aggregates so
-- the dashboard fetch can exclude archived rows at the SQL layer instead of post-filtering
-- in TypeScript. Archived rows still travel over the wire today; on workspaces with many
-- archived projects this is wasted bandwidth on every dashboard load.
--
-- Drop the old 1-arg overload from migration 008 first. Postgres allows both overloads
-- to coexist, but PostgREST's RPC resolver throws PGRST203 ("could not choose the best
-- candidate function") when a call's arg shape matches multiple overloads via defaults.
-- One canonical 2-arg signature avoids the ambiguity.

DROP FUNCTION IF EXISTS list_projects_with_aggregates(UUID);

CREATE OR REPLACE FUNCTION list_projects_with_aggregates(
  p_workspace_id UUID,
  p_include_archived BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
  id                  UUID,
  workspace_id        UUID,
  name                TEXT,
  description         TEXT,
  client_name         TEXT,
  client_email        TEXT,
  status              TEXT,
  share_token         TEXT,
  start_date          DATE,
  expected_end_date   DATE,
  created_at          TIMESTAMPTZ,
  updated_at          TIMESTAMPTZ,
  update_count        INTEGER,
  comment_count       INTEGER,
  latest_update_title TEXT,
  progress_pct        INTEGER
)
LANGUAGE sql STABLE
SET search_path = public
AS $$
  SELECT
    p.id,
    p.workspace_id,
    p.name,
    p.description,
    p.client_name,
    p.client_email,
    p.status,
    p.share_token,
    p.start_date,
    p.expected_end_date,
    p.created_at,
    p.updated_at,
    COALESCE(uc.cnt, 0)::INTEGER AS update_count,
    COALESCE(cc.cnt, 0)::INTEGER AS comment_count,
    lu.title                     AS latest_update_title,
    CASE
      WHEN COALESCE(mc.total, 0) > 0
        THEN ROUND(mc.completed::numeric / mc.total::numeric * 100)::INTEGER
      ELSE NULL
    END                          AS progress_pct
  FROM projects p
  LEFT JOIN LATERAL (
    SELECT u.title
    FROM updates u
    WHERE u.project_id = p.id
    ORDER BY u.created_at DESC, u.id DESC
    LIMIT 1
  ) lu ON TRUE
  LEFT JOIN (
    SELECT project_id, COUNT(*)::INTEGER AS cnt
    FROM updates
    GROUP BY project_id
  ) uc ON uc.project_id = p.id
  LEFT JOIN (
    SELECT u.project_id, COUNT(*)::INTEGER AS cnt
    FROM comments c
    JOIN updates u ON u.id = c.update_id
    GROUP BY u.project_id
  ) cc ON cc.project_id = p.id
  LEFT JOIN (
    SELECT
      project_id,
      SUM(CASE WHEN completed THEN 1 ELSE 0 END)::INTEGER AS completed,
      COUNT(*)::INTEGER                                   AS total
    FROM milestones
    GROUP BY project_id
  ) mc ON mc.project_id = p.id
  WHERE p.workspace_id = p_workspace_id
    AND p.deleted_at IS NULL
    -- IS DISTINCT FROM is NULL-safe: a row with status NULL would slip through
    -- `<> 'archived'` (NULL <> x is NULL, fails WHERE). Schema declares status
    -- NOT NULL today, but the safer predicate is free insurance.
    AND (p_include_archived OR p.status IS DISTINCT FROM 'archived')
  ORDER BY p.created_at DESC;
$$;

GRANT EXECUTE ON FUNCTION list_projects_with_aggregates(UUID, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION list_projects_with_aggregates(UUID, BOOLEAN) TO service_role;
