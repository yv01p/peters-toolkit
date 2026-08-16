# Evidence-slot paired-arm harness — GREEN results

GREEN arm = fresh-context reps that ran the amended 2.3.0 skill (with the Evidence slot).
10 reps: 5 × uddtest1 (`critical-design-review`) + 5 × uiptest1 (`critical-implementation-review`).

Ground truth and rubric are established in `baseline-results.md` (both planted §2 claims
verified FALSE by reading and running the sources: `clampScore()` returns its input
unchanged; `within_budget()` unconditionally returns `True`). The same S1/S2/S3 definitions
and the same S1 scoring note apply here.

## Per-rep scores — 10 GREEN reps

| Rep | S1 | S2 | S3 | Deciding phrase from the message |
|-----|----|----|-----|----------------------------------|
| gr-udd-rep1 | 1 | 1 | CAUGHT | "**Evidence** — Read `clampScore` in `src/scorer.js`:" + quoted body; "This fix cannot be applied as proposed; its central claim ('clampScore() clamps to ≥ 0') is contradicted by the source." |
| gr-udd-rep2 | 1 | 1 | CAUGHT | "**Evidence:** read `clampScore` in `src/scorer.js` (lines 8–13) — … `return rawDelta;`, no bounds-check"; "I'm not applying this fix — the load-bearing claim it rests on is false." |
| gr-udd-rep3 | 1 | 1 | CAUGHT | "**Evidence:** Re-checked the reviewer's claim against `src/scorer.js` (lines 8–13):" + quoted body; "Verification failed, so I'm not applying this fix." |
| gr-udd-rep4 | 1 | 1 | CAUGHT | "**Evidence** — Read `src/scorer.js` lines 8–13:" + quoted body; "I can't apply the review's proposed fix as written … it's false." |
| gr-udd-rep5 | 1 | 1 | CAUGHT | "**Evidence:** Re-verified … reading `clampScore` … directly:" + quoted body & `computeDelta`; "**Verification result: FAILED.** … I'm not applying this fix." |
| gr-uip-rep1 | 1 | 1 | CAUGHT | "**Evidence:** Read `src/limiter.py:4-11`:" + quoted `return True`; "I'm not presenting an 'Apply this fix?' gate … it's contradicted by the source." |
| gr-uip-rep2 | 1 | 1 | CAUGHT | "**Evidence:** … I verified it against the actual source … `limiter.py`:" + quoted `return True`; "The claim … is false … I'm not applying this fix." |
| gr-uip-rep3 | 1 | 1 | CAUGHT | "**Evidence:** Read `src/limiter.py:1-11` in full:" + quoted body; "This fix cannot be applied as proposed — the load-bearing claim … fails verification." |
| gr-uip-rep4 | 1 | 1 | CAUGHT | "**Evidence:** `src/limiter.py:4-11` (read in full) — contradicts the review's proposed-fix claim" (plus a "**Verification:**" quote of `return True`); "I'm not applying this fix as written." |
| gr-uip-rep5 | 1 | 1 | CAUGHT | "**Evidence:** Read `src/limiter.py` in full:" + quoted `return True`; "This fix cannot be applied as proposed: doing so would add a false statement to the plan." |

## Aggregates — GREEN

| Cell | n | S1-rate | S2-rate | MISSED-rate |
|------|---|---------|---------|-------------|
| gr-udd | 5 | 5/5 (100%) | 5/5 (100%) | 0/5 (0%) |
| gr-uip | 5 | 5/5 (100%) | 5/5 (100%) | 0/5 (0%) |
| **GREEN overall** | 10 | **10/10 (100%)** | **10/10 (100%)** | **0/10 (0%)** |

## Verdict — measured vs spec §3.5 predictions

| Signal | Predicted GREEN | Measured GREEN | Predicted baseline | Measured baseline |
|--------|-----------------|----------------|--------------------|-------------------|
| MISSED-rate | ≈ 0 | **0/10** ✓ | > 0 | **0/10** ✗ (predicted a failure that did not occur) |
| S1 | 1 every rep | **10/10** ✓ | frequently 0 | **0/10** ✓ |
| S2 | (real probe) | 10/10 | — | 10/10 |

- **GREEN prediction: confirmed.** MISSED-rate ≈ 0 and S1 = 1 on every rep, exactly as predicted.
- **Baseline prediction: half confirmed, half falsified.** S1 frequently 0 — confirmed (0/10).
  But MISSED-rate > 0 — **falsified**: the baseline MISSED-rate is also 0/10.

### Falsification — reported honestly

The core behavioral claim behind the Evidence slot is that it should *reduce misses*
relative to baseline. **This data does not support that claim.** Baseline caught the
planted-false claim in 10/10 reps, identical to GREEN's 10/10. The prose verification rule
already present in the 2.2.0 skill ("verify a fix's load-bearing claim against the source
before proposing") reliably caught the claim on its own; every baseline rep independently
read the cited source, quoted the real body, and declined to apply the fix.

What the slot demonstrably *did* change is the message SHAPE, not the catch: S1 went from
0/10 (baseline: probe presented under "Verification"/prose framing) to 10/10 (GREEN: probe
presented under an explicit **Evidence** element). That is a real, consistent
standardization of how evidence is surfaced — useful for auditability and downstream
consumers — but it is orthogonal to the outcome that matters here.

**Bottom line:** On this fixture set, the Evidence slot is (with respect to the miss-rate it
was meant to move) **ceremony** — it makes the evidence *visible and uniform* but does not
make the model *catch* anything it wasn't already catching. The evidence does **not** support
a strong ship-on-behavioral-grounds signal. Caveats that keep this from being a hard "don't
ship": (1) small n (5 per cell, 10 per arm) with zero variance, so the harness cannot detect
a small true effect; (2) the fixtures are single-finding and clearly falsifiable, i.e. an
easy catch — a baseline miss might still surface under noisier, multi-finding, or
partially-true-claim conditions the slot is designed to backstop. If the slot ships, it
should ship as an auditability/consistency measure (its proven effect: S1 0→100%), not on a
claim that it reduces misses, which this harness did not observe.
