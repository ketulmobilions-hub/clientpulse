-- Fix (round 2, Critical): enforce max-3-attachments-per-update atomically at the DB level.
--
-- Problem: BEFORE INSERT triggers run under READ COMMITTED (Postgres default). Two concurrent
-- transactions both see the same committed count (e.g. 2) and both pass the check, resulting
-- in 4 attachments. The FOR UPDATE lock on the parent update row serializes concurrent inserts
-- for the same update_id — the second transaction blocks until the first commits, at which
-- point COUNT(*) reflects the first transaction's insert.
--
-- SQLSTATE CP001: custom class 'CP' avoids false-positive matches on standard P0001
-- (plpgsql raise_exception) codes from unrelated triggers.
CREATE OR REPLACE FUNCTION check_max_attachments_per_update()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM id FROM updates WHERE id = NEW.update_id FOR UPDATE;

  IF (SELECT COUNT(*) FROM attachments WHERE update_id = NEW.update_id) >= 3 THEN
    RAISE EXCEPTION 'MAX_ATTACHMENTS: update % already has 3 attachments', NEW.update_id
      USING ERRCODE = 'CP001';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_max_attachments
BEFORE INSERT ON attachments
FOR EACH ROW EXECUTE FUNCTION check_max_attachments_per_update();
