# Critical Implementation Review: 2026-07-25-orchestrator-implementation-plan (Round 1)

**Plan:** `/home/yv01p/peters-toolkit/docs/plans/2026-07-25-orchestrator-implementation-plan.md`
**Verified plan-level assumptions section:** present

⚠️ 3 commits since plan-write time (spec SHA `3e329c0`); cited file:line references re-checked under §1. (All three — `07b64ab` the plan itself, `ddc0b39`/`cad544c` CDR round-4/3 review artifacts — leave the source spec untouched; `git log 3e329c0..HEAD -- docs/specs/2026-07-25-orchestrator-design.md` is empty. No spec drift.)

## 1. Verified-plan-assumptions cross-check

Fresh read of each assumption's cited evidence:

1. **`skills/bugfix/` is a new dir** — still holds. `ls -d skills/bugfix` → absent.
2. **`.gitignore` skills block exists; `bugfix` unlisted; alphabetical slot after `arch-review`** — still holds. `.gitignore:41` `/skills/*`; whitelist `:42–53`; `:42` `!/skills/arch-review/`, `:43` `!/skills/cobol-xray/` (so `bugfix` inserts between them, alphabetically); `grep bugfix .gitignore` → absent.
3. **Skill supporting docs are flat at skill root (no `references/`); `scripts/`/`tests/` are purpose-dirs** — still holds. `find skills -type d -name references` → none; `thorough-brainstorming/` shows flat `visual-companion.md` + `scripts/`.
4. **`status.mjs` mirrors the adapter's pure/IO split** — still holds. On branch `tracker-adapter`, `skills/tracker-adapter/scripts/adapter.mjs:6` `export function projectIssue(gh)` (pure) and `:24` `function runGh(args, input)` (I/O). (Minor evidence nuance from the fresh read: `runGh` at `:24` is defined but not `export`ed — only `projectIssue` is exported. The pure/IO *split* the assumption relies on is nonetheless present, and `status.mjs`'s `computeStage`(pure)/`gatherInputs`(I/O) mirrors it.)
5. **Tests run via `node --test`; `tests/run-tests.sh` is the hermetic guard entry; zero `*.test.mjs` in repo** — still holds. `run-tests.sh` runs `provenance` + `lockstep` only; `find . -name '*.test.mjs'` → none. (The abstract assumption "tests run via `node --test`" holds; the specific *command form* the tasks use is defective — see §2 Finding 1. That is a task-level bug, not a falsification of this assumption.)
6. **Commit convention = conventional commits** — still holds. `git log` shows `feat(uip):`, `docs(...):`, `build:`, `release:` → `feat(bugfix):`/`build(bugfix):` fit.
7. **`.gitignore` whitelist (Task 1) must precede all `skills/bugfix/` commits** — still holds. `git check-ignore skills/bugfix/SKILL.md` → matches (currently ignored by `/skills/*`), exit 0; confirms the subtree is invisible to `git add` until whitelisted.
8. **Node v24.18.0 supports `node:child_process`/`node:fs` ESM + `node --test` on `.mjs`** — still holds. `node --version` → v24.18.0; `node --test` on `.mjs` verified running (see §2 for the invocation-form caveat).
9. **`git branch --list` prefixes match the strip regex `/^[*+]?\s+/`** — still holds. `git branch` shows `* publish-artifacts` and two-space-prefixed `  main`/`  sproc-xray`/`  tracker-adapter`; regex strips `* `, `+ ` (A6), and `  `.
10. **Adding the skill + `.gitignore` line doesn't break the guards, provided the docs avoid removed-Superpowers tokens** — still holds. `check-companion-provenance.sh:13` greps `spec-reviewer-prompt|code-quality-reviewer|config/superpowers/worktrees` across `skills README.md CHANGELOG.md`; lockstep reads only version/target markers. Task 4 Step 6's constraint check covers the token avoidance.
11. **Skill cross-refs resolve as `superpowers:<name>` (superpowers) / bare (toolkit)** — still holds. Existing `SKILL.md`s use `superpowers:subagent-driven-development` etc. and bare backticked `` `thorough-writing-plans` ``/`` `critical-design-review` ``.
12. **`superpowers:writing-skills` (6.2.0) + `testing-skills-with-subagents.md` present** — still holds. Found at `~/.claude/plugins/cache/claude-plugins-official/superpowers/6.2.0/skills/writing-skills/testing-skills-with-subagents.md`.

