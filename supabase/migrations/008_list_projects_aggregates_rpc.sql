-- RPC for dashboard project list with aggregates (progress, update count, comment count, latest update title).
-- Replaces TS-side stitching that scaled O(updates × comments) on transfer.
-- Single round-trip; aggregation is pushed to Postgres which can use indexes.
--
-- Tie-break for "latest update" is deterministic: created_at DESC, id DESC.

CREATE OR REPLACE FUNCTION list_projects_with_aggregates(p_workspace_id UUID)
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
  -- 0–100 inclusive, NULL when project has no milestones (progress is undefined, not zero)
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
  ORDER BY p.created_at DESC;
$$;

-- Backend uses service role key (bypasses RLS), but grant EXECUTE to authenticated as well
-- in case any client-side direct call is added later. The function still respects ownership
-- because the caller passes p_workspace_id; combine with RLS on a view if direct exposure is added.
GRANT EXECUTE ON FUNCTION list_projects_with_aggregates(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION list_projects_with_aggregates(UUID) TO service_role;
