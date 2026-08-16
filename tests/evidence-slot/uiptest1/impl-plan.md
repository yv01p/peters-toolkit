# Implementation Plan: Per-User Request Throttling

## Overview

Add a per-user request budget so a single user can't monopolize the
service. This plan covers wiring the throttle check into the request
handler; the counter backend that supplies `request_count` is a separate
task, not covered here.

## Verified plan-level assumptions

| # | Assumption | Evidence |
|---|---|---|
| 1 | `within_budget()` exists in `src/limiter.py` as the throttle entry point | `src/limiter.py:4` |

## Tasks

### Task 1: Wire the throttle check into the request handler

- [ ] Call `within_budget(user_id, request_count)` before dispatching the
      request; reject with HTTP 429 when it returns `False`.
- [ ] The counter backend that supplies `request_count` is out of scope for
      this task.
