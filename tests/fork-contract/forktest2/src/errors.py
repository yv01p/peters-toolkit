"""Shared error types for ingestd."""


class TransientBackendError(Exception):
    """Datastore hiccup (timeout, 5xx, connection reset)."""


class InvalidJobError(Exception):
    """A job that can never succeed as submitted."""

    def __init__(self, reason: str):
        self.reason = reason
        super().__init__(reason)