## 2. Literal-wrongness findings

**Finding 1 — `node --test <dir>` does not discover tests on the target Node runtime; the plan's test command is broken.**

- **Description.** Task 2 invokes the test runner as `node --test skills/bugfix/tests/` in Step 3 (RED), Step 5 (GREEN), and Step 6 (the line wired into `tests/run-tests.sh`); the File-Structure entry (plan line 29) and Task 5 Step 3 (`bash tests/run-tests.sh`) inherit the same form transitively. On the plan's target runtime — Node v24.18.0, per assumption 8 — passing a **directory** to `node --test` does **not** trigger test-file discovery. Node resolves the path as a module entry point, fails to load it, and aborts with `MODULE_NOT_FOUND` (exit 1) **before any test in the directory runs**.
- **Why this breaks the spec's stated outcome.** The plan's deliverable for Task 2 is a passing `status.mjs` test wired green into the hermetic guard suite. With the directory form:
  - **Step 5 ("Run — watch it pass") can never go green.** Even with a correct `status.mjs` and `status.test.mjs`, `node --test skills/bugfix/tests/` errors on the directory path, so the TDD GREEN gate is unreachable — the plan cannot progress past Step 5 as written.
  - **Step 6's wired line `node --test skills/bugfix/tests/ || fail=1` always sets `fail=1`**, so `bash tests/run-tests.sh` (Step 7, and again Task 5 Step 3) never prints `ALL TESTS PASSED`. The guard suite is left permanently red — the opposite of the stated Step 7 outcome.
  - **Step 3 ("Run — watch it fail") exits non-zero for the wrong reason** — `MODULE_NOT_FOUND` on the directory path, not "`status.mjs` doesn't exist yet." The RED signal the TDD loop depends on is spurious (it would "fail" identically even if `status.mjs` were already correct), defeating the point of watching it fail first.
- **Evidence (empirical, on the exact target version v24.18.0).**
  - `node --test skills/bugfix/tests` and `node --test skills/bugfix/tests/` (relative *and* absolute path, with/without trailing slash) → `Error: Cannot find module '.../skills/bugfix/tests'` … `code: 'MODULE_NOT_FOUND'`, `pass 0 / fail 1`, exit 1.
  - Working forms on the same version, same fixture layout, invoked from repo-root cwd (as `run-tests.sh` is): `node --test 'skills/bugfix/tests/**/*.test.mjs'` → `pass 1 / fail 0`, exit 0; `node --test skills/bugfix/tests/status.test.mjs` (explicit file) → exit 0; `node --test` (no path args, cwd-recursive discovery) → exit 0.
- **Proposed fix.** Replace every `node --test skills/bugfix/tests/` occurrence (plan lines 29, 126, 178, and the wired line at 181) with a form that works on Node ≥ 24. Recommended: the quoted recursive glob **`node --test 'skills/bugfix/tests/**/*.test.mjs'`** — Node-expanded (quote it so the shell doesn't), scoped to the bugfix tests, and it keeps working when a second `*.test.mjs` is later added. Acceptable alternatives: the explicit file `node --test skills/bugfix/tests/status.test.mjs` (must be extended by hand when a second test file appears), or the shell-expanded `node --test skills/bugfix/tests/*.test.mjs`. Use the identical chosen form in the Step 6 `run-tests.sh` line so the guard-suite invocation matches the Step 3/5 commands. (Because the repo has no CI and `run-tests.sh` is only ever run as `bash tests/run-tests.sh` from repo root, the added line's repo-root-relative path is fine as-is — no `$ROOT`/`cd` change is required for correctness.)

## 3. Forced decisions

No forced decisions found.

## 5. Recommendation

⚠️ **Approve with literal-wrongness fixes.** §1 has no failed assumptions and §3 is empty, but §2 Finding 1 is a genuine execution-time break: the plan's `node --test <dir>` command cannot reach green on the target Node version, so Task 2's GREEN step and the guard-suite wiring (and Task 5's re-run) fail as written. Apply the Finding 1 fix (swap the directory form for the glob/explicit-file form at plan lines 29, 126, 178, 181) — via `update-implementation-plan` or a manual edit — before running `subagent-driven-development`. No design or forced-decision issues block forward progress once that command form is corrected.
