"""Nightly retention sweep: trim processed stream entries and stale DLQ rows."""

import time

from .config import settings


def sweep(r):
    horizon_ms = int((time.time() - settings.retention_days * 86400) * 1000)
    r.xtrim(settings.stream, minid=horizon_ms)
    r.xtrim("ingestd:dlq", minid=horizon_ms)
    stale = [
        k for k, ts in r.hgetall("ingestd:failed").items()
        if int(ts) < horizon_ms
    ]
    if stale:
        r.hdel("ingestd:failed", *stale)
