CREATE TABLE IF NOT EXISTS silver.matches (
    match_id TEXT PRIMARY KEY, season TEXT, match_date DATE, venue TEXT, city TEXT,
    team1 TEXT, team2 TEXT, toss_winner TEXT, toss_decision TEXT,
    winner TEXT, match_number TEXT
);

CREATE TABLE IF NOT EXISTS silver.deliveries (
    match_id TEXT, innings_no INT, is_super_over BOOLEAN, batting_team TEXT,
    over_no INT, ball_in_over INT, batter TEXT, bowler TEXT, non_striker TEXT,
    batter_runs INT, extra_runs INT, total_runs INT,
    is_wicket BOOLEAN, wicket_kind TEXT, player_out TEXT
);

TRUNCATE silver.matches, silver.deliveries;

INSERT INTO silver.matches
SELECT match_id,
       payload->'info'->>'season',
       (payload->'info'->'dates'->>0)::date,
       payload->'info'->>'venue',
       payload->'info'->>'city',
       payload->'info'->'teams'->>0,
       payload->'info'->'teams'->>1,
       payload->'info'->'toss'->>'winner',
       payload->'info'->'toss'->>'decision',
       payload->'info'->'outcome'->>'winner',
       payload->'info'->'event'->>'match_number'
FROM bronze.raw_matches;

INSERT INTO silver.deliveries
SELECT m.match_id,
       inn.ord,
       COALESCE((inn.val->>'super_over')::boolean, false),
       inn.val->>'team',
       (ov.val->>'over')::int,
       del.ord,
       del.val->>'batter', del.val->>'bowler', del.val->>'non_striker',
       (del.val->'runs'->>'batter')::int,
       (del.val->'runs'->>'extras')::int,
       (del.val->'runs'->>'total')::int,
       (del.val->'wickets') IS NOT NULL,
       del.val->'wickets'->0->>'kind',
       del.val->'wickets'->0->>'player_out'
FROM bronze.raw_matches m,
     jsonb_array_elements(m.payload->'innings') WITH ORDINALITY AS inn(val, ord),
     jsonb_array_elements(inn.val->'overs') AS ov(val),
     jsonb_array_elements(ov.val->'deliveries') WITH ORDINALITY AS del(val, ord);