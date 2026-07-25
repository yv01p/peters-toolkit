# Bugfix Orchestrator — Design

**Date:** 2026-07-25
**Home:** Peter's Toolkit (`~/peters-toolkit`). Ships as a new toolkit skill (`bugfix`).
**Parent spec:** `docs/specs/2026-07-25-bug-fixing-workflow-design.md` (the umbrella bug-fixing workflow). This document resolves the orchestrator forks that spec deliberately left open (its §6/§12.3) and **refines** its trivial/non-trivial routing (see O5 / §17).
**Sibling spec:** `docs/specs/2026-07-25-tracker-adapter-design.md` (the tracker adapter — already built on branch `tracker-adapter`). The orchestrator consumes its invocation contract (§11).
**Test harness:** Umbraco CMS (`~/Umbraco-CMS`) — first project exercised. GitHub via `gh` CLI is the reference provider.
**Status:** Design drafted (pending `critical-design-review`). Build follows as its own plan → build cycle.
**Storage:** Git-ignored working file (the toolkit repo tracks only shippable plugin files).

---

## 1. Purpose & scope

The `bugfix` orchestrator is the **conductor** of the bug-fixing workflow — the LLM skill a developer invokes to drive one bug, locally, from pickup to a merged fix, with human gates at each stage. It sequences the stages, enforces the gates, routes by complexity tier, reads the per-project harness config, writes the ticket work-log, and **delegates every hard step** to the skills that already exist (superpowers + Peter's Toolkit) plus the tracker adapter. It re-implements none of their logic.

This spec defines the orchestrator's **form, entry/invocation, state & resumption model, complexity tiers, stage-delegation mechanism, gates, harness-config format, work-log template, adapter invocation, UI-bug handling, file layout, and extension points** — enough to plan and build the skill.

A second, explicit goal (per the user): the orchestrator is a **solid base that people customize to their own needs.** "Easy to change and improve" is a design constraint, not an afterthought (see O8 / §14).

**In scope:**

- The `bugfix` LLM skill: `SKILL.md` + `references/` + a small deterministic `status.mjs` script + tests.
- The invocation model (`/bugfix [id]`), the resume/picker behaviour, and the deterministic status script.
- The three complexity tiers and the routing that selects them.
- The stage-by-stage delegation to existing skills and the tracker adapter, and the human gates.
- The harness-config file format + an annotated Umbraco example.
- The ticket work-log template.
- The extension points and the shipped customization docs.

**Out of scope (deliberately):**

- Building or modifying the delegated skills or the tracker adapter (each has its own home). One **one-line adapter-docs clarification** is folded in as a follow-up (§19), not built here.
- `listCandidates` / any tracker-side "list my in-flight bugs" query — deferred with the adapter (§20).
- An autonomy dial — the gates are the future dial (umbrella D2/§11); we build only the fully-gated manual version.
- Browser-automation tooling for UI bugs — a documented seam, not built (§12, §20).

---

## 2. Decisions (locked, with rationale)

| # | Decision | Rationale |
|---|----------|-----------|
| O1 | **LLM orchestrator skill (a conductor), not a script.** The skill is a playbook the developer runs; it sequences stages, enforces gates, routes tiers, and calls sub-skills + the adapter. | The orchestrator's job is judgment and coordination — the opposite of the adapter's mechanical I/O. Mechanical sub-parts (resume/status) become small scripts (O3); the conducting stays LLM. (Umbrella D5.) |
| O2 | **Dedicated harness-config file** (`.claude/bugfix.harness.md`) in the target repo; the orchestrator reads it and **echoes the resolved config at G1 for human confirmation.** | Deterministic, amortized across runs, self-documenting. Resolves the umbrella's open fork (§12.3). Chosen over per-project inference (brittle to parse from prose) and interactive prompting (repetitive every run). The G1 confirm catches drift. |
| O3 | **Resume/position is a deterministic Node script** (`status.mjs`), offline (git + filesystem), **not LLM inference.** | "Which stage is bug #123 at" is mechanical fact-gathering + a fixed rule table — plumbing, not judgment (same principle as the adapter, TA1). It is load-bearing (a wrong resume redoes work or skips a gate) and unit-testable against fixtures. |
| O4 | **The `/bugfix` picker is scoped to branch-cut bugs (Stage 3+).** Early/needs-info bugs (pre-branch) are resumed by explicit id; the orchestrator then reads the ticket work-log (`getTicket`) for context. | The offline git/fs script can only see work that has a local footprint, which begins when the branch is cut at Stage 3. Listing pre-branch bugs would require a tracker query = the deferred `listCandidates`. YAGNI: early bugs are short-lived / resumed from a ticket notification by id. |
| O5 | **Three complexity tiers — `trivial` / `design-only` / `full` — refining the umbrella's two-path model (D3/§3.2).** | Design-effort and planning-effort are **independent dials**, not one switch. The "design ON, plan OFF" combination (real brainstorming, then a localized TDD fix with no formal plan) is common and the umbrella forgot it. The fourth combination (plan without design) is dropped — YAGNI, it never occurs. |
| O6 | **`systematic-debugging` is the shared investigation spine (Stage 2) across all tiers; G2 (root-cause sign-off) is the common fork.** | Every bug is investigated the same way to root cause. Trivial resumes straight into the fix (systematic-debugging's own continuation via TDD + verification); design-only/full detour through design (and, for full, a plan) before the fix. One spine, one fork, three tails. |
| O7 | **UI / non-code bugs use the *same* pipeline; the base is test-stack-agnostic.** The reproduction/verification method is a seam (`repro_verify`): automated tests by default; browser/E2E/manual variants. **Manual fallback** when no automated UI-test path exists — recorded in the work-log, regression protection flagged manual. | A UI bug isn't a different pipeline — it's the same stages with a different test stack and reproduction surface. `systematic-debugging`, `test-driven-development`, and `verification-before-completion` are all framework-agnostic (verified A12). Hard-coding browser tooling would violate the customizable-base goal (O8). |
| O8 | **"Solid, customizable base" is a first-class design goal.** Lean core; named + documented seams; decisions recorded with rationale; customize-by-editing (markdown + config), **no plugin/hook framework.** | Every feature in the base is something a customizer must understand and work around, so ruthless YAGNI keeps it forkable. A formal extensibility framework would itself violate the goal. |
| O9 | **The orchestrator invokes the adapter by absolute path** — resolved from its harness-provided skill base directory → sibling `../tracker-adapter/scripts/adapter.mjs` — **while cwd = the target repo.** | `gh` infers the repo from cwd, so the adapter must run cwd'd in the target repo; a relative `node scripts/adapter.mjs` cannot resolve from there. Both skills ship in the same plugin, so they are siblings wherever installed (verified A5). |
| O10 | **Documentation split.** The design spec (this file, in `docs/specs/`, git-ignored) is the deep decisions record *for the team*. The **shipped skill** carries its own condensed `references/customizing.md` with the essential "why," so an installer can customize safely without ever seeing this spec. | The spec never ships (repo tracks only plugin files). The user's requirement — "good documentation about the decisions and the basic functionality of `/bugfix`" — is met on both sides of that boundary. |
| O11 | **Status is advisory; `done` closes via the PR closing keyword, not a label** (inherited from adapter TA6 / umbrella D11). The harness `status_labels` map lists only statuses with a native label. | Consistency with the adapter's built behaviour; the orchestrator holds the label *names* (harness config), the adapter holds the mechanism. |

---

## 3. Entry & invocation

The skill is invoked as a slash command (the harness maps `/<skill-name>` → the Skill tool), with an optional bug id argument.

- **`/bugfix <id>`** — start a new bug at that id, or resume it if work already exists. On resume, the orchestrator runs `status.mjs` for that id, states the resume point, and asks the human to confirm before continuing.
- **`/bugfix`** (no id) — run `status.mjs` across all in-flight (branch-cut) bugs and present a **picker**: each bug's id, title, and computed **phase** (the coarse, offline-computable position — see §4.1). The human picks one; the orchestrator then narrows the resume point from that bug's ticket work-log and confirms it. Or supply a new id to start.

Example picker:

```
You have 3 bugs in progress:
  #123  Cache not invalidating    → plan done (in progress)
  #456  Off-by-one in pager       → branch cut (in progress)
  #789  Login redirect loop       → branch cut (in progress)

Pick one to resume — I'll narrow the exact spot from the ticket work-log and confirm with you.
Or give me a new ticket number to start.
```

The developer is always cd'd into the target repo; the orchestrator and the adapter both operate on that cwd (matching the adapter's TA4).

---

## 4. State & resumption model

**Each bug carries its own state, on its own turf** — a git branch, its design/plan artifacts, and a work-log on its own ticket. Nothing is shared between concurrent bugs, so any number can be in flight at once without collision. There is **no separate state store**; a state file would be a second copy of the truth that drifts. This realizes the umbrella's "the ticket is the work-log."

### 4.1 `status.mjs` (deterministic, offline)

A small Node script — the mechanical half of resumption. Given the branch glob and artifact directories (passed as CLI args by the orchestrator, which read them from the harness config), it:

1. Lists in-flight bugfix branches via `git branch --list '<glob>'` and parses the id from each branch name. (Branches checked out in worktrees created by `using-git-worktrees` are included — verified live, A6. Note: `git branch --list` prefixes worktree branches with `+ ` and the current branch with `* `; the script strips these.)
2. Checks whether each bug's design/plan artifacts exist in the configured dirs (matched by id in the filename).
3. Applies a fixed rule table to compute a coarse **phase** (not a precise stage — see the note below):

   | branch? | design artifact? | plan artifact? | → phase (offline) |
   |---|---|---|---|
   | yes | no | no | `branch cut` — Stage 3+ (no design/plan artifact; covers a trivial bug across its whole life, or any tier pre-design) |
   | yes | yes | no | `design done` — Stage 5 (full) or Stage 6 (design-only) |
   | yes | yes | yes | `plan done` — Stage 6+ (full, implementing) |

4. Emits JSON — one bug (`/bugfix <id>`) or all in-flight bugs (`/bugfix`).

**Phase vs stage (why the picker shows a phase).** The offline signal set `{branch, design, plan}` is deliberately coarse: it cannot distinguish Stages 6–9 (no new artifact appears after the plan), and a **trivial** bug produces no design/plan artifact at all, so it stays in `branch cut` for its entire life (Stages 3→9). The picker therefore shows the **phase**, not a precise stage. When the human picks a bug (or runs `/bugfix <id>`), the orchestrator reads that bug's ticket work-log (`getTicket`) and **narrows** the resume point to the last recorded milestone — for a full bug that pins tier (design-only Stage 6 vs full Stage 5); for a trivial bug the work-log has no entry between G2 and Verify, so it narrows only to `root-cause-done / verified / done`. The **human confirm** (§4.2) then fixes the exact stage. Precision comes from the work-log-plus-confirm at selection time, never from the offline script.

**Testability:** the script separates a pure `computeStage({branches, artifacts}) → results` function (unit-tested against fixtures, no I/O) from a thin git/fs I/O wrapper — mirroring the adapter's `projectIssue`/`runGh` split, so it is verifiable without a live repo (verified A8: `node --test` works on Node v24.18.0).

### 4.2 The LLM half

The orchestrator takes the script's JSON, presents the resume point (or picker), **waits for the human to confirm**, then drives the workflow. Because the script reads reality (branches + files), it cannot drift; the confirm step covers the rare inference ambiguity.

### 4.3 Pre-branch bugs

Bugs at Stages 0–2 have no branch and no artifacts, so `status.mjs` cannot see them (O4). They are resumed by explicit id; the orchestrator additionally reads the ticket work-log (`getTicket`) to recover context (e.g., the agreed root cause posted at G2). This is why a work-log entry at G2 matters (§10) — it is the only durable record of a root-cause agreement made before the branch exists.

> **Distinction from umbrella D11:** reading back the *work-log comments* to recover context is not "reading a status to branch on it." `setStatus` remains advisory and one-way; `getTicket`'s faithful comment dump (adapter TA7) is what the orchestrator reads. The work-log entries carry a hidden marker (§10) so the orchestrator finds its own entries.

---

## 5. The three complexity tiers

Selected at triage (G1): the orchestrator proposes a tier with its reasoning; the human confirms or overrides. The tiers differ **only** in whether Stages 4 and 5 run and how Stage 6 executes. All three share Stages 0–3 and 7–9.

| Tier | Stage 4 (design) | Stage 5 (plan) | Stage 6 (implement) | Gates | Reasoning heuristic |
|---|---|---|---|---|---|
| **Trivial** | — | — | direct TDD fix | G1, G2, G8 | Fix obvious from root cause |
| **Design-only** | `TB → CDR ⇄ UDD` | — | direct TDD fix | G1, G2, **G4**, G8 | Approach unclear, but the change is localized |
| **Full** | `TB → CDR ⇄ UDD` | `TWP → CIR ⇄ UIP` | **`subagent-driven-development`** | G1, G2, G4, **G5**, G8 (+ security review) | Approach unclear **and** multi-step / risky |

(`CDR ⇄ UDD` / `CIR ⇄ UIP` = a mandatory review loop, run until the review is green: once `TB`/`TWP` runs, its review runs; if not green, `UDD`/`UIP` applies the findings and the review re-runs, repeating until green. What is optional is `TB`/`TWP` themselves — the tier selects whether they run.) The fourth combination — plan without design — is deliberately not offered (O5).

---

## 6. Stage pipeline & delegation

The orchestrator walks the umbrella's stages 0–9. At each stage it does exactly one of: **delegate to a skill** (Skill tool), **call the adapter** (node, §11), or **apply its own judgment** (only for triage classification and work-log posting). It re-implements nothing.

| # | Stage | Orchestrator action | Gate |
|---|-------|---------------------|------|
| 0 | Pickup / ingest | adapter: `getTicket`, `assign … @me`, `setStatus … in-progress` | — (folded into G1) |
| 1 | Triage & route | **own judgment:** state expected-vs-actual; propose tier; post work-log | **G1** |
| 2 | Reproduce & root cause | delegate: `systematic-debugging` (the shared spine, O6) → pause at G2 | **G2** |
| 3 | Isolate + failing test | delegate: `using-git-worktrees` (branch, per harness convention) → `test-driven-development` (failing reproduction test on the branch) | — |
| 4 | Solution options *(design-only, full)* | delegate: `thorough-brainstorming` → `critical-design-review` ⇄ `update-design-doc` (loop until CDR green) | **G4** |
| 5 | Plan *(full)* | delegate: `thorough-writing-plans` → `critical-implementation-review` ⇄ `update-implementation-plan` (loop until CIR green) | **G5** |
| 6 | Implement | full: `subagent-driven-development`; trivial/design-only: direct TDD fix (make the test pass) | — |
| 7 | Verify | delegate: `verification-before-completion` + run harness `format`/`test`; original reproduction gone | — |
| 8 | Review | delegate: `requesting-code-review` / `receiving-code-review` (+ *optional* `critical-security-review` on full/security-relevant) (+ *optional* harness `review_skill`) | **G8** |
| 9 | Finish & writeback | delegate: `finishing-a-development-branch` (PR per harness convention, closing keyword); adapter: `linkPullRequest`, `setStatus … done` | — |

**The `systematic-debugging` fork (O6):** all tiers run Stage 2 identically to root cause and pause at G2. Trivial resumes straight into Stages 3→6→7 (systematic-debugging's natural continuation, which already points to TDD and verification-before-completion). Design-only/full detour through Stage 4 (and, for full, Stage 5) before Stage 6.

**Why delegation composes cleanly (verified A3):** every chain-skill (`thorough-brainstorming`, `thorough-writing-plans`, CDR, CIR, UDD, UIP) hard-gates against auto-chaining — each stops at a committed artifact and hands back. The orchestrator is exactly the conductor that picks each one up, runs the gate, and moves to the next — looping `CDR ⇄ UDD` / `CIR ⇄ UIP` until the review is green before advancing past G4/G5. Their natural stop points *are* the orchestrator's gates.

### 6.1 Needs-info loop (umbrella §4.1)

If Stage 2 cannot reproduce for lack of information, the orchestrator posts the "required to proceed" checklist (carried by the adapter skill), calls `setStatus … needs-info --label <configured>`, posts a work-log entry, and pauses. The bug re-enters at Stage 2 by explicit id when the reporter responds (it is pre-branch, so not in the picker — O4).

---

## 7. Gates

Mandatory human checkpoints, presented in-chat; the orchestrator waits for approval before continuing:

- **G1** — confirm the bug statement + tier classification.
- **G2** — root-cause sign-off (highest value: agree on *why* before *how*). The common fork point across all tiers.
- **G4** *(design-only, full)* — approve the design / chosen option.
- **G5** *(full)* — approve the plan.
- **G8** — human review before the PR is raised.

These gates are precisely the knobs a future autonomy phase would turn down (umbrella §11) — not built now (D2).

---

## 8. Harness configuration

A human-authored file `.claude/bugfix.harness.md` in the **target** repo. The orchestrator reads it on every invocation and echoes the resolved values at G1 for confirmation (O2). It passes `branch` (as a glob) and the `artifacts` dirs to `status.mjs` as CLI args, keeping the script a pure function of its inputs.

Annotated Umbraco example (every value verified against the harness — A11):

```
# Bugfix harness config — Umbraco CMS

tracker: github

status_labels:
  needs-info: state/needs-investigation
  # in-progress / in-review / done → no native label → comment fallback (adapter)

branch: "v{major}/bugfix/{id}-{desc}"     # v<major>/<type>/<desc>; example: v18/bugfix/12345-...
major_from: version.json                    # version 18.2.0-rc → major 18

pr:
  title: "{area}: {description} (closes #{id})"
  closing_keyword: "Fixes #{id}"            # on its own line in the PR body (title suffix alone won't auto-close)

format: dotnet format
test:   dotnet test

review_skill: umb-review                     # optional; omit if none

artifacts:                                   # target dirs (created on first write; need not pre-exist)
  specs:   docs/specs/
  plans:   docs/plans/
  reviews: docs/criticalreviews/

repro_verify: auto                           # auto = project test suite; browser/manual are documented seams (§12)
```

`done` is not a label — issue closing is delegated to the PR closing keyword at Stage 9 (O11 / adapter TA6). The format is itself a seam (§14): the orchestrator reads it, so a customizer edits values without touching code.

---

## 9. Work-log

Structured markdown the orchestrator posts to the ticket (adapter `comment`) at each milestone — the durable human record and the recovery source for pre-branch resume (§4.3). Each block carries a hidden marker so the orchestrator finds its own entries:

```markdown
### 🔧 bugfix · <milestone>
<!-- bugfix-worklog stage=<n> -->
<fields>
```

| Milestone | Fields |
|---|---|
| Triage (G1) | Classification: `trivial` \| `design-only` \| `full` · Expected: … · Actual: … |
| Root cause (G2) | Root cause (the *why*): … |
| Design (G4) | Options considered: … · Chosen: … · Design doc: `<path>` |
| Plan (G5) | Plan: `<path>` · Summary: … |
| Verify (7) | Test added: … · `format` ✅ · `test` ✅ · Original repro gone: ✅ |
| Done (9) | PR: `<url>` · Status: done |

Lean by design and a named seam (teams edit what lands on their tickets).

---

## 10. Tracker adapter invocation

The orchestrator consumes the adapter's built contract (sibling spec §4; verified A4). It resolves the script's **absolute** path from its own harness-provided skill base directory → sibling `../tracker-adapter/scripts/adapter.mjs`, and runs it **with cwd = the target repo** (O9):

```
node <resolved>/tracker-adapter/scripts/adapter.mjs github <verb> [args…]
```

Verbs used, by stage: `getTicket` (0, resume context), `assign` (0), `setStatus` (0, needs-info, 9), `comment` (work-log, needs-info checklist), `linkPullRequest` (9). `listCandidates` is unused (deferred). Status-label names come from `status_labels`; absent → the adapter's comment fallback.

---

## 11. UI / non-code bugs

Same pipeline, different test stack and reproduction surface (O7):

- **Reproduce + root cause (2):** `systematic-debugging` — reproduction happens in a browser instead of a REPL/test; the discipline is identical.
- **Failing test (3):** whatever the project's stack expresses — a component or E2E test (Playwright/Cypress/…) exactly as a unit test for a backend bug. The pipeline never assumes "unit test" (verified A12: the delegated skills are framework-agnostic).
- **Verify (7):** run that suite; plus, for a visual defect, a manual browser re-check.

`repro_verify` is the seam: `auto` (the project test suite) by default; browser/E2E/manual are documented variants a team plugs their own tooling into. **The base ships no browser automation** (a §20 future add).

**Honest fallback:** when the project has no automated UI-test path, the "failing test first" Iron Law is satisfied by a **documented manual reproduction** (steps + expected/actual) recorded in the work-log; the fix is verified manually; the work-log **flags that regression protection is manual, not automated.** Nothing pretends every UI bug gets a regression test; nothing is silently skipped.

---

## 12. Component shape & file layout

```
skills/bugfix/
  SKILL.md                 # overview · invocation (/bugfix [id]) · tiers + gates · pointers to config & customizing
  references/
    playbook.md            # the stage-by-stage conductor the LLM follows (the operational spine)
    harness-config.md      # config format + the annotated Umbraco example + "author your own"
    work-log.md            # the work-log template + marker convention (seam)
    customizing.md         # extension points + condensed decisions & rationale (why → safe to change)
  scripts/
    status.mjs             # deterministic resume: pure computeStage({branches,artifacts}) + thin git/fs I/O
  tests/
    status.test.mjs        # node:test over fixtures (pure computeStage, no live git)
    fixtures/*.json        # {branches, artifacts} → expected-stage samples
```

Plus one `.gitignore` line in the skills-whitelist block: `!/skills/bugfix/` (verified A9: one line recursively tracks the subtree; slot alphabetically). The `status.mjs` pure/IO split mirrors the adapter's for testability.

---

## 13. Extension points (→ `references/customizing.md`)

| Seam | How you change it |
|---|---|
| Tracker provider | Adapter provider slot — `github` built, `jira` documented; add your own |
| Harness values | Edit `.claude/bugfix.harness.md` (labels, branch/PR, commands, dirs) |
| Project review skill | Set `review_skill:` (Stage 8) or omit |
| Reproduction/verification | `repro_verify:` — `auto` (tests) by default; browser/E2E/manual for UI |
| Work-log content | Edit `references/work-log.md` template |
| Tiers / gates / stages | Fork `references/playbook.md` — each stage is a self-contained block |

---

## 14. Build vs reuse

**Build (this cycle):** `skills/bugfix/` — `SKILL.md`, the four `references/` docs, `scripts/status.mjs`, `tests/status.test.mjs` + fixtures, and the `.gitignore` whitelist line.

**Reuse (no new code):** all 15 delegated skills (§6) and the built tracker adapter (§10). The orchestrator's only original code is `status.mjs`; everything else is delegation + prose playbook.

---

## 15. Relationship to the umbrella

This spec conforms to the umbrella. It originally refined the umbrella's two-path model (D3/§3.2) into three tiers (O5/§5); that refinement has since been folded into the umbrella (§3.2), so the parent carries the three-tier model and no divergence remains. Everything else conforms to the umbrella (stages, gates, needs-info loop, generic-core/harness split, thorough-* skills, `subagent-driven-development` as executor).

---

## 16. Verified assumptions

Checked on 2026-07-25 against the real codebase before finalizing this spec:

- **A1 — skill invocation + args + skills-invoking-skills.** ✅ The Skill tool accepts `args`; the harness maps `/<skill-name>` → Skill; skills routinely invoke other skills (`thorough-writing-plans` names `subagent-driven-development` as REQUIRED SUB-SKILL). Skills are invoked with a harness-provided **base directory** (observed: `Base directory for this skill: ~/.claude/skills/thorough-brainstorming`).
- **A2 — all 15 delegated skills exist.** ✅ superpowers 8/8 (`systematic-debugging, test-driven-development, using-git-worktrees, subagent-driven-development, verification-before-completion, requesting-code-review, receiving-code-review, finishing-a-development-branch`) in the plugin cache; toolkit 7/7 in `skills/`.
- **A3 — chain-skills hard-gate against auto-chaining.** ✅ TB ("do NOT invoke any implementation skill… Wait for the user"), TWP ("Stop at a committed plan; do not invoke downstream"), CIR ("STOP… Do NOT auto-invoke"), CDR (terminal state = review file), UDD/UIP (decomposition/abort gates). The conductor model fits.
- **A4 — adapter contract as documented.** ✅ `tracker-adapter:scripts/adapter.mjs` dispatches `getTicket/assign/setStatus/comment/linkPullRequest` (+ `listCandidates` stub); invocation `node scripts/adapter.mjs <provider> <verb>`.
- **A5 — orchestrator can locate the adapter.** ✅ No `CLAUDE_PLUGIN_ROOT` convention exists; skills use relative-to-base-dir paths and receive their base dir at invocation. `bugfix` and `tracker-adapter` are both peters-toolkit skills → siblings wherever installed. Resolution: `<own-base>/../tracker-adapter/scripts/adapter.mjs`, run with cwd = target repo. (Surfaced Finding 1 — §19.)
- **A6 — `git branch --list` glob incl. worktrees.** ✅ **proven live** — a temporary worktree branch `v99/bugfix/99999-probe` appeared for `git branch --list 'v*/bugfix/*'`, prefixed `+ ` (script strips `+ `/`* `). Offline.
- **A7 — artifact naming carries the id.** ✅ TB → `docs/specs/YYYY-MM-DD-<topic>-design.md`; TWP → `docs/plans/YYYY-MM-DD-<topic>-implementation-plan.md`. `<topic>` is orchestrator-controlled → embed the id; `status.mjs` matches by id.
- **A8 — `node:test` + `.mjs` ESM.** ✅ Node v24.18.0; `node --test <file>` passed; `.mjs` runs as ESM with no `package.json` type pin.
- **A9 — `.gitignore` recursion + no collision.** ✅ `skills/thorough-brainstorming/scripts/**` is tracked via one `!` line; no `bugfix` skill exists.
- **A10 — `run-tests.sh` stays green.** ✅ `check-version-lockstep.sh` compares only version markers (plugin.json/README/CHANGELOG) + Superpowers-target; `check-companion-provenance.sh` sha256-checks a fixed manifest + greps for removed tokens. A new skill touches neither. (Shipping still requires the coordinated version bump — a release step.)
- **A11 — Umbraco harness values.** ✅ version `18.2.0-rc` → major 18; branch `v<version>/<type>/<desc>` (example `v17/bugfix/12345-…`); PR title `Area: Description (closes #ID)` + `Fixes #ID` on its own body line; `dotnet format` / `dotnet test`; `state/needs-investigation` label real; `umb-review` present. **Correction:** only `docs/criticalreviews/` exists in Umbraco today — `docs/specs/`, `docs/plans/` are created on first write (Finding 3 — §19).
- **A12 — pipeline is test-stack-agnostic.** ✅ TDD's core ("write the test first, watch it fail" — jest is only its example); `verification-before-completion` runs "the project's" linter/build/test generically. UI seam viable.
- **A13 — umbrella is an editable working spec.** ✅ Editable for the O5 refinement (and the review-loop correction), applied and committed this session. Now git-tracked (per the per-skill `docs/` publishing policy), not ignored as originally verified.

---

## 17. Findings folded in

- **Finding 1 (adapter docs) — one-line follow-up.** The tracker-adapter SKILL.md documents `node scripts/adapter.mjs …` (relative), which cannot resolve when cwd = the target repo (required by `gh`). The orchestrator handles this by absolute-path resolution (O9/§10). Per the user's decision, a **one-line clarification** to the adapter SKILL.md ("invoke by absolute path with cwd = the target repo") is folded in as a follow-up — applied when the adapter is next touched (not built in this cycle).
- **Finding 2 (build detail).** `status.mjs` strips the `+ ` (worktree) and `* ` (current) prefixes from `git branch --list` output when parsing ids.
- **Finding 3 (accuracy).** Harness `artifacts` dirs need not pre-exist; TB/TWP create them on first write. The umbrella §9's claim that `docs/specs/` is "present in the Umbraco repo" is slightly overstated — only `docs/criticalreviews/` exists today.

---

## 18. Deferred / not built

- **`listCandidates` / tracker-side "list my in-flight bugs"** — the picker is offline/branch-cut only (O4); a tracker query for assigned/needs-info issues is the deferred adapter verb.
- **Browser-automation tooling for UI bugs** — `repro_verify` is a seam; the base ships automated-test + manual fallback only (§11).
- **Autonomy dial** — the gates are the future dial (umbrella D2/§11).
- **Jira provider** — the adapter's documented, unbuilt slot.

---

## 19. Next steps

1. `critical-design-review` against this spec (the team's adversarial-review discipline).
2. `thorough-writing-plans` → `critical-implementation-review` → build the `bugfix` skill via `subagent-driven-development`.
3. Add the `!/skills/bugfix/` whitelist line as part of the build; apply the coordinated version bump (A10) when shipping.
4. Fold the one-line adapter-docs clarification (Finding 1) when the `tracker-adapter` branch is next touched.
5. Optionally update the umbrella spec for the three-tier refinement (§15).
6. Exercise end-to-end on real issues in the Umbraco harness; tune gates, tiers, and the work-log template.
