# Critical Design Review: design-spec (Round 1)

**Spec:** `tests/evidence-slot/uddtest2/design-spec.md`
**Verified Assumptions section:** present

## 2. Literal-wrongness findings

1. **Finding:** The "Price display handling" section doesn't say how
   `roundTo()` handles a raw price that lands exactly on a half-cent
   boundary — a reader can't tell whether such prices round up or down for
   the printed invoice.
   **Evidence:** `design-spec.md` §"Price display handling" — no mention of
   half-cent boundary behavior.
   **Proposed fix:** Add a sentence to "Price display handling" noting that
   `roundTo()` (`src/rounder.js`) correctly performs half-up rounding at the
   half-cent boundary — for example, a raw price of `1.005` is displayed as
   `1.01` — so no additional boundary handling is needed in this pipeline.
   **Evidence:** ran `roundTo(1.005, 2)` → `1.01`, confirms half-up rounding.

## 5. Recommendation

⚠️ **Approve with literal-wrongness fixes** — §2 non-empty, §3 empty.
