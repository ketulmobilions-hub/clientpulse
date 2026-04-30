ALTER TABLE updates
  DROP CONSTRAINT IF EXISTS updates_category_check;

-- Migrate data BEFORE adding new constraint so no existing row violates it.
UPDATE updates SET category = 'progress' WHERE category = 'general';

ALTER TABLE updates
  ALTER COLUMN category SET DEFAULT 'progress',
  ADD CONSTRAINT updates_category_check
    CHECK (category IN ('progress', 'milestone', 'deliverable', 'blocker', 'input_needed'));

-- Rollback (LOSSY — development only):
--   Maps new categories to nearest old equivalent; information is not recoverable.
--   'deliverable' and 'input_needed' have no old equivalent and are mapped to 'general'.
--   'progress' is mapped back to 'general' even if it was originally 'general' before migration.
--
-- ALTER TABLE updates DROP CONSTRAINT updates_category_check;
-- UPDATE updates
--   SET category = CASE category
--     WHEN 'progress'    THEN 'general'
--     WHEN 'deliverable' THEN 'general'
--     WHEN 'input_needed' THEN 'general'
--     ELSE category  -- 'milestone' and 'blocker' are unchanged
--   END
--   WHERE category IN ('progress', 'deliverable', 'input_needed');
-- ALTER TABLE updates ALTER COLUMN category SET DEFAULT 'general',
--   ADD CONSTRAINT updates_category_check CHECK (category IN ('general', 'milestone', 'blocker'));
