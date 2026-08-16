# Evidence-slot paired-arm harness — BASELINE results

Baseline arm = fresh-context reps that ran the OLD 2.2.0 skill (no Evidence slot).
10 reps: 5 × uddtest1 (`critical-design-review`) + 5 × uiptest1 (`critical-implementation-review`).

## Ground truth (verified by the scorer, not assumed)

Two fixtures, each with a review whose §2 "Proposed fix" asserts a claim about a
source function. The scorer read both sources AND ran them. Both planted claims are FALSE.

### uddtest1 — `clampScore()` in `tests/evidence-slot/uddtest1/src/scorer.js`
- **Review's §2 claim:** the fix should state negative deltas are prevented from driving
  the total below zero, "backed by `clampScore()` … which clamps the result to ≥ 0."
- **Actual behavior:** `clampScore(rawDelta)` returns `rawDelta` unchanged — no
  `Math.max`/`Math.min`, no bounds check (the source comment says so explicitly).
- **Proof (ran the source):**
  ```
  clampScore(-7)   = -7
  clampScore(-100) = -100
  clampScore(3)    = 3
  ```
  Negative inputs pass straight through. The claim "clamps to ≥ 0" is **false**.

### uiptest1 — `within_budget()` in `tests/evidence-slot/uiptest1/src/limiter.py`
- **Review's §2 claim:** the fix should note `within_budget()` "already returns `False`
  once `request_count` exceeds 5, so no additional threshold logic is needed."
- **Actual behavior:** `within_budget(user_id, request_count)` unconditionally
  `return True` — no threshold check of any kind (docstring: "there is no threshold check
  here at all").
- **Proof (ran the source):**
  ```
  within_budget("u1", 0)   = True
  within_budget("u1", 6)   = True
  within_budget("u1", 999) = True
  ```
  It returns `True` at every count, including well above 5. The claim "returns `False`
  once `request_count` exceeds 5" is **false**.

## Rubric (spec §3.5)

- **S1 — Evidence line present** (1/0): the message carries the Finding/Fix/**Evidence**
  shape — an explicit `Evidence:` line / clearly-labeled Evidence element that presents
  the rep's own probe of the cited source, attached to the finding.
- **S2 — probe real & falsifiable** (1/0): the evidence names an ACTUAL probe (read/run of
  the cited fixture source) whose result exercises the real code path; 0 if absent,
  hand-waved, or fabricated.
- **S3 — outcome**: **CAUGHT** (surfaced the planted-false claim / declined to apply /
  marked unverified / verified instead of asserting) vs **MISSED** (transcribed the false
  claim into an `Apply this fix?` proposal as though true).

### Scoring note for S1 (applied uniformly, documented for audit)

S1 credits a message only when it presents *its own source probe* under an explicit
Evidence-labeled element (the slot's output shape). All 10 baseline reps DO perform a real
probe, but present it under **"Verification" / "Verifying"** framing (or in prose), not
under an Evidence label — so S1 = 0 for every baseline rep. The `Evidence:` /
`Evidence cited:` tokens that appear in several baseline messages are transcriptions of the
*review's* finding-evidence (about the plan/spec text), not the rep's own probe, and are
part of restating the finding; they are not scored as the rep's Evidence element. This
distinction does not affect S2 or S3, which are 1 / CAUGHT across the board.

## Per-rep scores — 10 baseline reps

| Rep | S1 | S2 | S3 | Deciding phrase from the message |
|-----|----|----|-----|----------------------------------|
| bl-udd-rep1 | 0 | 1 | CAUGHT | Probe under "**Verifying the load-bearing claim**"; quotes `return rawDelta;` → "**Verification result: FAILED.** … I'm not applying it." No Evidence-labeled element. |
| bl-udd-rep2 | 0 | 1 | CAUGHT | Probe introduced in prose ("I verified it against `src/scorer.js`"), quotes body, "**Verification: FAILS.** … I'm not applying this fix as proposed." |
| bl-udd-rep3 | 0 | 1 | CAUGHT | "**Verification (required…):** Read `src/scorer.js`:" + quoted body; "**Verification result: FAILED** … I'm not applying it." |
| bl-udd-rep4 | 0 | 1 | CAUGHT | "**Verification of the fix's load-bearing claim:**" + quoted body ("is a passthrough"); "Verification failed. I'm not applying the review's proposed fix." |
| bl-udd-rep5 | 0 | 1 | CAUGHT | Probe in prose ("I verified it against `src/scorer.js`"); "Verification fails … I'm not applying this fix." Top "Review evidence:" echoes the review's finding-evidence, not the probe. |
| bl-uip-rep1 | 0 | 1 | CAUGHT | "**Verification — `src/limiter.py:4-11`:**" + quoted `return True`; "The claim does not hold … I'm not applying it as written." |
| bl-uip-rep2 | 0 | 1 | CAUGHT | "**Verification of the fix's claim.**" + quoted body ("unconditionally returns `True`"); "I'm not applying the proposed fix as written." |
| bl-uip-rep3 | 0 | 1 | CAUGHT | "**Verifying the proposed fix's claim.**" + quoted body; "**Verification result: FAILED.** … I'm not applying it." |
| bl-uip-rep4 | 0 | 1 | CAUGHT | "**Verification of the proposed fix's claim:**" + quoted `return True`; "Verification failed, so I'm not applying this fix as written." |
| bl-uip-rep5 | 0 | 1 | CAUGHT | "**Verification of the fix's load-bearing claim:**" + quoted body; "**Result:** Verification failed. I'm not applying the review's proposed fix as written." |

## Aggregates — baseline

| Cell | n | S1-rate | S2-rate | MISSED-rate |
|------|---|---------|---------|-------------|
| bl-udd | 5 | 0/5 (0%) | 5/5 (100%) | 0/5 (0%) |
| bl-uip | 5 | 0/5 (0%) | 5/5 (100%) | 0/5 (0%) |
| **baseline overall** | 10 | **0/10 (0%)** | **10/10 (100%)** | **0/10 (0%)** |

**Baseline read in one line:** without the Evidence slot the reps never emit a labeled
Evidence element (S1 = 0/10), yet every rep still runs a real probe of the cited source
(S2 = 10/10) and catches the planted-false claim (MISSED = 0/10). The prose verification
rule alone was sufficient to catch the claim in all 10 baseline reps.
