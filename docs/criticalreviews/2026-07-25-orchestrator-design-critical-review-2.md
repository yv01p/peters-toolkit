# Critical Design Review: 2026-07-25-orchestrator-design (Round 2)

**Spec:** `~/peters-toolkit/docs/specs/2026-07-25-orchestrator-design.md`
**Verified Assumptions section:** present

_No commit-drift note: the spec is a git-ignored working file (no SHA to diff). Round 1's finding F1 was applied via `update-design-doc` (a `.pre-update.bak` snapshot exists). Coverage was re-derived from scratch this round per the iterative-review discipline; F1 is not re-raised (it appears in §4)._

## 1. Verified-assumptions cross-check

Fresh read of the 13 assumptions (A1–A13, spec §16). Round 1's fix touched only §3 (picker) and §4.1 (phase wording); it invalidated no assumption's cited evidence.

1. **A1 — skill invocation + args + skills-invoking-skills.** Still holds.
2. **A2 — all 15 delegated skills exist.** Still holds (8/8 superpowers, 7/7 toolkit).
3. **A3 — chain-skills hard-gate against auto-chaining.** Still holds.
4. **A4 — adapter contract as documented.** Still holds (all six verbs dispatched).
5. **A5 — orchestrator can locate the adapter.** Still holds (same-plugin siblings; base-dir-relative resolution).
6. **A6 — `git branch --list` glob incl. worktrees.** Still holds (proven live round 1).
7. **A7 — artifact naming carries the id.** Still holds (TB/TWP topic is orchestrator-controlled).
8. **A8 — `node:test` + `.mjs` ESM.** Still holds (Node v24.18.0).
9. **A9 — `.gitignore` recursion + no collision.** Still holds.
10. **A10 — `run-tests.sh` stays green.** Still holds.
11. **A11 — Umbraco harness values.** Still holds (with the spec's recorded artifact-dir correction).
12. **A12 — pipeline is test-stack-agnostic.** Still holds.
13. **A13 — umbrella is a git-ignored working file.** Still holds.

All 13 verified assumptions reconfirmed.

## 2. Literal-wrongness findings

### F2 — Stage 4 and Stage 5 place the *mandatory* update step (`UDD` / `UIP`) after an *optional* review (`CDR` / `CIR`), but the update step consumes the review's output — so the review-skipped path cannot execute the update step.

**Description.** The design-only and full tiers define Stage 4 as `TB → CDR? → UDD` and the full tier defines Stage 5 as `TWP → CIR? → UIP` (§5 table lines 124–125; §6 stage rows lines 141–142). The `?` marks `critical-design-review` / `critical-implementation-review` as **optional**, but `update-design-doc` / `update-implementation-plan` follow **unconditionally**. However, `update-design-doc` **requires a CDR v2 review file as its input** (its input contract: "Invoked with one or more paths to CDR v2 review files… If not provided in the invocation, ask the user"), and `update-implementation-plan` likewise requires a CIR review file. When the optional review is **skipped** — a normal, intended path (many design-only fixes won't warrant adversarial review) — there is no review file, so the update step has nothing to consume and cannot run.

**Evidence.**
- §5 line 124 (design-only): `TB → CDR? → UDD`; line 125 (full): `TB → CDR? → UDD` and `TWP → CIR? → UIP`.
- §6 line 141 (Stage 4): `thorough-brainstorming → *(optional)* critical-design-review → update-design-doc`.
- §6 line 142 (Stage 5): `thorough-writing-plans → *(optional)* critical-implementation-review → update-implementation-plan`.
- `update-design-doc` input contract (run-confirmed this session — UDD was just invoked and required a CDR review path): consumes CDR v2 review file(s). UDD's "empty input is valid" means *a review that found nothing*, **not** "no review file at all" — with zero review files it asks the user for one, and on the CDR-skipped path none exists.
- The spec's own §5 note (line 127) already states the intended semantics — "`UDD`/`UIP` **apply the findings**" — which implies they run only when a review produced findings. The operational chains (§6 rows, which become the playbook) contradict that note by placing the update step unconditionally.

**Why this is literal-wrongness.** A builder encoding the §6 Stage 4/5 rows verbatim gets an impossible sequence on the review-skipped path: after `thorough-brainstorming`, the playbook says "→ update-design-doc," but UDD has no review to consume and stalls (asks for a nonexistent file). The only way to make the literal chain runnable is to make CDR/CIR *mandatory* — which contradicts the `(optional)` marker and the tier design (design-only fixes are exactly the ones that often skip adversarial review). Either reading breaks an asked-for path.

**Proposed fix.** Express the review-and-apply as an **optional pair**, matching the §5 note's stated intent:
- §5 table: `TB → CDR? → UDD` → `TB → [CDR → UDD]?` (design-only, full); `TWP → CIR? → UIP` → `TWP → [CIR → UIP]?` (full).
- §6 Stage 4 row: "`thorough-brainstorming` → *(optional pair)* `critical-design-review` → `update-design-doc`" — and state that `update-design-doc` runs **only if** `critical-design-review` ran (it no-ops when the review found nothing).
- §6 Stage 5 row: the same for `thorough-writing-plans` → `critical-implementation-review` → `update-implementation-plan`.
- Optionally tighten the §5 note to say explicitly: "skip the review → skip its update; run the review → run its update (a no-op if the review is empty)."

(This is one finding with two instances — the Stage 4 CDR/UDD pair and the Stage 5 CIR/UIP pair share the identical failure shape.)

## 3. Forced decisions

No forced decisions found.

## 4. Previously addressed

- **F1 (Round 1) — picker promised a per-bug stage the offline `status.mjs` signal set couldn't compute (broke for the most common, trivial tier).** Resolved: §3 now shows a coarse **phase** (`branch cut` / `design done` / `plan done`); §4.1's rule table is relabeled `→ phase (offline)`; the new "Phase vs stage" note (§4.1) is honest that the offline set can't distinguish Stages 6–9 and that a trivial bug stays `branch cut` for its whole life, with precision coming from work-log-plus-human-confirm at selection time. §3 and §4.1 no longer contradict each other.

## 5. Recommendation

⚠️ **Approve with literal-wrongness fixes.** §1 reconfirms all 13 verified assumptions; §3 is empty; §4 records F1 as resolved. The single new finding (F2) is an internal contradiction between the optional-review markers and the unconditional update steps in the Stage 4/5 chains — it must be resolved (a small notation fix that aligns the operational chains with the spec's own §5 note) before the spec goes to planning, because a builder following §6 verbatim would encode an unrunnable step on the review-skipped path.
