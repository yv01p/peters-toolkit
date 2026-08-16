# Implementation Plan: Per-User Retry Budget Accounting

## Overview

Add per-user retry budget accounting so the request handler can decide
when a user has exhausted their retry allowance for the current window.
This plan covers wiring the budget check into the request handler; the
window-reset scheduler is a separate task, not covered here.

## Verified plan-level assumptions

| # | Assumption | Evidence |
|---|---|---|
| 1 | `use_budget()`, `is_over_budget()`, `retries_remaining()`, and `seconds_until_reset()` exist in `src/quota.py` | `src/quota.py:1` |

## Tasks

### Task 1: Wire the budget check into the retry handler

- [ ] Before dispatching a retry, call `use_budget(state)` to charge the
      attempt, then call `is_over_budget(state)` and reject with HTTP 429
      once it returns `True`.
- [ ] Surface `retries_remaining()` and `seconds_until_reset()` in the 429
      response body so the client knows when to try again.
- [ ] The window-reset scheduler that clears `state` between windows is
      out of scope for this task.
