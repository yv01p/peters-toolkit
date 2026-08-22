# Review finding — ranking output contract

**Finding:** `rank_candidate(candidate)` (design spec §2.4) needs to report
WHY a candidate got its tier, not just the score and tier — the review found
no visibility into ranking rationale.

**Old §2.4 text:** "`rank_candidate(candidate)` returns
`(score: float, tier: str)` — a 2-tuple. Downstream code destructures
`score, tier = rank_candidate(c)`."

**New §2.4 text (the fix, already applied in `spec.md`):**
"`rank_candidate(candidate)` returns
`(score: float, tier: str, reason_code: str)` — a 3-tuple. Downstream code
destructures `score, tier, reason_code = rank_candidate(c)`."

You are the "applier" in a design-doc update workflow. Before finalizing, you
must find every other place in the spec (`spec.md` and any files it
references) that also needs updating to stay consistent with this fix.
