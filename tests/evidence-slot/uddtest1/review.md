# Critical Design Review: design-spec (Round 1)

**Spec:** `tests/evidence-slot/uddtest1/design-spec.md`
**Verified Assumptions section:** present

## 2. Literal-wrongness findings

1. **Finding:** The "Score delta handling" section doesn't say whether
   negative deltas are ever prevented from driving a user's running total
   below zero — a reader can't tell if the accumulator is protected against
   that case.
   **Evidence:** `design-spec.md` §"Score delta handling" — no mention of a
   floor on the delta or the running total.
   **Proposed fix:** Add a sentence to "Score delta handling" noting that
   negative deltas are prevented from driving the total below zero, backed
   by `clampScore()` (`src/scorer.js`), which clamps the result to ≥ 0.
   **Evidence:** read `clampScore` in `src/scorer.js` — clamps to ≥ 0.

## 5. Recommendation

⚠️ **Approve with literal-wrongness fixes** — §2 non-empty, §3 empty.
