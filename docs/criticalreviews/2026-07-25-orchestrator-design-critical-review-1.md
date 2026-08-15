# Critical Design Review: 2026-07-25-orchestrator-design (Round 1)

**Spec:** `~/peters-toolkit/docs/specs/2026-07-25-orchestrator-design.md`
**Verified Assumptions section:** present

## 1. Verified-assumptions cross-check

Fresh read of the cited evidence for each of the 13 assumptions (A1–A13, spec §16):

1. **A1 — skill invocation + args + skills-invoking-skills.** Still holds. The Skill tool exposes `args`; the harness maps `/<skill-name>` → Skill; `thorough-writing-plans` names `subagent-driven-development` as a REQUIRED SUB-SKILL; skills are invoked with a harness-provided base directory (observed at this session's `thorough-brainstorming` invocation).
2. **A2 — all 15 delegated skills exist.** Still holds. 8/8 superpowers skills in the plugin cache; 7/7 toolkit skills in `skills/`.
3. **A3 — chain-skills hard-gate against auto-chaining.** Still holds. TB/TWP/CDR/CIR/UDD/UIP each STOP at a committed artifact and hand back (re-read of each SKILL.md's stop language).
4. **A4 — adapter contract as documented.** Still holds. `tracker-adapter:scripts/adapter.mjs` dispatches all six verbs; invocation `node scripts/adapter.mjs <provider> <verb>`.
5. **A5 — orchestrator can locate the adapter.** Still holds. No `CLAUDE_PLUGIN_ROOT` convention; skills resolve scripts relative to their harness-provided base dir. `bugfix` and `tracker-adapter` are both peters-toolkit skills → siblings wherever installed (toolkit skills confirmed flat under `~/.claude/skills/`, so `<base>/../tracker-adapter/` resolves).
6. **A6 — `git branch --list` glob incl. worktrees.** Still holds. Proven live this session (a worktree branch appeared, prefixed `+ `); offline.
7. **A7 — artifact naming carries the id.** Still holds. TB → `docs/specs/YYYY-MM-DD-<topic>-design.md`; TWP → `docs/plans/YYYY-MM-DD-<topic>-implementation-plan.md`; `<topic>` is orchestrator-controlled. (Scope note: this assumption is about *design/plan* artifacts, which are the signals §4.1 relies on — see Finding F1, which concerns tiers where those artifacts never exist.)
8. **A8 — `node:test` + `.mjs` ESM.** Still holds. Node v24.18.0; `node --test` passed.
9. **A9 — `.gitignore` recursion + no collision.** Still holds. `skills/thorough-brainstorming/scripts/**` tracked via one `!` line; no `bugfix` skill exists.
10. **A10 — `run-tests.sh` stays green.** Still holds. Lockstep checks only version markers; provenance checks a fixed manifest + a removed-token grep; a new skill touches neither.
11. **A11 — Umbraco harness values.** Still holds, with the spec's own recorded correction (only `docs/criticalreviews/` pre-exists; other artifact dirs are created on first write). version 18.2.0-rc → major 18; PR/branch/dotnet/label/umb-review all match.
12. **A12 — pipeline is test-stack-agnostic.** Still holds. TDD's core is stack-independent (jest is only its example); `verification-before-completion` runs "the project's" checks generically.
13. **A13 — umbrella is a git-ignored working file.** Still holds; editable for the O5 refinement.

All 13 verified assumptions reconfirmed.

## 2. Literal-wrongness findings

### F1 — The `/bugfix` picker's per-bug stage (§3) is not computable from `status.mjs`'s signal set (§4.1) for the most common tiers. Internal contradiction on an explicitly asked-for feature.

**Description.** The design promises a picker that shows each in-flight bug's *stage* (§3) — the feature the user explicitly requested ("easy to resume an open tix"). But `status.mjs` computes stage from exactly three offline signals: `{branch exists, design artifact exists, plan artifact exists}` (§4.1 rule table). For **trivial** bugs — per the user, the most common tier ("most bugs get quickly fixed in one step") — no design or plan artifact is *ever* produced. So the tuple `{branch:yes, design:no, plan:no}` holds for a trivial bug across its **entire** on-branch life (Stages 3→9), and the rule table pins it to a single bucket: "Stage 3 (isolated; no design yet)." The signal set also produces no new artifact after the plan is written, so it cannot distinguish Stages 6/7/8/9 in *any* tier.

**Evidence (internal contradiction, spec-only).**
- §4.1 rule table, row 1: `branch=yes, design=no, plan=no → Stage 3 (isolated; no design yet)`.
- §3 picker example: `#456  Off-by-one in pager → Stage 6 (implementing)`. An off-by-one is a trivial fix → no design/plan artifact → `status.mjs` computes **Stage 3**, not Stage 6. The picker example is not producible by the design's own mechanism.
- §3 picker example: `#123 … → Stage 5 (plan approved)`. Once the plan artifact exists (written during Stage 5), §4.1 row 3 computes **"Stage 6+ (plan done; implementing)"** — so even this line is off by the mechanism's own mapping.
- §4.1's "design present, no plan" row already needs the ticket work-log to disambiguate design-only (Stage 6) from full (Stage 5) — but the picker runs **offline across all bugs** (§4.1 step 4, O4) and does not read work-logs, so it cannot perform that disambiguation in the picker at all.

**Why this is literal-wrongness, not coarseness-to-be-tolerated.** For a trivial bug that has been fixed and verified (Stage 7) but not yet PR'd, the picker reports "Stage 3 (isolated; no design yet)" — not merely imprecise but actively misleading about a bug that is nearly done. The confirm step (§4.2) prevents a wrong *resume* once a bug is selected, but the picker's stage column — the thing that makes "just pick one" work — is wrong for the most common tier. A builder implementing §4.1 verbatim cannot produce §3's own example; the spec contradicts itself on the asked-for feature.

**Proposed fix (design choice — CDR does not pick; any one removes the contradiction, trading determinism/offline-ness against picker precision):**
- **(a) Enrich `status.mjs` with additional offline, tier-independent signals** so it can resolve Stages 3→9: e.g., parse `git log <branch>` for conventional commit markers the pipeline is made to leave (failing-test commit, fix commit) and/or a local completion marker. Keeps the picker deterministic and offline, but requires the pipeline stages to leave parseable git traces.
- **(b) Right-size the picker to what is knowable offline:** show a coarse phase (e.g., `in progress` / `design done` / `plan done`) plus id/title, and resolve the precise stage from the ticket work-log only *after* a bug is selected. Correct §3's example to match §4.1.
- **(c) Have the picker read each in-flight bug's ticket work-log** (`getTicket`) for the precise stage (the work-log records every gate). Accurate picker, but it is no longer offline (needs `gh`) and costs one `getTicket` per in-flight bug.

## 3. Forced decisions

No forced decisions found.

## 5. Recommendation

⚠️ **Approve with literal-wrongness fixes.** §1 reconfirms all 13 verified assumptions. §3 is empty. The single §2 finding (F1) is an internal contradiction between the picker's promised output (§3) and the deterministic status mechanism's signal set (§4.1), affecting the most common bug tier — it must be resolved (by picking one of the fix options, which is a design decision) before the spec goes to planning, because a builder following §4.1 verbatim would produce a picker that cannot match the spec's own §3 example.
