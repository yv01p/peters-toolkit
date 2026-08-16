"""quota.py -- per-user retry budget helpers.

Each retry costs STEP budget units; a user is over budget once their
cumulative usage reaches BUDGET_LIMIT for the current window.
"""

STEP = 0.1
BUDGET_LIMIT = 1.0


def use_budget(state, n=1):
    """Charge `n` retries (STEP each) against `state["used"]` and return
    the updated cumulative usage."""
    for _ in range(n):
        state["used"] = state["used"] + STEP
    return state["used"]


def is_over_budget(state):
    """Return True once cumulative usage has reached BUDGET_LIMIT."""
    return state["used"] >= BUDGET_LIMIT


def retries_remaining(attempt, max_attempts=3):
    """Return the number of retry attempts still allowed after `attempt`
    completed attempts (0-indexed count of attempts already made)."""
    return max_attempts - attempt


def seconds_until_reset(elapsed, window=60):
    """Return the seconds remaining until the current window resets."""
    return window - elapsed
