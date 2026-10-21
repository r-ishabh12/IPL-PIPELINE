
CREATE TABLE IF NOT EXISTS gold.dim_team (
    team_id        INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    team_name      TEXT NOT NULL UNIQUE,
    franchise_name TEXT
);

-- 1. Insert every team name once (safe to rerun)
INSERT INTO gold.dim_team (team_name)
SELECT team_name FROM (
    SELECT team1 AS team_name FROM silver.matches
    UNION
    SELECT team2 FROM silver.matches
) s
ON CONFLICT (team_name) DO NOTHING;

-- 2. Default: a team is its own franchise
UPDATE gold.dim_team
SET franchise_name = team_name
WHERE franchise_name IS NULL;

-- 3. Override for renamed teams (fill in after checking your data)
-- UPDATE gold.dim_team t
-- SET franchise_name = m.franchise_name
-- FROM (VALUES
--     ('Delhi Daredevils',  'Delhi Capitals'),
--     ('Kings XI Punjab',   'Punjab Kings')
--     -- add the rest you confirmed
-- ) AS m(team_name, franchise_name)
-- WHERE t.team_name = m.team_name;

CREATE TABLE IF NOT EXISTS gold.dim_venue (
    venue_id   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    venue_name TEXT NOT NULL UNIQUE,
    city       TEXT
);

INSERT INTO gold.dim_venue (venue_name, city)
SELECT DISTINCT ON (venue) venue, city
FROM silver.matches
WHERE venue IS NOT NULL
ORDER BY venue, city NULLS LAST
ON CONFLICT (venue_name) DO NOTHING;