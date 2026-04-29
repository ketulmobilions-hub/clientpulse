ALTER TABLE updates
  ADD COLUMN category TEXT NOT NULL DEFAULT 'general'
    CHECK (category IN ('general', 'milestone', 'blocker'));

-- Rollback: ALTER TABLE updates DROP COLUMN category;
