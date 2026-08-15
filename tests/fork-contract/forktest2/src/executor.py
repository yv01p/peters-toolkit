"""Per-job execution: validate, then submit, with transient-error retry."""

import time

from .errors import TransientBackendError
from .validator import validate_payload

MAX_ATTEMPTS = 3


def run_job(job, store):
    """Run one job. Called by the poller for every job taken off the queue."""
    validate_payload(job.payload)
    for attempt in range(1, MAX_ATTEMPTS + 1):
        try:
            result = store.submit(job.payload)
            job.mark_done(result)
            return
        except TransientBackendError:
            if attempt == MAX_ATTEMPTS:
                raise
            time.sleep(min(2 ** attempt, 30))
