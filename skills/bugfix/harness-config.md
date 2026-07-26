# Harness configuration

Everything project-specific lives in one human-authored file, `.claude/bugfix.harness.md`, in the **target** repo — never in the skill. The orchestrator reads it on every invocation and **echoes the resolved values at G1** for the human to confirm (this catches drift). It passes `branch` (as a glob) and the `artifacts` dirs to `status.mjs` as CLI args, keeping the script a pure function of its inputs.

The generic core is parameterized by this small config; if a value would only ever be true for one project, it belongs here, not in the core.

## Format

A markdown file with a fenced config block. The keys:

| Key | Meaning |
|---|---|
| `tracker` | The adapter provider slot — `github` is the reference implementation. |
| `status_labels` | Map of workflow status → native tracker label. **List only statuses that have a native label**; the rest fall back to a comment (the adapter handles this). |
| `branch` | Branch-name template (a glob after substitution) — passed to `status.mjs` and to `using-git-worktrees` at Stage 3. |
| `major_from` | Optional: file the major version is read from, when the branch template needs it. |
| `pr.title` | PR title template. |
| `pr.closing_keyword` | The issue-closing keyword — must go **on its own line in the PR body**; a title suffix alone won't auto-close. |
| `format` | The project's formatter/linter command (Stage 7). |
| `test` | The project's test command (Stage 7). |
| `review_skill` | Optional project-specific review skill (Stage 8). Omit if none. |
| `artifacts.specs` / `artifacts.plans` / `artifacts.reviews` | Target dirs for design / plan / adversarial-review artifacts. **Created on first write — they need not pre-exist.** |
| `repro_verify` | Reproduction/verification seam: `auto` (project test suite) by default; `browser` / `manual` are documented variants for UI bugs. |

## Annotated Umbraco example

Every value below is verified against the Umbraco harness. Copy this as a starting point and edit the values for your project.

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

repro_verify: auto                           # auto = project test suite; browser/manual are documented seams
```

Notes on the example:
- **`done` is not a label.** Issue closing is delegated to the PR closing keyword at Stage 9, not to a status label — so `status_labels` lists only `needs-info` here.
- **`in-progress` / `in-review`** have no native GitHub issue status and no label defined in this repo, so they degrade to the adapter's comment fallback — nothing is silently lost.
- **Artifact dirs** need not exist up front; `thorough-brainstorming` / `thorough-writing-plans` create them on first write. (In Umbraco today only `docs/criticalreviews/` exists.)

## Author your own

1. **Copy the Umbraco block** above into `.claude/bugfix.harness.md` in your repo.
2. **`tracker`** — set to your provider slot (`github` is built; `jira` and others are documented adapter slots).
3. **`status_labels`** — map only the statuses your tracker represents natively; drop the rest and let the comment fallback carry them.
4. **`branch` / `pr`** — set to your project's conventions. Keep the closing keyword on its own body line.
5. **`format` / `test`** — your real commands. A Node project might use `npm run lint` / `npm test` and a `fix/{id}-{desc}` branch; a Python project `ruff format` / `pytest`. None of this touches the core.
6. **`artifacts`** — where design/plan/review docs should land in your repo, following your conventions.
7. **`repro_verify`** — leave `auto` unless you have a UI/E2E stack to plug in (`browser`) or genuinely no automated path (`manual`; see the honest-fallback rule in playbook.md Stage 3).

The config file is itself a seam: the orchestrator reads it, so a customizer changes behavior by editing values here — never by editing skill code.
