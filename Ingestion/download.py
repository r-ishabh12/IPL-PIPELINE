import io, zipfile, requests, pathlib

URL = "https://cricsheet.org/downloads/ipl_json.zip"   # where the data lives
OUT = pathlib.Path("data/raw")                          # where we save it

def main():
    OUT.mkdir(parents=True, exist_ok=True)              # create data/raw if missing
    r = requests.get(URL, timeout=60)                   # download the zip
    r.raise_for_status()                                # stop with an error if download failed
    with zipfile.ZipFile(io.BytesIO(r.content)) as z:
        z.extractall(OUT)                               # unzip into data/raw
    print(f"Extracted {len(list(OUT.glob('*.json')))} match files")

if __name__ == "__main__":
    main()