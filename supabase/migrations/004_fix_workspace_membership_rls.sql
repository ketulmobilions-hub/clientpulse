-- Fix get_user_workspace_ids() to include invited members, not just workspace owners.
-- Previously: only returned workspaces where owner_id = auth.uid().
-- Now: also returns workspaces where user has a non-deleted row in the users table.
-- SECURITY DEFINER means the function runs as its owner and bypasses RLS on users,
-- so there is no circular dependency with the users table RLS policy.

CREATE OR REPLACE FUNCTION get_user_workspace_ids()
RETURNS SETOF UUID
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id FROM workspaces WHERE owner_id = auth.uid() AND deleted_at IS NULL
  UNION
  SELECT workspace_id FROM users WHERE id = auth.uid() AND deleted_at IS NULL
$$;
