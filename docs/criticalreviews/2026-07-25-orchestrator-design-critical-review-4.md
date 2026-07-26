# Critical Design Review: 2026-07-25-orchestrator-design (Round 4)

**Spec:** `~/peters-toolkit/docs/specs/2026-07-25-orchestrator-design.md`
**Verified Assumptions section:** present

_Round 4. Coverage re-derived from scratch. Prior findings F1 (round 1), F2 (round 2), and F3 (round 3) are all resolved in the current spec and are not re-raised (see §4). This round confirms the F3 fix landed completely (no residual "git-ignored" / "never ships" self-references remain) and surfaces no new findings._

## 1. Verified-assumptions cross-check

Fresh read of the 13 assumptions (A1–A13, §16):

1. **A1 — skill invocation + args + skills-invoking-skills.** Still holds.
2. **A2 — all 15 delegated skills exist.** Still holds (8/8 superpowers, 7/7 toolkit).
3. **A3 — chain-skills hard-gate against auto-chaining.** Still holds — consistent with the review-loop model (orchestrator re-invokes each hard-gating skill).
4. **A4 — adapter contract as documented.** Still holds.
5. **A5 — orchestrator can locate the adapter.** Still holds.
6. **A6 — `git branch --list` glob incl. worktrees.** Still holds (proven live, round 1).
7. **A7 — artifact naming carries the id.** Still holds.
8. **A8 — `node:test` + `.mjs` ESM.** Still holds (Node v24.18.0).
9. **A9 — `.gitignore` recursion + no collision.** Still holds — the per-skill `docs/` policy change touched only the `docs/` block; the skills-whitelist block is unchanged and no `bugfix` skill exists yet.
10. **A10 — `run-tests.sh` stays green.** Still holds.
11. **A11 — Umbraco harness values.** Still holds (with the recorded artifact-dir correction).
12. **A12 — pipeline is test-stack-agnostic.** Still holds.
13. **A13 — umbrella is an editable working spec.** Still holds; the spec body (line 9, O10) now matches A13's git-tracked reality — the F3 inconsistency is resolved.

All 13 verified assumptions reconfirmed.

## 2. Literal-wrongness findings

No literal-wrongness findings.

## 3. Forced decisions

No forced decisions found.

## 4. Previously addressed

- **F1 (Round 1)** — picker promised a per-bug stage the offline `status.mjs` couldn't compute for trivial bugs. Resolved: §3/§4.1 show a coarse **phase**, narrowed by ticket work-log + human confirm at selection.
- **F2 (Round 2)** — Stages 4/5 placed a mandatory update step after an optional review. Resolved (and refined per the author's clarified model): §5/§6 express a mandatory review-until-green loop (`CDR ⇄ UDD` / `CIR ⇄ UIP`) inside an optional stage.
- **F3 (Round 3)** — the spec described itself as a git-ignored, never-shipping working file (header, O10), contradicting A13 and its now-published status. Resolved: line 9 and O10 now state the spec is git-tracked and published under the per-skill `docs/` policy (O10's doc-split decision retained with a corrected rationale); §19 step 5's completed umbrella-update step was dropped; the status line was updated. Verified this round: no residual `git-ignored` / `never ships` / `Optionally update the umbrella` strings remain.

## 5. Recommendation

✅ **Approve as-is.** §1 reconfirms all 13 verified assumptions; §2 and §3 are both empty. The three findings raised across rounds 1–3 are all resolved, and the round-3 fix (F3) landed with no residual inconsistency. The spec is ready for implementation planning (`thorough-writing-plans`).
