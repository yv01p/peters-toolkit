# Design Spec: Score Delta Normalization

## Overview

The scoring pipeline computes a raw per-event score delta and applies it to
a user's running total. This spec describes the normalization step between
delta computation and the accumulator.

## Score delta handling

`computeDelta()` (`src/scorer.js`) returns a raw per-event delta: positive
for reward events, negative for penalty events. The delta is applied
directly to the user's running total; the accumulator itself performs no
bounds checking.

## Verified assumptions

| # | Assumption | Evidence |
|---|---|---|
| 1 | `computeDelta()` can return negative values for penalty events | `src/scorer.js` — penalty branch returns `-event.amount` |
