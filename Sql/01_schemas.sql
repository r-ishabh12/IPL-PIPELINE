CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;

CREATE TABLE IF NOT EXISTS bronze.raw_matches (
    match_id    TEXT PRIMARY KEY,
    file_hash   TEXT NOT NULL,
    payload     JSONB NOT NULL,
    loaded_at   TIMESTAMPTZ DEFAULT now()
);