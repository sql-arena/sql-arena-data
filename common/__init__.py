import datetime
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
TEMP_DIR = REPO_ROOT / "temp"


def log(message: str) -> None:
    print(f"[{datetime.datetime.now():%Y-%m-%d %H:%M:%S}] {message}", flush=True)
