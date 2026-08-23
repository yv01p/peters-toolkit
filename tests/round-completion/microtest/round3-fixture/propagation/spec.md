# Candidate Ranking Service — Design Spec (excerpt)

## §1 Overview

This service ranks inbound candidates for the review queue and hands the
ranked list to the dashboard and the alerting pipeline.

## §2.1 Candidate intake

Describes how a `Candidate` object is constructed from the upstream event
stream; no scoring or tier logic.

## §2.2 Queue admission

A candidate is admitted to the queue once its intake fields pass a
completeness check; no scoring or tier logic.

## §2.3 Alerting hook

`alert_if_urgent(candidate)` checks a separate `urgency` field set by the
intake pipeline; unrelated to ranking.

## §2.4 Ranking

`rank_candidate(candidate)` returns `(score: float, tier: str, reason_code: str)`
— a 3-tuple. Downstream code destructures
`score, tier, reason_code = rank_candidate(c)`.

> This is the fix already applied here. Before the fix, this section read:
> "`rank_candidate(candidate)` returns `(score: float, tier: str)` — a
> 2-tuple. Downstream code destructures `score, tier = rank_candidate(c)`."
> See `review_finding.md` for the finding that motivated the change.

## §3 Data model

Table definitions for `Candidate`, `QueueEntry`, `AlertLog`; no ranking-output
fields represented.

## §4 API endpoints

`GET /queue`, `POST /candidates`, `GET /alerts`; none of the response schemas
mention scoring, tiers, or ranking output.

## §5.1 Executive summary

The ranking engine returns a numeric grade alongside a bucket label for each
candidate, letting the dashboard sort and group results in one pass.

## §6 Rollout plan

Three-phase rollout description; no scoring or tier content.

## §7.1 Fixture setup

Shared `pytest` fixtures for constructing `Candidate` objects; no
ranking-output content.

## §7.2 Queue admission tests

Tests for §2.2's completeness check; no ranking-output content.

## §7.3 Dashboard tests

See `test_dashboard.py`.
