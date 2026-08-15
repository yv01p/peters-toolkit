"""One-shot backfill: replay a JSONL dump onto the ingest stream."""

import json
import sys

from .config import settings
from .jobqueue import JobQueue


def backfill(path, batch=500):
    q = JobQueue()
    n = 0
    with open(path) as fh:
        pipe = q.r.pipeline()
        for line in fh:
            pipe.xadd(settings.stream, {"payload": line.strip()})
            n += 1
            if n % batch == 0:
                pipe.execute()
                pipe = q.r.pipeline()
        pipe.execute()
    return n


if __name__ == "__main__":
    print(backfill(sys.argv[1]))
