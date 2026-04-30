ALTER TABLE projects
  ADD COLUMN IF NOT EXISTS start_date DATE,
  ADD COLUMN IF NOT EXISTS expected_end_date DATE;

-- Enforce logical date ordering at the DB level as last-resort defense.
ALTER TABLE projects
  ADD CONSTRAINT check_project_dates CHECK (
    expected_end_date IS NULL
    OR start_date IS NULL
    OR expected_end_date >= start_date
  );
