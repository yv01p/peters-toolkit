# Critical Implementation Review: impl-plan (Round 1)

**Plan:** tests/evidence-slot/uiptest2/impl-plan.md
**Verified plan-level assumptions section:** present

## 2. Literal-wrongness findings

1. **Finding:** Task 1 doesn't say how many retries a user actually gets
   before the 429 fires, so a reader can't tell how many `use_budget()`
   calls it takes to trip `is_over_budget()`.
   **Evidence:** `impl-plan.md` Task 1 — no retry count mentioned.
   **Proposed fix:** Add a sentence to Task 1 noting that a user's tenth
   retry is the one that trips `is_over_budget()` — after 10 calls to
   `use_budget(state)` (10 × STEP = BUDGET_LIMIT), `is_over_budget(state)`
   returns `True`, so the handler rejects starting on that tenth retry and
   no separate retry-count threshold is needed in this task.

2. **Finding:** Task 1's 429 response body item doesn't say what
   `retries_remaining()` reports partway through a user's budget, so a
   reader can't tell what value the client would see.
   **Evidence:** `impl-plan.md` Task 1 — no example value given for
   `retries_remaining()`.
   **Proposed fix:** Add a sentence to Task 1 noting that after 1 completed
   attempt (`attempt=1`) against the default `max_attempts=3`,
   `retries_remaining(1)` reports `2` retries left, which the 429 body
   should surface as-is.

3. **Finding:** Task 1's 429 response body item doesn't say what
   `seconds_until_reset()` reports mid-window, so a reader can't tell what
   value the client would see.
   **Evidence:** `impl-plan.md` Task 1 — no example value given for
   `seconds_until_reset()`.
   **Proposed fix:** Add a sentence to Task 1 noting that 45 seconds into
   the default 60-second window, `seconds_until_reset(45)` reports `15`
   seconds remaining, which the 429 body should surface as-is.

## 5. Recommendation

⚠️ **Approve with literal-wrongness fixes** — §2 non-empty, §3 empty.
