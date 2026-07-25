# Bugfix Orchestrator Implementation Plan

> **For agentic workers:** REQUIRED: Use `superpowers:subagent-driven-development` to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking. Tasks 3–5 author the skill and REQUIRED: use `superpowers:writing-skills` (RED → GREEN → REFACTOR with subagent testing) — do not free-hand the SKILL.md / reference docs.

**Source spec:** `docs/specs/2026-07-25-orchestrator-design.md` (commit `3e329c0` — the spec's last-modifying commit; repo HEAD is `ddc0b39`, the two later commits are CDR round-3/4 review artifacts and do not touch the spec, so no drift).

**Goal:** Build the `bugfix` orchestrator skill — the LLM conductor that drives one bug from pickup to a merged fix through the umbrella's staged, gated, tier-routed workflow, delegating every hard step to existing skills + the tracker adapter.

**Architecture:** A single toolkit skill at `skills/bugfix/`: a lean `SKILL.md` entry + flat reference docs (`playbook.md`, `harness-config.md`, `work-log.md`, `customizing.md`) + one deterministic `scripts/status.mjs` (offline git+fs → resume phase) with `tests/`. It re-implements nothing: the 15 delegated skills and the built tracker adapter are reused; the only original code is `status.mjs`.

**Tech stack:** Node ESM (`.mjs`, `node:test`, Node v24.18.0); Markdown skill docs authored per `superpowers:writing-skills`; git + `gh`-based workflow. Skill cross-references use `superpowers:<name>` for Superpowers skills and bare names for toolkit skills.

---

## File Structure

**Create**
- `skills/bugfix/SKILL.md` — lean entry: overview + core principle, when-to-use, `/bugfix [id]` invocation, the three tiers + gates (quick-reference), pointers to the flat reference docs
- `skills/bugfix/playbook.md` — the stage-by-stage conductor spine (stages 0–9, per-stage delegation, the `review ⇄ update` loop, the gates, the needs-info loop, the `systematic-debugging` fork)
- `skills/bugfix/harness-config.md` — `.claude/bugfix.harness.md` format + the annotated Umbraco example + "author your own"
- `skills/bugfix/work-log.md` — work-log template + hidden-marker convention
- `skills/bugfix/customizing.md` — extension points + condensed decisions & rationale (the "why," installer-facing)
- `skills/bugfix/scripts/status.mjs` — deterministic resume: pure `computeStage` + thin git/fs I/O + CLI
- `skills/bugfix/tests/status.test.mjs` — `node:test` over fixtures
- `skills/bugfix/tests/fixtures/*.json` — `{branches, artifacts}` → `expected` samples

**Modify**
- `.gitignore` — add `!/skills/bugfix/` in the skills-whitelist block (alphabetical slot, between `!/skills/arch-review/` and `!/skills/cobol-xray/`)
- `tests/run-tests.sh` — add a `node --test 'skills/bugfix/tests/**/*.test.mjs'` guard to the hermetic suite

**Test**
- `skills/bugfix/tests/status.test.mjs` + `tests/fixtures/*.json` (unit-tests the pure `computeStage`)

---

## Inherited from spec

Verified by `thorough-brainstorming` at spec-write time (§16) and by three CDR rounds; **trusted as ground truth, not re-verified here**:

- **A1** — Skill tool accepts `args`; harness maps `/<skill-name>` → Skill; skills invoke skills; skills get a harness-provided base directory.
- **A2** — all 15 delegated skills exist (8 superpowers, 7 toolkit).
- **A3** — chain-skills (`thorough-brainstorming`, `thorough-writing-plans`, CDR, CIR, UDD, UIP) hard-gate against auto-chaining — each stops at a committed artifact.
- **A4** — tracker-adapter contract: `getTicket/assign/setStatus/comment/linkPullRequest` (+ `listCandidates` stub); `node scripts/adapter.mjs <provider> <verb>`.
- **A5** — orchestrator resolves the adapter as `<own-base>/../tracker-adapter/scripts/adapter.mjs` (same-plugin siblings), cwd = target repo.
- **A6** — `git branch --list '<glob>'` includes worktree branches (prefixed `+ `); offline.
- **A7** — artifact filenames carry the id (`YYYY-MM-DD-<topic>-design.md` / `-implementation-plan.md`; `<topic>` is orchestrator-controlled).
- **A8** — `node --test` + `.mjs` ESM work on Node v24.18.0.
- **A9** — one `!/skills/<name>/` line recursively tracks a skill subtree; no `bugfix` collision.
- **A10** — `run-tests.sh`'s lockstep + provenance guards are unaffected by adding a skill (shipping still needs the coordinated version bump — a release step).
- **A11** — Umbraco harness values (branch/PR/`dotnet`/labels/`umb-review`); only `docs/criticalreviews/` pre-exists — other artifact dirs are created on first write.
- **A12** — the pipeline is test-stack-agnostic (TDD + `verification-before-completion` are framework-generic).
- **A13** — the umbrella is an editable, git-tracked working spec (now published per the per-skill `docs/` policy).

---

## Verified plan-level assumptions

Newly introduced by this plan and verified at plan-write time:

| # | Category | Assumption | Evidence |
|---|---|---|---|
| 1 | File path | `skills/bugfix/` is a new dir | `ls -d skills/bugfix` → absent |
| 2 | File path | `.gitignore` skills block exists; `bugfix` unlisted; alphabetical slot after `arch-review` | `.gitignore:41` `/skills/*`, `:42–53` whitelist; `bugfix` grep → absent |
| 3 | Convention | Skill supporting docs are **flat at skill root** (no `references/` dir); `scripts/`/`tests/` are purpose-dirs | No skill uses `references/`; `thorough-brainstorming` has flat `visual-companion.md` + `scripts/`; `writing-skills` keeps 4+ `.md` at root |
| 4 | Signature | `status.mjs` mirrors the adapter's pure/IO split | `tracker-adapter:…/adapter.mjs` exports `projectIssue()` (:6) + `runGh()` (:24) |
| 5 | Command | Tests run via `node --test`; `tests/run-tests.sh` is the hermetic guard entry | `run-tests.sh` runs provenance + lockstep only — no `node --test` yet; zero `*.test.mjs` in repo (status.test.mjs is the first) |
| 6 | Command | Commit convention = conventional commits | `git log`: `feat(…)`, `docs(…)`, `build:` → skill commits use `feat(bugfix):` / `build(bugfix):` |
| 7 | Ordering | `.gitignore` whitelist (Task 1) must precede all `skills/bugfix/` file commits | `git check-ignore skills/bugfix/SKILL.md` → ignored by `/skills/*` until whitelisted |
| 8 | Code | Node v24.18.0 supports `node:child_process`/`node:fs` ESM imports + `node --test` on `.mjs` | `node --version` = v24.18.0 (A8) |
| 9 | Code | `git branch --list` prefixes (`* ` current, `+ ` worktree, `  ` other) match the strip regex `/^[*+]?\s+/` | `git branch` shows `* publish-artifacts`; `+ ` proven live (A6) |
| 10 | Consumer | Adding the skill + `.gitignore` line doesn't break the guard scripts, **provided** the skill docs avoid removed-Superpowers tokens | `check-companion-provenance.sh` greps **all of `skills/`** for `spec-reviewer-prompt\|code-quality-reviewer\|config/superpowers/worktrees`; lockstep only reads version markers |
| 11 | Cross-ref | Skill cross-refs resolve as `superpowers:<name>` (superpowers) / bare (toolkit) | `skills/*/SKILL.md`: `superpowers:subagent-driven-development`, bare `` `thorough-writing-plans` `` |
| 12 | Assets | `superpowers:writing-skills` (6.2.0) + `testing-skills-with-subagents.md` present | listed in the 6.2.0 plugin cache |

---

## Tasks

### Task 1: Whitelist `skills/bugfix/` in `.gitignore`

**Files:**
- Modify: `.gitignore` (skills-whitelist block, after `:42`)

- [ ] **Step 1: Add the whitelist line.** Insert `!/skills/bugfix/` immediately after `!/skills/arch-review/` (alphabetical slot).
- [ ] **Step 2: Verify.** `git check-ignore skills/bugfix/SKILL.md` now returns nothing (exit 1 — no longer ignored).
- [ ] **Step 3: Commit.**
```bash
git add .gitignore
git commit -m "build(bugfix): whitelist skills/bugfix/ for tracking"
```

> **Ordering:** this task MUST complete before any other task's commit — until the subtree is whitelisted, `git add skills/bugfix/*` is a silent no-op.

### Task 2: `status.mjs` + tests (TDD), wired into the guard suite

**Files:**
- Create: `skills/bugfix/scripts/status.mjs`, `skills/bugfix/tests/status.test.mjs`, `skills/bugfix/tests/fixtures/*.json`
- Modify: `tests/run-tests.sh`

- [ ] **Step 1: Write fixtures** covering the §4.1 rule table + prefix edge cases. Each fixture: `{ name, branches, artifacts, expected }`.
  - `branch-cut.json` — pre-design / trivial stays `branch cut`:
    ```json
    { "name": "trivial or pre-design → branch cut",
      "branches": ["  v18/bugfix/101-off-by-one"],
      "artifacts": { "specs": [], "plans": [] },
      "expected": [{ "id": "101", "branch": "v18/bugfix/101-off-by-one", "phase": "branch cut" }] }
    ```
  - `design-done.json` — design artifact present, no plan → `design done` (`specs: ["2026-07-25-102-x-design.md"]`, `plans: []`).
  - `plan-done.json` — design + plan present → `plan done`.
  - `prefixes.json` — `["* v18/bugfix/104-cur", "+ v18/bugfix/105-wt", "  v18/bugfix/106-oth"]`, empty artifacts → three `branch cut` entries, ids `104/105/106` (asserts `* `/`+ `/`  ` stripping).
- [ ] **Step 2: Write `tests/status.test.mjs`** — load every `fixtures/*.json`, call `computeStage`, `assert.deepEqual` against `expected`:
```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readdirSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { computeStage } from '../scripts/status.mjs';

const dir = join(dirname(fileURLToPath(import.meta.url)), 'fixtures');
for (const f of readdirSync(dir).filter((x) => x.endsWith('.json'))) {
  const { name, branches, artifacts, expected } = JSON.parse(readFileSync(join(dir, f), 'utf8'));
  test(name ?? f, () => assert.deepEqual(computeStage({ branches, artifacts }), expected));
}
```
- [ ] **Step 3: Run — watch it fail.** `node --test 'skills/bugfix/tests/**/*.test.mjs'` (no `status.mjs` yet → error).
- [ ] **Step 4: Implement `scripts/status.mjs`** — pure `computeStage` + I/O + CLI:
```js
#!/usr/bin/env node
// Deterministic, offline resume signal for the bugfix orchestrator (spec §4.1).
// Pure computeStage() (unit-tested) + thin git/fs I/O, mirroring the adapter's
// projectIssue()/runGh() split.
import { execFileSync } from 'node:child_process';
import { readdirSync } from 'node:fs';

// branches: raw `git branch --list <glob>` lines (may carry `* `/`+ `/`  ` prefixes)
// artifacts: { specs: string[], plans: string[] } — filenames in the configured dirs
export function computeStage({ branches, artifacts }) {
  return branches
    .map((line) => line.replace(/^[*+]?\s+/, '').trim())   // strip current/worktree markers
    .filter(Boolean)
    .map((branch) => ({ branch, id: parseId(branch) }))
    .filter((b) => b.id !== null)
    .map(({ branch, id }) => {
      const hasDesign = artifacts.specs.some((f) => f.includes(id));
      const hasPlan = artifacts.plans.some((f) => f.includes(id));
      const phase = !hasDesign ? 'branch cut' : !hasPlan ? 'design done' : 'plan done';
      return { id, branch, phase };
    });
}

// id = leading digits of the branch's last '/'-segment (GitHub numeric ids).
// Jira-style keys (PROJ-123) are deferred with the Jira provider (spec §18).
function parseId(branch) {
  const seg = branch.split('/').pop() ?? '';
  const m = seg.match(/^(\d+)/);
  return m ? m[1] : null;
}

export function gatherInputs(glob, specsDir, plansDir) {
  const branches = execFileSync('git', ['branch', '--list', glob], { encoding: 'utf8' })
    .split('\n').filter(Boolean);
  return { branches, artifacts: { specs: safeReaddir(specsDir), plans: safeReaddir(plansDir) } };
}

function safeReaddir(dir) {
  try { return readdirSync(dir); } catch { return []; }   // dirs created on first write (spec Finding 3)
}

// CLI: node status.mjs <branch-glob> <specs-dir> <plans-dir> [id]
if (import.meta.url === `file://${process.argv[1]}`) {
  const [glob, specsDir, plansDir, id] = process.argv.slice(2);
  let results = computeStage(gatherInputs(glob, specsDir, plansDir));
  if (id) results = results.filter((r) => r.id === id);
  console.log(JSON.stringify(results, null, 2));
}
```
- [ ] **Step 5: Run — watch it pass.** `node --test 'skills/bugfix/tests/**/*.test.mjs'` → green.
- [ ] **Step 6: Wire into the guard suite.** In `tests/run-tests.sh`, add before the `fail` check:
```bash
echo "== bugfix status =="; node --test 'skills/bugfix/tests/**/*.test.mjs' || fail=1
```
- [ ] **Step 7: Run the full suite.** `bash tests/run-tests.sh` → `ALL TESTS PASSED`.
- [ ] **Step 8: Commit.**
```bash
git add skills/bugfix/scripts/status.mjs skills/bugfix/tests/ tests/run-tests.sh
git commit -m "feat(bugfix): deterministic status.mjs resume script + tests"
```

### Task 3: RED — baseline skill test (`superpowers:writing-skills`)

No files committed — this establishes what the skill must teach/enforce (writing-skills' Iron Law: watch it fail first).

- [ ] **Step 1:** REQUIRED: use `superpowers:writing-skills`; read its `testing-skills-with-subagents.md`.
- [ ] **Step 2: Craft baseline scenarios matched to element type:**
  - *Discipline (pressure):* give a fresh subagent a bug + the umbrella context but **not** the bugfix skill, under mild time/sunk-cost pressure — does it skip G2 root-cause sign-off, jump to a fix without a failing test, or bypass a gate?
  - *Technique (application):* does it mis-route the tier (e.g. treat a design-only bug as trivial) or mis-sequence stages?
- [ ] **Step 3:** Run each scenario WITHOUT the skill; record verbatim the failures/rationalizations.
- [ ] **Step 4:** Distill the specific behaviors `SKILL.md`/`playbook.md` must fix (feeds Task 4). No commit.

### Task 4: GREEN — author `SKILL.md` + reference docs (`superpowers:writing-skills`)

**Files:**
- Create: `skills/bugfix/SKILL.md`, `skills/bugfix/playbook.md`, `skills/bugfix/harness-config.md`, `skills/bugfix/work-log.md`, `skills/bugfix/customizing.md`

- [ ] **Step 1: `SKILL.md`** — frontmatter `name: bugfix`; `description:` third-person, starts with "Use when…", **triggers/symptoms only — no workflow summary**, ≤ ~500 chars (frontmatter ≤ 1024). Body: overview + core principle ("conductor that delegates; human-gated"), when-to-use, `/bugfix [id]` invocation + picker, the three tiers + gates as a quick-reference table, and pointers to the flat reference docs. Keep lean.
- [ ] **Step 2: `playbook.md`** — the operational spine from spec §6: stages 0–9, the per-stage action (delegate / adapter / own-judgment), the `review ⇄ update` loop (`CDR ⇄ UDD` / `CIR ⇄ UIP` until green), the gates (§7), the needs-info loop (§6.1), and the `systematic-debugging` fork (§6/O6). Cite delegated skills as `**REQUIRED SUB-SKILL:** Use superpowers:<name>` (superpowers) or bare toolkit names — **never `@`-links** (they force-load context). Address the Task 3 baseline failures (gate-stopping, root-cause-first).
- [ ] **Step 3: `harness-config.md`** — the `.claude/bugfix.harness.md` format + the annotated Umbraco example (spec §8) + an "author your own" section.
- [ ] **Step 4: `work-log.md`** — the work-log template + hidden-marker convention (`<!-- bugfix-worklog stage=<n> -->`) and the milestone→fields table (spec §9).
- [ ] **Step 5: `customizing.md`** — the extension-points table (spec §13) + condensed decisions & rationale (the O-decisions' "why"), installer-facing.
- [ ] **Step 6: Constraint check.** None of the docs may contain `spec-reviewer-prompt`, `code-quality-reviewer`, or `config/superpowers/worktrees` (the provenance guard greps all of `skills/`). Confirm frontmatter ≤ 1024 chars.
- [ ] **Step 7: Commit.**
```bash
git add skills/bugfix/SKILL.md skills/bugfix/playbook.md skills/bugfix/harness-config.md skills/bugfix/work-log.md skills/bugfix/customizing.md
git commit -m "feat(bugfix): SKILL.md + playbook and reference docs"
```

### Task 5: REFACTOR — verify compliance, close loopholes (`superpowers:writing-skills`)

- [ ] **Step 1:** Re-run Task 3's scenarios WITH the skill: verify a subagent now stops at gates, root-causes before fixing, routes tiers correctly, and can retrieve the config/work-log formats.
- [ ] **Step 2:** For each new rationalization or gap, add an explicit counter / fix the doc; re-test until compliant (writing-skills REFACTOR).
- [ ] **Step 3:** Run `bash tests/run-tests.sh` → green (provenance passes: no forbidden tokens; lockstep unaffected).
- [ ] **Step 4: Commit any refinements** (skip if none):
```bash
git add skills/bugfix/
git commit -m "fix(bugfix): close skill-compliance gaps found in testing"
```

---

## Tasks NOT in this plan

Inherited from the spec's out-of-scope (§1) and deferred (§18) lists, plus the release step (§19.3). A new spec → plan cycle is required to add any of these:

- Building or modifying the 15 delegated skills or the tracker adapter (each has its own home).
- The one-line adapter-docs clarification (spec Finding 1 / §17) — folded when the `tracker-adapter` branch is next touched, not here.
- `listCandidates` / any tracker-side "list my in-flight bugs" query (deferred with the adapter).
- Browser-automation tooling for UI bugs — `repro_verify` is a documented seam; the base ships automated-test + manual fallback only.
- The autonomy dial (gates are the future dial).
- The Jira provider (adapter's documented, unbuilt slot) — including Jira-style (`PROJ-123`) id parsing in `status.mjs`.
- The coordinated **release version bump** (`plugin.json` / `README.md` / `CHANGELOG.md` + provenance-manifest/target sync) — a separate release step; adding the skill alone keeps `run-tests.sh` green (A10).

## Known issues inherited from spec

From spec §17 (Findings folded in), the following are **handled within this plan** (not deferred), noted here for traceability:

- **Finding 2** — `status.mjs` strips the `+ ` (worktree) and `* ` (current) prefixes from `git branch --list` output (Task 2, `computeStage` strip regex + `prefixes.json` fixture).
- **Finding 3** — harness artifact dirs need not pre-exist; `status.mjs`'s `safeReaddir` returns `[]` for a missing dir (Task 2).
