"""Per-case entry point. The batch driver calls run_review once per case."""

import logging

from .applyedits import ApplyError, apply_edits
from .reviewer import ReviewFailed, request_edits

log = logging.getLogger("caseaudit.runner")


def run_review(case, client):
    """Review one case. A failed case is marked and skipped; the batch
    continues with the next case."""
    try:
        batch = request_edits(client, case.packet())
        apply_edits(case, batch)
        case.mark_reviewed()
    except (ReviewFailed, ApplyError) as e:
        log.warning("case %s failed review: %s", case.id, e)
        case.mark_failed(str(e))
