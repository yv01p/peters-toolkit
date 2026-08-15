"""Half-finished generic field checker from the config-validation attempt.

Currently unused; kept for reuse.
"""

_MISSING = object()


def collect_field_errors(payload, spec):
    """Check a dict against a ``{field: (type, required)}`` spec.

    Returns a list of human-readable problem strings, one per violation,
    covering every field in the spec — does not stop at the first problem,
    so callers get a complete picture in a single pass.

    Example::

        spec = {"dataset": (str, True), "priority": (int, False)}
        collect_field_errors({"priority": "high"}, spec)
        # -> ["missing required field 'dataset'",
        #     "field 'priority' must be int, got str"]
    """
    errors = []
    for field, (ftype, required) in spec.items():
        value = payload.get(field, _MISSING)
        if value is _MISSING:
            if required:
                errors.append(f"missing required field '{field}'")
        elif not isinstance(value, ftype):
            errors.append(
                f"field '{field}' must be {ftype.__name__}, got {type(value).__name__}"
            )
        if errors:
            return errors
    return errors
