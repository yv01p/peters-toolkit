# Critical Design Review: 2026-07-25-orchestrator-design (Round 3)

**Spec:** `~/peters-toolkit/docs/specs/2026-07-25-orchestrator-design.md`
**Verified Assumptions section:** present

_Round 3. Coverage re-derived from scratch. Prior findings F1 (round 1 — picker phase) and F2 (round 2 — review-loop notation) are both resolved in the current spec and are not re-raised (see §4). One new finding (F3) surfaces this round: two same-session changes — the per-skill `docs/` publishing policy and the umbrella being brought to three tiers + the review loop — invalidated several of the spec's self-references._

## 1. Verified-assumptions cross-check

Fresh read of the 13 assumptions (A1–A13, §16):

1. **A1 — skill invocation + args + skills-invoking-skills.** Still holds.
2. **A2 — all 15 delegated skills exist.** Still holds (8/8 superpowers, 7/7 toolkit).
3. **A3 — chain-skills hard-gate against auto-chaining.** Still holds — reinforced by the corrected review-loop model, which is the orchestrator re-invoking each hard-gating skill, not the skills auto-chaining.
4. **A4 — adapter contract as documented.** Still holds (six verbs dispatched).
5. **A5 — orchestrator can locate the adapter.** Still holds (same-plugin siblings; base-dir-relative resolution).
6. **A6 — `git branch --list` glob incl. worktrees.** Still holds (proven live, round 1).
7. **A7 — artifact naming carries the id.** Still holds.
8. **A8 — `node:test` + `.mjs` ESM.** Still holds (Node v24.18.0).
9. **A9 — `.gitignore` recursion + no collision.** Still holds. The `docs/` publishing policy changed this session, but it touched only the `docs/` block; the skills-whitelist block (where `!/skills/bugfix/` will slot) is unchanged, and no `bugfix` skill exists yet.
10. **A10 — `run-tests.sh` stays green.** Still holds — the version-lockstep and companion-provenance checks read version markers / a fixed manifest, neither of which the `.gitignore` change or a new skill touches.
11. **A11 — Umbraco harness values.** Still holds (with the recorded artifact-dir correction).
12. **A12 — pipeline is test-stack-agnostic.** Still holds.
13. **A13 — umbrella is an editable working spec.** Holds, and was **rewritten this session**: the umbrella is now git-tracked (per the per-skill `docs/` publishing policy) and was committed (`235fb3b`); it remains editable, as this session's own edits prove. The load-bearing claim (editable) holds; the evidence was corrected from the now-false "git-ignored." (The same git-tracked reality is *not yet* reflected in the spec body — see F3.)

All 13 verified assumptions reconfirmed.

## 2. Literal-wrongness findings

### F3 — The spec's self-description is now false and internally contradictory: it declares itself a git-ignored, never-shipping working file (header + O10), but this session's per-skill `docs/` publishing policy makes it git-tracked and published — which A13 itself now states.

**Description.** Between round 2 and now, two same-session changes altered facts the spec asserts about itself: (1) the per-skill `docs/` publishing policy made this spec git-tracked and published, and (2) the umbrella was brought to three tiers + the review loop. Several self-references were not updated to match, leaving the spec asserting contradictory facts about its own storage/shipping status and listing an already-completed step as pending. Because the spec is now itself a *published* artifact, cloners read these contradictions directly.

**Evidence.**
- **Header, line 9:** `**Storage:** Git-ignored working file (the toolkit repo tracks only shippable plugin files).` — false: the spec is git-tracked (committed `b492b33`, `271ef75`) and published (its filename matches the `!/docs/**/*orchestrator*` whitelist).
- **O10, line 53:** `The design spec (this file, in docs/specs/, git-ignored) is the deep decisions record for the team.` … `so an installer can customize safely without ever seeing this spec.` Rationale: `The spec never ships (repo tracks only plugin files).` — false on both counts now; installers and cloners **can** see the spec.
- **A13, §16 line 324** (rewritten this session) states the opposite — "Now git-tracked … not ignored." So the body (line 9, O10) and §16 (A13) now contradict each other.
- **§19 step 5, line 351:** `Optionally update the umbrella spec for the three-tier refinement (§15).` — already done this session (umbrella `235fb3b` carries three tiers + the review loop), and directly contradicts §15's current text: "that refinement has since been folded into the umbrella … no divergence remains."
- **Header, line 8:** `**Status:** Design drafted (pending critical-design-review).` — stale; CDR has now run three times. (Minor instance.)

**Why this is literal-wrongness.** The spec asserts contradictory facts about itself (git-ignored vs. git-tracked; umbrella update pending vs. done). This is more than cosmetic: **O10 is a locked decision** whose stated rationale — "the spec never ships, so build a condensed `customizing.md` so installers never see the spec" — is now false, so a builder consulting O10 to size `customizing.md` acts on an invalid premise. And the contradiction lives in a now-published document.

**Proposed fix.** (One finding, several instances — same root: self-references invalidated by this session's two changes.)
- **Line 9:** replace "Git-ignored working file (…tracks only shippable plugin files)" with the current reality — the spec is git-tracked and published under the per-skill `docs/` policy (only the bug-fixing skill's artifacts publish; other skills stay private).
- **O10:** keep the documentation-split *decision* (deep team record vs. condensed installer `customizing.md`); rewrite the *rationale* — the spec now ships, so `customizing.md`'s justification is "a focused installer doc rather than the full decisions record (which is also published for those who want the depth)," not "installers never see the spec."
- **§19 step 5:** mark the umbrella update done (or drop the step), consistent with §15.
- **Line 8:** update the status to reflect the design has been through CDR (round 3).

## 3. Forced decisions

No forced decisions found.

## 4. Previously addressed

- **F1 (Round 1)** — the `/bugfix` picker promised a per-bug *stage* the offline `status.mjs` signal set couldn't compute for trivial bugs. Resolved: §3/§4.1 show a coarse **phase**, narrowed to the exact stage by the ticket work-log plus human confirm at selection time.
- **F2 (Round 2)** — Stages 4/5 placed a *mandatory* update step after an *optional* review. Resolved, and corrected further this session per the author's clarified model: §5/§6 now express a **mandatory review-until-green loop** (`CDR ⇄ UDD` / `CIR ⇄ UIP`) *inside* an optional stage (the tier selects whether `TB`/`TWP` run).

## 5. Recommendation

⚠️ **Approve with literal-wrongness fixes.** §1 reconfirms all 13 assumptions; §3 is empty. The single finding (F3) is a set of self-references invalidated by this session's own changes (the per-skill `docs/` publishing policy and the umbrella alignment) — including a locked decision (O10) whose stated rationale is now false. Reconcile them before the spec goes to planning; the fixes are localized prose corrections.
