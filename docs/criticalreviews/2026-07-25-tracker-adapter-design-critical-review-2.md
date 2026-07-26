# Critical Design Review: 2026-07-25-tracker-adapter-design (Round 2)

**Spec:** `~/peters-toolkit/docs/specs/2026-07-25-tracker-adapter-design.md`
**Verified Assumptions section:** present

## 1. Verified-assumptions cross-check

Re-checked against cited evidence (unchanged since round 1; several run-verified live this session with `gh` authenticated for reads):

- **A1 — `gh` present + authenticated.** ✅ `gh` v2.46.0; `gh api user` → `yv01p`. Write smoke test correctly deferred to build against a writable repo.
- **A2 — `gh issue view --json` fields.** ✅ Run-verified field list; `number, title, body, comments, labels` present.
- **A3 — repo inference from cwd.** ✅ `umb-review/SKILL.md` uses `gh pr view --json baseRefName` with no `-R`.
- **A4 — `gh issue edit` flags.** ✅ `--add-assignee` (`@me`), `--add-label`.
- **A5 — `gh issue comment` body.** ✅ `--body`, `--body-file -` (stdin).
- **A6 — no native enriching fields.** ✅ No `severity`/`attachments`/`links` in the field set.
- **A7 — Node + `node:test`.** ✅ v24.18.0; `node:test` OK.
- **A8 — Node-script precedent, no runtime pin.** ✅ `thorough-brainstorming/scripts/` present; no root `package.json`.
- **A9 — `.gitignore` recursion.** ✅ `sproc-xray/references/*` and `thorough-brainstorming/scripts/*` tracked.
- **A10 — no name collision.** ✅ No `tracker`/`adapter` skill.
- **A11 — `state/needs-investigation` real.** ✅ Only `state/*` label in `Umbraco-CMS/.github/`.

All verified assumptions reconfirmed.

## 2. Literal-wrongness findings

No literal-wrongness findings.

The round-1 finding (F1 — §7 asserting `state`/`url` mapping) is resolved in the current spec; see §4. Re-scan of the full spec against the umbrella contract surfaced no new literal-wrongness:

- The `done` status is consistent across specs: adapter `setStatus done` posts an advisory `→ done` comment and never closes (TA6, §6); the closed-issue *outcome* is delegated to the PR closing keyword at Stage 9 (§5:135), which is exactly what umbrella §5/§7/§9 mandate. No contradiction.
- Load-bearing negative claims hold: GitHub exposes no native issue-side workflow-status or PR-link API (only open/closed `state`, confirmed in the A2 field list) → comment-degradation is faithful; `listCandidates` has no current consumer (the orchestrator is unbuilt, umbrella §6/§12) → deferral is safe; no root `package.json` → a new `.mjs` has no engines pin to conflict with.
- The §5 projection, §5 `getTicket` command, and §7 assertion list are now mutually consistent (all cover exactly `id, title, body, comments, labels` + empty `severity`/`attachments`/`links`).

## 3. Forced decisions

No forced decisions found.

## 4. Previously addressed

- **F1 (round 1) — §7 asserted mapping of `state`/`url`, fields absent from the `Ticket` contract.** Resolved: §7 line 165 now reads "Assertions cover: **id/title/body mapping**, full comment-array passthrough, label flattening, and that `severity`/`attachments`/`links` are empty." This matches the §5 projection table and the umbrella `Ticket` shape.

## 5. Recommendation

✅ **Approve as-is.** §2 and §3 are both empty; the sole round-1 finding is resolved. The spec is ready for implementation planning (`thorough-writing-plans`).
