import http.client
import shutil
import time
import urllib.error
import urllib.request
from collections.abc import Callable
from pathlib import Path
from typing import TypeVar

from common import log

T = TypeVar("T")


# Some servers (e.g. Harvard Dataverse) reject the default Python-urllib agent
USER_AGENT = "sql-arena-data"


def download(url: str, path: Path) -> None:
    """Download url to path unless it is already there. A partial download never lands at path.

    An interrupted download resumes from its partial file when the server honours Range requests.
    """
    if path.exists():
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    offset = tmp.stat().st_size if tmp.exists() else 0
    headers = {"User-Agent": USER_AGENT} | ({"Range": f"bytes={offset}-"} if offset else {})
    try:
        with urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=600) as response:
            with open(tmp, "ab" if response.status == 206 else "wb") as out:
                shutil.copyfileobj(response, out, length=8 << 20)
    except urllib.error.HTTPError as e:
        # 416: the partial file is already complete
        if e.code != 416:
            raise
    tmp.rename(path)


def retry(fn: Callable[[], T], attempts: int = 5, delay: int = 30) -> T:
    """Retry fn on network errors. HTTP error responses are raised immediately."""
    for attempt in range(1, attempts + 1):
        try:
            return fn()
        except urllib.error.HTTPError:
            raise
        except (urllib.error.URLError, http.client.IncompleteRead, TimeoutError, ConnectionError) as e:
            if attempt == attempts:
                raise
            log(f"Network error ({e}), retrying in {delay}s")
            time.sleep(delay)
