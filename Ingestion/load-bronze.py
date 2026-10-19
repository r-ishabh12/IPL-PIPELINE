import hashlib, json, pathlib, psycopg2

RAW = pathlib.Path("data/raw")

# "Insert, but if this match_id already exists, update it only if the file changed"
UPSERT = """
INSERT INTO bronze.raw_matches (match_id, file_hash, payload)
VALUES (%s, %s, %s)
ON CONFLICT (match_id) DO UPDATE
SET file_hash = EXCLUDED.file_hash,
    payload   = EXCLUDED.payload,
    loaded_at = now()
WHERE bronze.raw_matches.file_hash <> EXCLUDED.file_hash;
"""

def main():
    conn = psycopg2.connect(host="localhost", port=5433, dbname="ipl", user="ipl", password="ipl")
    cur = conn.cursor()
    files = sorted(RAW.glob("*.json"))
    for f in files:
        text = f.read_text(encoding="utf-8")
        file_hash = hashlib.md5(text.encode()).hexdigest()   # fingerprint of the file
        cur.execute(UPSERT, (f.stem, file_hash, json.dumps(json.loads(text))))
    conn.commit()                                             # save everything
    print(f"Processed {len(files)} files")

if __name__ == "__main__":
    main()