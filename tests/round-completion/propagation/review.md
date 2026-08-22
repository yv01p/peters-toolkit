# Critical Implementation Review: impl-plan (Round 1)

**Plan:** tests/round-completion/propagation/impl-plan.md
**Verified plan-level assumptions section:** present

## 2. Literal-wrongness findings

1. **Finding:** `rank_candidate(candidate)` (Task 3) needs to report WHY a
   candidate got its tier, not just the score and tier — there is no
   visibility into ranking rationale anywhere downstream, and support staff
   reviewing the queue have no way to see the reasoning behind a tier
   assignment.
   **Evidence:** `impl-plan.md` Task 3 — `rank_candidate()` returns only
   `(score, tier)`; no rationale field anywhere in its output or in any
   downstream consumer.
   **Proposed fix:** Change Task 3's contract so `rank_candidate(candidate)`
   returns `(score: float, tier: str, reason_code: str)` — a 3-tuple.
   Downstream code destructures `score, tier, reason_code =
   rank_candidate(c)`.

## 5. Recommendation

⚠️ **Approve with literal-wrongness fixes** — §2 non-empty, §3 empty.
