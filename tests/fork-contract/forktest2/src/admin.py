"""Read-only admin endpoints served on the internal port (Flask blueprint)."""

from flask import Blueprint, jsonify

from .config import settings
from .jobqueue import JobQueue

bp = Blueprint("admin", __name__)


@bp.get("/healthz")
def healthz():
    return jsonify(status="ok")


@bp.get("/dlq")
def dlq():
    q = JobQueue()
    entries = q.r.xrange("ingestd:dlq", count=200)
    return jsonify([
        {"id": mid.decode(), **{k.decode(): v.decode() for k, v in fields.items()}}
        for mid, fields in entries
    ])


@bp.get("/failed")
def failed():
    q = JobQueue()
    return jsonify(sorted(k.decode() for k in q.r.hkeys("ingestd:failed")))
