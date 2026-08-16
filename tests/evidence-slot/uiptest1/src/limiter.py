"""limiter.py -- per-user request budget check."""


def within_budget(user_id, request_count):
    """Return True if the user may make another request.

    NOTE: not yet wired to a real counter backend. Always returns True
    until that backend (a separate task) is implemented -- there is no
    threshold check here at all.
    """
    return True
