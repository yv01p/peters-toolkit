# Implementation Plan: Candidate Ranking Service

## Overview

Ranks inbound candidates for the review queue and hands the ranked list to
the dashboard and the alerting pipeline.

## Verified plan-level assumptions

| # | Assumption | Evidence |
|---|---|---|
| 1 | `rank_candidate(candidate)` exists in `src/ranking.py` as the ranking entry point | `src/ranking.py:4` |

## Task 1: Candidate intake

- [ ] Construct a `Candidate` object from the upstream event stream. No
      scoring or tier logic in this task.

## Task 2: Queue admission

- [ ] Admit a candidate to the queue once its intake fields pass a
      completeness check. No scoring or tier logic in this task.

## Task 3: Ranking

- [ ] `rank_candidate(candidate)` (`src/ranking.py`) returns `(score: float,
      tier: str)` — a 2-tuple. Downstream code destructures `score, tier =
      rank_candidate(c)`.

## Task 4: Dashboard summary

- [ ] The dashboard's summary panel reports a numeric grade alongside a
      bucket label for each candidate, letting support staff sort and group
      results in one pass. Backed by `src/dashboard.py`; see
      `src/test_dashboard.py` for its test coverage.

## Task 5: Rollout

- [ ] Three-phase rollout: internal cohort, 10% of traffic, full traffic. No
      scoring or tier content in this task.
