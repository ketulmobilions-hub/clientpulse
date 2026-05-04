ALTER TABLE workspaces ADD COLUMN logo_url TEXT CHECK (logo_url ~ '^https://');
