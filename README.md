# IPL Data Pipeline

End-to-end data engineering project using IPL ball-by-ball data from [Cricsheet](https://cricsheet.org).
The pipeline downloads raw match files, loads them into Postgres, and transforms them through
bronze, silver, and gold layers (medallion architecture). It is designed to later support
win probability prediction and player statistics.

## Architecture

```
Cricsheet (JSON zip)
   ↓  ingestion/download.py
data/raw/*.json          (1,243 match files, one per match)
   ↓  ingestion/load-bronze.py   (idempotent upsert)
bronze.raw_matches       (raw JSON, untouched)
   ↓  sql/02_silver.sql          (flatten nested JSON)
silver.matches, silver.deliveries   (one row per match / per ball)
   ↓  planned
gold                     (star schema + features for win probability)
```

## Tech Stack

- **Python** (requests, psycopg2) for ingestion
- **PostgreSQL 16** as the database
- **Docker Compose** to run Postgres in a reproducible container
- **SQL** (JSONB functions) for transformation
- **DBeaver** for querying and inspection

Planned: dbt, Apache Airflow, Kafka, Spark, MLflow, FastAPI, Streamlit.

## Project Structure

```
ipl-pipeline/
├── docker-compose.yml
├── requirements.txt
├── ingestion/
│   ├── download.py        # download and extract the Cricsheet zip
│   └── load-bronze.py     # load raw JSON into Postgres (idempotent)
├── sql/
│   ├── 01_schemas.sql     # bronze/silver/gold schemas + raw table
│   └── 02_silver.sql      # flatten JSON into matches and deliveries
├── data/raw/              # downloaded files (git-ignored)
└── README.md
```

## How to Run

1. Install Docker Desktop and start it.
2. Start Postgres (runs on port 5433, so it doesn't clash with a local Postgres):
```bash
   docker compose up -d
```
3. Install dependencies:
```bash
   python -m venv .venv
   .venv\Scripts\activate        # Windows
   pip install -r requirements.txt
```
4. Download data and load bronze:
```bash
   python ingestion/download.py
   python ingestion/load-bronze.py
```
5. Build silver by running `sql/02_silver.sql` in DBeaver (Alt+X), or:
```powershell
   Get-Content sql/02_silver.sql | docker compose exec -T postgres psql -U ipl -d ipl
```

Connection details: host `localhost`, port `5433`, database `ipl`, user `ipl`, password `ipl`.

## Design Decisions

### Why store raw JSON in the bronze layer?
Bronze keeps an untouched copy of the source data. If a transformation has a bug or
the business logic changes, silver and gold can be rebuilt from bronze without
downloading the data again. It also lets me compare cleaned data against the original
to verify correctness, and gives an audit trail of what the source actually sent.

### Why upsert instead of plain insert?
The loader must be idempotent: running it multiple times gives the same result as
running it once. A plain INSERT would fail on the primary key or create duplicate rows
on every rerun. The upsert (`INSERT ... ON CONFLICT DO UPDATE`) inserts new matches,
updates a match only if its file hash changed, and skips unchanged files. This makes
the pipeline safe to retry after a failure and safe to run on a schedule.

### Downsides of TRUNCATE and reload in silver
Silver is fully rebuilt from bronze on every run. This is simple and correct, and fine
for ~1,200 matches, but it has downsides:
- It reprocesses all data even when only a few matches are new, so it becomes slow
  and costly as data grows.
- Tables are empty or incomplete while the reload runs, so anyone querying at that
  moment sees missing data (unless wrapped in a transaction).
- It does not scale to large data volumes.

The planned fix is incremental loading (process only new or changed matches), which
will be implemented with dbt.

## Roadmap

- [x] Phase 1: Ingestion, bronze layer, silver layer
- [ ] Phase 2: Gold star schema (dim_team, dim_player, dim_venue, dim_match, fact_deliveries)
- [ ] Phase 3: Move transformations to dbt with data tests
- [ ] Phase 4: Orchestrate with Airflow (incremental, idempotent runs)
- [ ] Phase 5: Kafka replay of matches + live win probability
- [ ] Phase 6: Feature tables, model training, dashboard

## Known Limitations

- Silver uses full refresh (TRUNCATE + insert), to be replaced by incremental models.
- Streaming will be a replay of historical matches, not a live feed.
- Database credentials are hardcoded for local development; to be moved to `.env`.