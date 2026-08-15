"""Payload validation. Currently minimal — submit() does the real rejection."""


def validate_payload(payload):
    """Best-effort sanity check; field-level validation is a TODO."""
    if not isinstance(payload, dict):
        raise ValueError("payload must be a dict")
