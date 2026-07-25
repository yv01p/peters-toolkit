# Critical Design Review: 2026-07-25-bug-fixing-workflow-design (Round 1)

**Spec:** `~/peters-toolkit/docs/specs/2026-07-25-bug-fixing-workflow-design.md`
**Verified Assumptions section:** present

## 0. Coverage enumeration

**Sections**

| Row | Disposition |
|-----|-------------|
| §1 Purpose & scope | ok — scope bounds (define workflow, defer implementation, no dial, no monitoring, no context input) internally consistent with §2 decisions |
| §2 Decisions D1–D10 | ok — each decision maps to a downstream section; D9 (subagent-driven-development, never executing-plans) consistent with §3.1/§3.2/§6 |
| §3.1 Stage pipeline | → §2.1 (test-before-isolation ordering) |
| §3.2 Two paths | → §2.1 (both paths sequence stage 3 before stage 6) |
| §3.3 Gates | ok — G1/G2/G8 (+G4/G5) consistent across 3.1/3.2/3.3 |
| §3.4 systematic-debugging relationship | ok — design scopes systematic-debugging to investigation-through-root-cause and delegates Phase-4 work to TDD/subagent-dd/verification; the "how to stop mid-skill" is implementation, and the gate intent is resolved at design level (not a finding) |
| §4 Bug-info contract | ok — three tiers; required-to-proceed doubles as needs-info checklist |
| §4.1 Needs-info loop | ok — re-entry at Stage 2 is manual (dev re-runs); no automation claimed |
| §5 Tracker adapter contract | → §3.1 (setStatus 4-value vocabulary vs GitHub model) |
| §6 Build vs reuse | ok — new surface = adapter + orchestrator; cross-plugin dependency on superpowers + toolkit stated |
| §7 Harness configuration | → §3.1 (status model row); other rows ok against cited sources |
| §8 Worked examples | ok — trivial/non-trivial traces match §3.2; note trivial example "6 worktree + direct fix" corroborates §2.1 |
| §9 Verified assumptions | → §1 cross-check |
| §10 Generic/harness boundary | ok — boundary rule ("only-ever-true-for-Umbraco → harness config") consistent with §7 |
| §11 Path to autonomy | ok — explicitly future, nothing built; no dependency introduced |
| §12 Next steps | ok — sequencing (adapter → orchestrator → exercise) coherent |

**Rules and operands**

