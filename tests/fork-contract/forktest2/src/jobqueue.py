"""Queue client: take / ack / mark_failed / DLQ over Redis streams."""

import json

import redis

from .config import settings
from .errors import InvalidJobError


class Job:
    def __init__(self, id, payload):
        self.id = id
        self.payload = payload
        self.result = None

    def mark_done(self, result):
        self.result = result


class JobQueue:
    def __init__(self):
        self.r = redis.Redis.from_url(settings.redis_url)

    def take(self, timeout):
        entry = self.r.xread({settings.stream: ">"}, count=1, block=timeout)
        if not entry:
            return None
        msg_id, fields = entry[0][1][0]
        try:
            payload = json.loads(fields[b"payload"])
        except (KeyError, json.JSONDecodeError) as e:
            raise InvalidJobError(f"undecodable envelope {msg_id}: {e}") from e
        return Job(msg_id.decode(), payload)

    def ack(self, job_id):
        self.r.xack(settings.stream, settings.group, job_id)

    def mark_failed(self, job_id):
        self.r.xack(settings.stream, settings.group, job_id)
        self.r.hset("ingestd:failed", job_id, 1)

    def send_to_dlq(self, job, reason):
        self.r.xadd("ingestd:dlq", {"job": job.id, "reason": reason})
        self.r.xack(settings.stream, settings.group, job.id)
