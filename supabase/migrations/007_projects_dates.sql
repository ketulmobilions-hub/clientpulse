-- Add optional date columns to projects (referenced in service layer but missing from schema)
ALTER TABLE projects
  ADD COLUMN IF NOT EXISTS start_date        DATE,
  ADD COLUMN IF NOT EXISTS expected_end_date DATE;