| Rule | Both directions checked | Disposition |
|------|-------------------------|-------------|
| R1 Trivial/non-trivial classification (G1) | over-ceremony (trivial→full: wasteful, not wrong) / under-ceremony (non-trivial→trivial: skips options+plan+adversarial). Human-confirmed at G1, root cause still gated at G2, diff still reviewed at G8. | dropped — misclassification degrades quality but does not make the asked-for outcome (a verified fix) literally wrong; human owns the call |
| R2 Needs-info trigger (required-to-proceed missing) | false-proceed (missing repro: blocked anyway by systematic-debugging's reproduce-or-gather) / false-ask (asks for obvious "expected": annoyance) | dropped — neither direction breaks the outcome |
| R3 setStatus vocabulary → provider mapping | over: writes a status the provider can't represent → silent no-op / under: a workflow status has no target | → §3.1 |
| R4 Close-on-merge via native PR linkage | GitHub keyword `Fixes #ID` closes issue on merge | ok — verified as CLAUDE.md convention; provider emits keyword; 'done' == closed is representable |

**Data-flow arrows**

| Arrow (→ operation) | Parameter/artifact check | Disposition |
|---------------------|--------------------------|-------------|
| Stage 4 `thorough-brainstorming` → Stage 5 `thorough-writing-plans` | 5 requires a thorough-brainstorming spec (strict input contract); 4 produces exactly that | ok — required input produced upstream on the non-trivial path |
| Stage 4 optional CDR → `update-design-doc` | CDR v2 output consumed by update-design-doc; revised spec still valid input to 5 | ok |
| Stage 5 → Stage 6 `subagent-driven-development` | consumes the plan from 5 (non-trivial only) | ok |
| Stage 3 `test-driven-development` (writes+runs failing test) vs Stage 6 `using-git-worktrees` (creates the branch) | **persistence/isolation boundary**: test authored in main tree before the worktree exists; worktree branches from base | → §2.1 |
| Stage 8 `critical-security-review` / `umb-review` / `requesting-code-review` | each requires the changed code / branch, which exists after 6–7 | ok |
| Stage 9 `finishing-a-development-branch` → adapter `linkPullRequest` | finish creates the PR; adapter needs the PR URL to link back | ok at design level (URL capture is implementation) |
| Stage 0 adapter `getTicket` / `setStatus('in-progress')` | id + writeback guaranteed; 'in-progress' target on GitHub | → §3.1 |

## 1. Verified-assumptions cross-check

- "All delegated skills exist" — **reconfirmed.** superpowers set (incl. `subagent-driven-development`, `requesting-code-review`, `receiving-code-review`) present under the superpowers plugin; toolkit set present in `~/peters-toolkit/skills/`; `umb-review` in the Umbraco harness only.
- "`subagent-driven-development` executes plans; `thorough-writing-plans` points to it" — **reconfirmed.** Skill description: "Use when executing implementation plans with independent tasks"; thorough-writing-plans HARD-GATE names it.
- "Peter's Toolkit chain holds" — **reconfirmed** against the skills' frontmatter/input contracts.
- "`systematic-debugging` scope" — **reconfirmed.**
- "Toolkit repo layout / .gitignore denylist" — **reconfirmed.**
- "No collision" — **reconfirmed.**
- "Umbraco harness config" (§7) — **holds with one narrowing:** the status-model row is verified only for `needs-info` → `state/needs-investigation`. A fresh grep of all of `Umbraco-CMS/.github/` returns exactly one `state/*` label (`state/needs-investigation`). The other three setStatus values (`in-progress`, `in-review`, `done`) have no verified GitHub representation.

**Span check.** One uncovered dependency: the design's `setStatus` contract (§5) defines a four-value vocabulary and makes the GitHub provider the reference implementation the first harness runs against (§7), so the workflow will call `setStatus('in-progress')` at Stage 0 and `setStatus('in-review')` at Stage 9 on day one. No verified assumption covers how GitHub represents `in-progress` or `in-review` (`done` maps to issue-closed via R4; `needs-info` is covered). This is not verifiable as a plain fact — it is a choice the GitHub model forces → surfaced as §3.1.

## 2. Literal-wrongness findings

### §2.1 — Failing test is authored before workspace isolation, so it lands outside the fix branch

**Description.** Both paths sequence Stage 3 (**failing test first**, delegating to `test-driven-development`, which writes *and runs* a failing test) before Stage 6 (**isolate & implement**, which is where `using-git-worktrees` creates the branch): trivial `2 → 3 → 6`, non-trivial `3 → 4 → 5 → 6` (§3.2), and the §8 trivial example spells it out as "`6` worktree + direct fix." A git worktree has its own working directory and branches from base; an uncommitted file created in the main working tree at Stage 3 is not present in a worktree created at Stage 6. The regression test therefore lives in the main tree, while the fix is committed on the worktree's branch — which is the branch `finishing-a-development-branch` turns into the PR at Stage 9. The PR would contain the fix without its failing test, directly contradicting the workflow's stated outcome (the failing-test-first discipline in §3.1/Stage 3 and the "test + fix in one PR" shape in §8).

**Evidence.** Spec §3.2 (both path orderings) and §8 (trivial example "6 worktree + direct fix"); `using-git-worktrees` creates an isolated working directory branched from base; `test-driven-development` (Stage 3) authors the test in whatever working tree is current at Stage 3 (the main tree, since no worktree exists yet).

**Proposed fix.** Move workspace isolation ahead of the failing test: create the worktree/branch as the first action of hands-on work — immediately after G2 root-cause sign-off and before Stage 3 — so Stages 3, 6 and 7 all execute inside the worktree. (Reorder the pipeline so `using-git-worktrees` precedes `test-driven-development`; the trivial path becomes `2 → isolate → 3 → 6 → 7 → …` and the non-trivial path isolates before Stage 3 as well. Whether the Stage 4/5 design and plan artifacts are authored inside or outside the worktree is a separate, non-load-bearing choice.)

## 3. Forced decisions

### §3.1 — How does the GitHub reference provider represent `in-progress` and `in-review`?

**The choice.** The `setStatus` vocabulary is `{in-progress, needs-info, in-review, done}` (§5). For the GitHub reference provider: `needs-info → state/needs-investigation` (verified) and `done → issue closed` on merge (R4). `in-progress` (set at Stage 0) and `in-review` (set at Stage 9) have no defined GitHub representation, and a grep of `Umbraco-CMS/.github/` finds no matching `state/*` label.

**Why it's forced.** GitHub issues have no native status field — only open/closed plus labels or Projects. The design commits to setting `in-progress`/`in-review` on the first harness (§7), so a representation must be picked; it cannot be left to "provider config" in the abstract because the reference provider is the one that runs. The GitHub model forces the choice.

**The options.** (a) Define dedicated labels (e.g. `state/in-progress`, `state/in-review`) and add them to the harness repo; (b) drive a GitHub Projects status column instead of labels; (c) narrow the workflow's status vocabulary for the GitHub provider so these two transitions become no-ops (assignment alone signals "in progress"; the open PR link signals "in review"), and document that only `needs-info` and `done` are represented on GitHub. The reviewer surfaces the choice; the user picks.

## 5. Recommendation

🛑 **Surface forced decisions to user** — §3 is non-empty (regardless of §2). Resolve §3.1 (GitHub status representation) and apply the §2.1 reordering (isolate before the failing test) before this definition is turned into skills. Both are small, localized edits to the spec; neither reshapes the pipeline.
