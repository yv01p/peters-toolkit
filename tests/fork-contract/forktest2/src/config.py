"""Env-driven settings."""

import os
from dataclasses import dataclass


@dataclass
class Settings:
    redis_url: str = os.environ.get("INGESTD_REDIS_URL", "redis://localhost:6379/0")
    stream: str = os.environ.get("INGESTD_STREAM", "ingestd:jobs")
    group: str = os.environ.get("INGESTD_GROUP", "ingestd")
    store_url: str = os.environ.get("INGESTD_STORE_URL", "http://localhost:9200")
    store_timeout: float = float(os.environ.get("INGESTD_STORE_TIMEOUT", "10"))
    poll_timeout: int = int(os.environ.get("INGESTD_POLL_TIMEOUT", "5000"))
    idle_sleep: float = float(os.environ.get("INGESTD_IDLE_SLEEP", "0.5"))
    statsd_host: str = os.environ.get("INGESTD_STATSD_HOST", "127.0.0.1")
    statsd_port: int = int(os.environ.get("INGESTD_STATSD_PORT", "8125"))
    retention_days: int = int(os.environ.get("INGESTD_RETENTION_DAYS", "14"))


settings = Settings()
