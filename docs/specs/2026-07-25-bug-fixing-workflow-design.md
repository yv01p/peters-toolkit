# Bug-Fixing Workflow — Design

**Date:** 2026-07-25
**Home:** Peter's Toolkit (`~/peters-toolkit`). This is a **generic** workflow; the skills it produces ship in the toolkit.
**Test harness:** Umbraco CMS (`~/Umbraco-CMS`) is the first project we exercise it on — nothing here is Umbraco-specific except the clearly-marked *harness configuration* (§7).
**Status:** Approved (workflow definition). Building the adapter and orchestrator skills follows as separate spec → plan → build cycles.
**Storage:** This spec is a git-ignored working file (the toolkit repo tracks only shippable plugin files).

---

## 1. Purpose & scope

Define a **generic, tracker-agnostic bug-fixing workflow** — from picking a bug up in a ticketing tool through to a merged fix — that a developer drives locally in Claude Code, with human checkpoints at each stage. It is built by **composing skills that already exist** (superpowers + Peter's Toolkit) rather than reinventing them, plus two small new skills.

The end goal is a small number of **Peter's Toolkit skills** that *run* the workflow on any project. This document is the shared definition those skills are built from.

**In scope (this document defines):**

- The stage pipeline, the human gates, and the tier routing (`trivial` / `design-only` / `full`).
- The minimal bug-information contract the workflow needs to succeed.
- The tracker-adapter contract (the only tracker-specific part).
- The generic core vs. per-project **harness configuration** split.
- The build-vs-reuse skill decomposition — i.e. what we build next.

**Out of scope (deliberately, for now):**

- Implementing the tracker adapter or the orchestrator skill (each gets its own cycle).
- An autonomy "dial." We build the fully-gated manual version; autonomy is a documented future evolution (§11), not something we design today.
- Post-merge monitoring (deploy → watch → follow-up). Noted as future (§11).
- Any codebase-orientation / architecture-map input. The workflow relies purely on the just-in-time, bug-scoped investigation already inside the debugging and brainstorming skills.

---

## 2. Decisions (locked, with rationale)

| # | Decision | Rationale |
|---|----------|-----------|
| D1 | **Local, developer-driven** first. A developer invokes the workflow in Claude Code and drives one bug through the stages, approving at gates. | Lets humans build comfort before any autonomy. |
| D2 | **No autonomy dial.** Build only the fully-gated manual version. | YAGNI. The gates *are* the future dial — encode them now, add the dial later if wanted. |
| D3 | **Human-judged complexity tier at triage — `trivial` / `design-only` / `full`.** Two independent dials: does the fix need design exploration? does it need a formal plan? | Keeps ceremony proportional. A one-line fix must not drag through brainstorming + planning; and a fix that needs real design but only a localized change must not be forced through formal planning + `subagent-driven-development`. The fourth combination (plan without design) never occurs and is not offered. |
| D4 | **Tracker-agnostic.** A thin adapter at the two edges (ingest, writeback); the core pipeline is identical regardless of GitHub/Jira/other. | Every team has a different tracker and different fields; the core should not care. |
| D5 | **Approach B — one orchestrator skill + a thin tracker adapter, delegating to existing skills.** (vs. docs-only, vs. many granular skills) | Makes the workflow *runnable* with the smallest new surface; the seams for finer skills aren't known yet. |
| D6 | **Brainstorming and planning use the *thorough* skills only.** | Consistency with how this team works; empirical verification is exactly what a risky fix wants. No plain/`superpowers` brainstorming or planning. |
| D7 | **Verification is generic.** Stage 7 runs *the project's configured* formatter/linter and test suite. | The workflow is generic; concrete commands are harness config (§7). |
| D8 | **No codebase-context / arch-review input.** | Rely on the bug-scoped, always-fresh investigation inside `systematic-debugging` and `thorough-brainstorming`; a whole-repo map is the wrong altitude, staleness-prone, and duplicative. |
| D9 | **Plan execution uses `subagent-driven-development`,** never `executing-plans`. | Team preference; it is also the executor `thorough-writing-plans` itself points to. Applies only where a plan exists (the `full` tier). |
| D10 | **Generic core, per-project harness config.** Anything project-specific (tracker provider, branch/PR conventions, build/test commands, optional project review skill) is supplied as harness configuration, not baked into the core. | The skills live in the toolkit and must run on any project; Umbraco is just the first harness. |
| D11 | **Status is advisory, normalized per-adapter with a comment fallback.** `setStatus` is a one-way signal the core never reads back; each adapter maps it to native mechanisms, falling back to a comment where the tracker has none. | Resolves the GitHub status gap generically (CDR §3.1): GitHub lacks native `in-progress`/`in-review`, and every future tracker would re-raise it. Advisory + fallback means no status is ever silently lost and no per-tracker capability API is needed. |

---

## 3. Workflow shape

```
[ Tracker Adapter: INGEST ]  →  [  Tracker-agnostic core pipeline  ]  →  [ Tracker Adapter: WRITEBACK ]
    (GitHub / Jira / …)            driven locally, gated per stage          (comments, status, PR link)
```

Only the two edges know the tracker. Everything between them is identical.

### 3.1 Stage pipeline

Each stage names the skill it **delegates** to and the **human gate** (in the manual phase). Skills are generic unless marked *(harness)*.

| # | Stage | Delegates to | Human gate |
|---|-------|--------------|------------|
| 0 | **Pickup / ingest** — fetch & normalize the ticket, assign to self, set status "in progress" | tracker adapter *(new)* | — (folded into G1) |
| 1 | **Triage & route** — state expected-vs-actual; classify the **tier** (`trivial` / `design-only` / `full`); assistant proposes, human confirms | orchestrator logic *(new)* | **G1** — confirm bug + classification |
| 2 | **Reproduce & root cause** — Iron Law: no fix without root cause; if not reproducible → *Needs-info* loop (§4.1) | `systematic-debugging` | **G2 — root-cause sign-off** *(the key gate)* |
| 3 | **Isolate, then failing test first** — create the worktree/branch (per project convention *(harness)*) *before* authoring an automated test that fails now, so the test lands on the fix branch | `using-git-worktrees` → `test-driven-development` | — (artifact checkpoint) |
| 4 | **Solution options** *(design-only, full)* — 2–3 options → design; optional adversarial review | `thorough-brainstorming` → *(optional pair)* `[critical-design-review → update-design-doc]` | **G4** — choose option / approve design |
| 5 | **Plan** *(full only)* — implementation plan; optional adversarial review | `thorough-writing-plans` → *(optional pair)* `[critical-implementation-review → update-implementation-plan]` | **G5** — approve plan |
| 6 | **Implement** — on the worktree/branch from Stage 3; make the test pass, minimal change | (`full`: `subagent-driven-development`; `trivial`/`design-only`: direct TDD fix) | — |
| 7 | **Verify** — project's formatter/linter + test suite *(harness)*; original reproduction gone; evidence before claims | `verification-before-completion` | — |
| 8 | **Review** — diff review; security review when relevant; project review skill if configured | `requesting-code-review` / `receiving-code-review` (+ *optional* `critical-security-review`) (+ *optional* project review skill *(harness)*) | **G8 — pre-PR review** |
| 9 | **Finish & writeback** — open PR per project convention *(harness)*; link PR & set status on the ticket | `finishing-a-development-branch` + adapter writeback | — |

**Optional review + apply run as a pair.** In Stages 4 and 5 the adversarial review is optional; when it runs, its apply-step (`update-design-doc` / `update-implementation-plan`) runs immediately after to fold in the findings — a no-op if the review found nothing. When the review is skipped, its apply-step is skipped too: `update-*` consume a review file and have nothing to do without one. Hence the `[review → update]` bracket in the table.

### 3.2 The three tiers

Two independent dials at triage — does the fix need design exploration? does it need a formal plan? — give three tiers:

- **Trivial:** `0 → 1 → 2 → 3 → 6 → 7 → 8 → 9`. Gates **G1, G2, G8**. No design, no plan — the fix is obvious from the root cause. The worktree/branch is created at Stage 3 (before the failing test); Stage 6 is a direct TDD fix on that branch (no `subagent-driven-development`).
- **Design-only:** adds Stage **4** (`thorough-brainstorming` → optional `[critical-design-review → update-design-doc]`). Gates **G1, G2, G4, G8**. Design yes; no formal plan; Stage 6 is a direct TDD fix. The common middle case — a bug that needs real brainstorming but whose fix, once decided, is localized.
- **Full / risky:** adds Stages **4** and **5** (`thorough-writing-plans` → optional `[critical-implementation-review → update-implementation-plan]`) and security review in Stage 8. Stage 6 executes the plan via `subagent-driven-development`. Gates **G1, G2, G4, G5, G8**.

The fourth combination — plan without design — is deliberately not offered: a formal plan always follows design.

### 3.3 Gates (manual phase)

Mandatory human checkpoints: **G1** (confirm bug + classification), **G2** (root-cause sign-off — highest value: agree on *why* before *how*), **G8** (human reviews before the PR is raised/merged); plus **G4** on the `design-only` and `full` tiers, and **G5** on the `full` tier. These gates are precisely the knobs a future autonomy phase would turn down (§11).

### 3.4 Relationship to `systematic-debugging` (coherence note)

`systematic-debugging` itself spans root cause → failing test → fix → verify (its Phases 1–4) and explicitly points to `test-driven-development` (failing test) and `verification-before-completion` (confirm the fix). The workflow uses it as the **investigation spine** through root cause, **pauses at G2** for human sign-off, then continues — with failing-test / implement / verify delegated to the dedicated skills it already recommends. So stages 2/3/6/7 **delegate**, they don't duplicate.

---

## 4. Minimal bug-information contract

The adapter's job is to **project** each team's arbitrary field set onto one small normalized model. Three tiers:

| Tier | Field | Why it's here |
|------|-------|---------------|
| **Mechanical** (adapter must guarantee) | **Stable ticket ID** | So we can address the ticket and write back |
| | **Writeback channel** (comment + set-status capability) | So the work-log and status transitions land |
| **Required to proceed** (else → *Needs-info* loop) | **Expected behavior** | Can't define "fixed" without it |
| | **Actual behavior / symptom** (incl. error / stack trace if any) | This *is* the bug |
| | **Reproducibility context** — steps, and environment/version where relevant | Stage 2 can't reproduce without it |
| **Enriching** (optional; accelerates, never blocks) | severity/priority, labels/component/area, attachments/logs, related links (issues/PRs/commits), reporter/contact | Helps triage, routing, RCA, and needs-info round-trips |

Two properties make this generic and robust:

- **Projection, not schema.** The adapter maps whatever a team has onto these fields; unmapped tracker fields are ignored. Any tracker with an ID, comments, and a status works.
- **The list does double duty.** The "Required to proceed" tier is *also* the checklist the Needs-info loop posts when something is missing.

### 4.1 Needs-info loop

Missing required information never fails the run. In Stage 2, `systematic-debugging`'s rule ("if not reproducible → gather more data, don't guess") drives it: the workflow posts a structured request for exactly the missing required-to-proceed items, sets status to *needs-info*, and pauses. When the reporter responds, the ticket re-enters at Stage 2.

---

## 5. Tracker adapter contract

The only tracker-specific part of the core. Two directions:

**Read**

- `getTicket(id) → Ticket { id, title, body, comments[], labels[], severity?, attachments[], links[] }`
- *(optional)* `listCandidates(filter) → Ticket[]` — for "pick the next bug" style entry.

**Write**

- `assign(id, who)`
- `setStatus(id, name)` — `name` is one of a small workflow vocabulary: `in-progress`, `needs-info`, `in-review`, `done`.
- `comment(id, markdown)`
- `linkPullRequest(id, url)`

**Close-on-merge** is delegated to the tracker's native PR linkage — the adapter only emits the right link/keyword (GitHub closing keyword `Fixes #ID` in the PR body; Jira smart-commit / transition on merge).

**Status is advisory, normalized in the adapter.** `setStatus` is a best-effort, one-way signal to humans and tooling; the core never reads a status back to branch on it (`listCandidates` filters via the adapter's native query, not by round-tripping this vocabulary). Each adapter maps the abstract status to the best native mechanism its tracker offers and, where the tracker has none, **falls back to a comment** ("→ in review"). Because comments are in the mechanical tier (every tracker has them), a status signal is never silently lost, and a tracker that cannot represent a status degrades gracefully instead of breaking the run.

Providers are pluggable. The GitHub provider is the reference implementation (§7); Jira and others are documented provider slots, not built now.

---

## 6. Build vs reuse (the bridge to skills)

**Build (new Peter's Toolkit skills — each its own later spec → plan → build cycle):**

1. **Tracker adapter** — the normalized `Ticket` shape + the four writeback verbs, with a GitHub reference provider. Likely a skill plus per-provider reference docs (`references/github.md`, `references/jira.md`), or a small script the orchestrator calls. Exact form decided in its own cycle.
2. **`bugfix` orchestrator skill** — walks stages 0–9, enforces the gates, does the tier routing (`trivial` / `design-only` / `full`), reads the harness configuration (§7), and calls the delegated skills + adapter in order. Holds the stage checklist and the ticket **work-log template** (RCA / options considered / testing done).

Both new skills must be added to the toolkit `.gitignore` whitelist (`!/skills/<name>/`) to be tracked and shipped.

**Reuse (no new code):**

- superpowers: `systematic-debugging`, `test-driven-development`, `using-git-worktrees`, `subagent-driven-development`, `verification-before-completion`, `requesting-code-review`, `receiving-code-review`, `finishing-a-development-branch`.
- Peter's Toolkit: `thorough-brainstorming`, `thorough-writing-plans`, `critical-design-review`, `critical-implementation-review`, `critical-security-review`, `update-design-doc`, `update-implementation-plan`.
- *(harness, optional)* a project-specific review skill, e.g. `umb-review` for the Umbraco harness.

The new surface is intentionally small: an adapter and an orchestrator. Everything hard is delegation. Note the workflow depends on **both** the superpowers and Peter's Toolkit plugins being installed.

---

## 7. Harness configuration (what each project supplies)

The generic core is parameterized by a small per-project configuration. For the **Umbraco harness** these are:

| Config | Umbraco harness value | Verified source |
|--------|-----------------------|-----------------|
| Tracker provider | GitHub via `gh` CLI | `umb-review/references/gh-cli-setup.md` |
| Status model | GitHub has no native issue status: `needs-info` → `state/needs-investigation` label; `done` → issue closed (via the PR closing keyword); `in-progress`/`in-review` → a `state/*` label if the repo defines one, else a comment (per §5's advisory fallback) | `issue-deduplication.yml` (only `state/needs-investigation` verified present) |
| Branch convention | `v{major}/bugfix/{id}-{desc}`; major from `version.json` (currently **v18**) | `CLAUDE.md`, `version.json` = `18.2.0-rc` |
| PR convention | Title `Area: Description (closes #ID)` + closing keyword on its own line in the body | `CLAUDE.md` |
| Formatter / tests | `dotnet format` / `dotnet test` | `CLAUDE.md` |
| Project review skill (optional) | `umb-review` | `.claude/skills/umb-review` |
| Full-path artifact locations | design → `docs/specs/`; plans → `docs/plans/`; adversarial reviews → `docs/criticalreviews/` | created on first write; only `docs/criticalreviews/` exists in the Umbraco repo today |

A Node project's harness config would instead read e.g. `npm run lint` / `npm test`, a `fix/` branch convention, and no project review skill. None of this lives in the core.

**State:** the **ticket is the work-log** (RCA, options, testing notes posted back via the adapter). Full-path design/plan/review artifacts are written to the *harness project's* locations (above), following that project's conventions — not the toolkit repo.

---

## 8. Worked examples (Umbraco harness)

**Trivial bug** (off-by-one in a helper):
`0` ingest → `1` classify *trivial* (G1) → `2` reproduce + root cause (G2) → `3` isolate (worktree) + failing test → `6` direct fix → `7` verify (`dotnet format`/`dotnet test`) → `8` review + `umb-review` (G8) → `9` PR + writeback. No brainstorming, plan, or adversarial review.

**Design-only bug** (wrong value shown in a component — the *right* behaviour needs thought, but the fix is localized):
adds `4` `thorough-brainstorming` (→ optionally `[critical-design-review → update-design-doc]`) (G4); `6` is a direct TDD fix — no formal plan, no `subagent-driven-development`. Gates G1, G2, G4, G8.

**Full / risky bug** (caching invalidation defect with multiple viable fixes):
adds `4` `thorough-brainstorming` (→ optionally `[critical-design-review → update-design-doc]`) (G4) and `5` `thorough-writing-plans` (→ optionally `[critical-implementation-review → update-implementation-plan]`) (G5); `6` executes the plan via `subagent-driven-development`; `8` also runs `critical-security-review` if the change touches a security-relevant surface.

---

## 9. Verified assumptions

Checked on 2026-07-25 before writing this spec:

- **All delegated skills exist.** superpowers (`systematic-debugging`, `test-driven-development`, `using-git-worktrees`, `subagent-driven-development`, `verification-before-completion`, `requesting-code-review`, `receiving-code-review`, `finishing-a-development-branch`) present in the superpowers plugin. Peter's Toolkit skills present in `~/peters-toolkit/skills/`. `umb-review` present in the Umbraco harness only (correctly *not* a core dependency).
- **`subagent-driven-development`** executes implementation plans and is the executor `thorough-writing-plans` points to (its HARD-GATE names it). `executing-plans` is intentionally unused (D9).
- **Peter's Toolkit chain holds.** `thorough-writing-plans` consumes `thorough-brainstorming` spec output (strict input contract); `critical-design-review` reviews the spec; `critical-implementation-review` reviews the plan; `update-design-doc` / `update-implementation-plan` consume CDR/CIR v2 outputs and commit pre/post state in a git repo; `critical-security-review` accepts a dir/file/URL code input.
- **`systematic-debugging` scope.** Spans root cause → failing test → fix → verify and delegates to `test-driven-development` + `verification-before-completion`; stages 2/3/6/7 delegate rather than duplicate; gating at G2 and resuming is compatible.
- **Toolkit repo layout.** `~/peters-toolkit` is a git repo whose `.gitignore` is a denylist-then-whitelist tracking only shippable files (`skills/` whitelisted per-skill, `.claude-plugin/`, `tests/`, README/CHANGELOG/LICENSE). No `docs/` is tracked → this spec is a git-ignored working file; new skills need `!/skills/<name>/` whitelist lines.
- **No collision.** The toolkit `skills/` set contains no bug-fixing orchestrator/adapter; the design fills a genuine gap.
- **Umbraco harness config** verified as in §7, with one narrowing: only `state/needs-investigation` (needs-info) is a verified GitHub label — a grep of `Umbraco-CMS/.github/` finds no other `state/*` label. The other statuses are handled by design, not by a verified label: `done` maps to issue-closed, and `in-progress`/`in-review` fall back to a comment where no label exists (§5, D11). So no verified-label dependency is left uncovered.

---

## 10. Generic core vs. harness — the boundary

- **Generic (ships in the toolkit):** stages, gates, routing, the minimal bug-info contract, the tracker-adapter *contract*, the orchestrator, and the GitHub *reference* provider.
- **Per-project (harness config, §7):** tracker choice + status model, branch/PR conventions, build/test/format commands, optional project review skill, artifact locations.

If a change would only ever be true for Umbraco, it belongs in harness config, not the core.

---

## 11. Path to autonomy (future, not built now)

The manual gates (§3.3) are the future autonomy control. When the team is comfortable, autonomy can be added *without reshaping the pipeline* — e.g. an autonomy level that turns down which gates pause (`manual` → `assisted`, pausing only at G2 & G8 → `auto`, stopping only when genuinely blocked), and eventually a tracker-triggered entry point that runs the pipeline in the background and opens a PR for human review. Post-merge monitoring (deploy → watch → auto-file a follow-up) is the other natural future addition. Both are explicitly deferred.

---

## 12. Next steps

1. Review and approve this workflow definition.
2. Spec → plan → build the **tracker adapter** skill (GitHub reference provider first); add its `.gitignore` whitelist line.
3. Spec → plan → build the **`bugfix` orchestrator** skill; add its whitelist line; define the harness-config format it reads.
4. Exercise end-to-end on real issues in the Umbraco harness; tune gates and the work-log template.
