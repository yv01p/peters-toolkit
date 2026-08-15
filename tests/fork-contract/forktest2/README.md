# ingestd

Small ingestion daemon. A poller takes jobs off a Redis-backed queue and runs
each through `run_job` (validate → submit to the datastore backend). An
internal Flask blueprint serves read-only admin endpoints; a nightly sweep
handles retention.

Layout:

- `src/cli.py` — entry points (`ingestd run`, `ingestd sweep`)
- `src/poller.py` — long-running poll loop (systemd unit `ingestd.service`)
- `src/executor.py` — per-job execution with transient-error retry
- `src/validator.py` — payload validation (currently minimal)
- `src/fieldcheck.py` — generic field checker (half-finished, unused)
- `src/store.py` — datastore client
- `src/jobqueue.py` — queue client (take / ack / DLQ)
- `src/errors.py` — shared error types
- `src/admin.py` — internal admin endpoints (healthz, dlq, failed)
- `src/metrics.py` — statsd counters
- `src/retention.py` — retention sweep
- `src/backfill.py` — JSONL replay tool
- `src/logging_setup.py` — logging bootstrap
- `src/config.py` — env-driven settings
