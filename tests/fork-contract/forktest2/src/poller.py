"""Long-running poll loop. Runs as the `ingestd.service` systemd unit."""

import logging
import time

from .config import settings
from .errors import InvalidJobError
from .executor import run_job

log = logging.getLogger("ingestd.poller")


def poll_loop(queue, store):
    while True:
        job = queue.take(timeout=settings.poll_timeout)
        if job is None:
            time.sleep(settings.idle_sleep)
            continue
        try:
            run_job(job, store)
            queue.ack(job.id)
        except InvalidJobError as e:
            # Never-succeeds jobs go to the DLQ with a reason; operators
            # triage DLQ entries from the admin console.
            queue.send_to_dlq(job, reason=e.reason)
        except Exception:
            # Unexpected crash: mark failed so the job isn't re-delivered.
            # These land in the service log only.
            log.exception("job %s failed", job.id)
            queue.mark_failed(job.id)
