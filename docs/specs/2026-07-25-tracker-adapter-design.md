# Tracker Adapter — Design

**Date:** 2026-07-25
**Home:** Peter's Toolkit (`~/peters-toolkit`). Ships as a new toolkit skill.
**Parent spec:** `docs/specs/2026-07-25-bug-fixing-workflow-design.md` (the umbrella bug-fixing workflow). This document resolves the adapter forks that spec deliberately left open (its §6).
**Test harness:** Umbraco CMS (`~/Umbraco-CMS`) — first project exercised. GitHub via `gh` CLI is the reference provider.
**Status:** Design approved (pending `critical-design-review`). Build follows as its own plan → build cycle.
**Storage:** Git-ignored working file (the toolkit repo tracks only shippable plugin files).

---

## 1. Purpose & scope

The tracker adapter is the **only tracker-specific part** of the bug-fixing workflow — a thin edge at ingest and writeback that projects an arbitrary tracker's fields onto one normalized `Ticket` model and maps four abstract writeback verbs onto concrete tracker actions. Everything between the two edges is tracker-agnostic (umbrella §3).

This spec defines the adapter's **form, invocation contract, per-verb GitHub mapping, status model, file layout, and test approach** — enough to plan and build the GitHub reference provider.

**In scope:**

- The adapter's realization: an executable Node script + a thin contract skill + per-provider reference docs.
- The invocation contract the orchestrator calls.
- The concrete `gh` command and `Ticket` projection for each implemented verb.
- The advisory-status / comment-fallback model, concretely (umbrella D11).
- The `.gitignore` whitelist line and file layout.
- GitHub as the reference provider; Jira as a documented, unbuilt slot.

**Out of scope (deliberately):**

- The `bugfix` orchestrator (its own spec → plan → build cycle). This spec only defines the interface the orchestrator will call.
- `listCandidates` implementation — deferred (§9). Documented as a contract slot only; the entry model is "developer invokes the orchestrator with a specific bug id."
- Building the Jira provider — stub + reference doc only.
- Parsing enriching fields GitHub has no native source for (severity, attachments, related links) — left empty in v1 (§5, verified A6).

---

## 2. Decisions (locked, with rationale)

| # | Decision | Rationale |
|---|----------|-----------|
| TA1 | **Executable script, not a declarative skill.** The adapter's job is mechanical projection/I-O at a boundary — the one workflow component that is plumbing, not judgment. | Determinism (byte-identical ingest every run; a dropped comment at ingest silently corrupts RCA downstream), zero model-token cost per ticket, and unit-testability. The toolkit's other skills are LLM skills because they do judgment; the adapter does I/O. |
| TA2 | **Node, stdlib only.** Implementation is a Node script using `node:child_process` + `JSON`; tests use the built-in `node:test` runner. | Claude Code is itself a Node process, so Node is present by construction wherever the skill runs; the toolkit already ships Node scripts; `node:test` means zero external test deps. Python would add a second scripting runtime to the plugin. (Verified A7, A8.) |
| TA3 | **Thin contract skill wraps the script.** A `SKILL.md` carries the invocation contract + the non-mechanical policy (status model, needs-info checklist); the script is the implementation; `references/` documents the per-provider mapping. | Some of the adapter's job isn't mechanical (the D11 policy, what config it needs). That residue must live where the orchestrator will read it. The script alone can't be a discoverable skill. |
| TA4 | **No `--repo` flag; operate on the current repo.** `gh` infers the repository from the cwd's git remote, exactly like every other skill. | The developer is always cd'd into the repo they're fixing; passing a repo is ceremony. The Umbraco harness already relies on cwd inference (`umb-review` runs `gh pr view` with no `-R`). (Verified A3.) |
| TA5 | **The only injected config is an optional `--label` on `setStatus`.** Label present → apply that label; absent → comment fallback. | Splits D10/D11 cleanly: the *mechanism* (labels-else-comment) is tracker knowledge and stays in the adapter; the *label name* (`state/needs-investigation`) is harness config the orchestrator holds. The adapter reads no files and stays a pure function of its inputs. |
| TA6 | **`done` and `linkPullRequest` degrade to comments on GitHub.** `done` never hard-closes the issue; `linkPullRequest` posts a comment. | GitHub has no issue-side status or link API, and closing is delegated to the PR closing-keyword on merge (umbrella §5) — the adapter closing the issue itself would close it prematurely. Both fall through the generic no-label→comment path; no special-casing needed. |
| TA7 | **`getTicket` is a faithful, complete dump.** It returns all comments and fields raw, with no interpretation. | "Which comment holds the repro steps?" is judgment that belongs in the workflow's LLM stages (triage/RCA), never in the adapter. This both justifies the script and draws the boundary. |

---

## 3. Component shape & file layout

```
skills/tracker-adapter/
  SKILL.md                    # invocation contract + status/needs-info policy + required harness config
  scripts/
    adapter.mjs               # entry point: dispatch <provider> <verb> [args]
  references/
    github.md                 # exact gh command + Ticket projection per verb (reference provider)
    jira.md                   # documented-but-unbuilt slot: intended mapping sketch
  tests/
    project.test.mjs          # node:test over recorded fixtures (pure projection; no live gh)
    fixtures/
      issue-view.json         # a recorded `gh issue view --json …` sample
```

**`.gitignore` change** (one line, in the skills-subtree whitelist block):

```
!/skills/tracker-adapter/
```

Verified (A9): a `!/skills/<name>/` line recursively tracks the skill's subdirs — existing `skills/sproc-xray/references/**` and `skills/thorough-brainstorming/scripts/**` are tracked with exactly this pattern.

**Code structure for testability:** the script separates a **pure `projectIssue(ghJson) → Ticket`** function (unit-tested against fixtures, no I/O) from a thin **`runGh(args) → stdout`** wrapper (the only part that shells out). This is what makes the adapter testable without `gh` in the environment (see §7).

---

## 4. Invocation contract

```
node scripts/adapter.mjs <provider> <verb> [verb-args…]
```

- **provider:** `github` (implemented) | `jira` (stub, exits nonzero `not_implemented`).
- **stdout:** JSON result on success. **exit 0** = success.
- **failure:** nonzero exit with `{"error": "<message>", "code": "<slug>"}` on stdout so the orchestrator can parse it. Error codes: `gh_error` (underlying `gh` failed — message carries `gh` stderr), `unknown_provider`, `unknown_verb`, `not_implemented`, `bad_args`.
- The adapter reads **no files** and holds **no ambient config** beyond what `gh` itself infers (the repo, from cwd). It is a pure function of its arguments + the cwd repo.

| Verb | Args | Success output |
|------|------|----------------|
| `getTicket` | `<id>` | `Ticket` JSON object |
| `assign` | `<id> <who>` (`who` typically `@me`) | `{"ok": true}` |
| `setStatus` | `<id> <name> [--label <label>]` | `{"ok": true, "via": "label"\|"comment"}` |
| `comment` | `<id>` (+ markdown on **stdin**) | `{"ok": true, "url": "<comment-url>"}` |
| `linkPullRequest` | `<id> <url>` | `{"ok": true}` |
| `listCandidates` | — | **deferred** — exits `not_implemented` (§9) |

---

## 5. Verb → `gh` mapping (GitHub reference provider)

All flags verified against the official `gh` manual (A2, A4, A5) and, for repo inference, an existing harness callsite (A3).

### Read

**`getTicket(id)`**

```
gh issue view <id> --json number,title,body,comments,labels
```

`projectIssue(ghJson) → Ticket` (the `Ticket` shape is defined by the umbrella §5 — this projection conforms to it exactly, adding no fields):

| Ticket field | Source | Notes |
|--------------|--------|-------|
| `id` | `number` | issue number (stable within the repo) |
| `title` | `title` | |
| `body` | `body` | |
| `comments[]` | `comments[]` → `{author, body, createdAt}` | full array, faithful dump (TA7) |
| `labels[]` | `labels[].name` | flattened to names |
| `severity?` | — | **empty** — GitHub has no native severity field (A6) |
| `attachments[]` | — | **empty** — no native field (A6) |
| `links[]` | — | **empty in v1** — no structured field; `#`-ref parsing deferred (A6) |

### Write

| Verb | `gh` command |
|------|--------------|
| `assign(id, who)` | `gh issue edit <id> --add-assignee <who>` (`@me` supported) |
| `setStatus(id, name, --label L)` | `gh issue edit <id> --add-label <L>` |
| `setStatus(id, name)` *(no label)* | `gh issue comment <id> --body-file -` with body `→ <name>` |
| `comment(id, md)` | `gh issue comment <id> --body-file -` (markdown via stdin — avoids arg-length/escaping issues) |
| `linkPullRequest(id, url)` | `gh issue comment <id> --body "Linked PR: <url>"` |

**Close-on-merge is not an adapter action.** It is delegated to GitHub's native PR linkage — the closing keyword (`Fixes #<id>`) in the PR body, emitted at workflow Stage 9, not here (umbrella §5).

---

## 6. Status model (D11, concrete)

`setStatus` is **advisory and one-way** — the core never reads a status back to branch on it. The adapter resolves each abstract status through a single uniform rule:

> **`--label` given → add that label. No `--label` → post a comment `→ <name>`.**

Mapping for the four workflow statuses, as the Umbraco harness will drive them:

| Abstract status | Umbraco harness call | Native mechanism |
|-----------------|----------------------|------------------|
| `needs-info` | `setStatus <id> needs-info --label state/needs-investigation` | label (verified real, A11) |
| `in-progress` | `setStatus <id> in-progress` | comment fallback (`→ in-progress`) |
| `in-review` | `setStatus <id> in-review` | comment fallback (`→ in-review`) |
| `done` | `setStatus <id> done` | comment fallback (`→ done`) — never closes (TA6) |

No status is ever silently lost: comments are the mechanical tier every tracker has, so a status with no configured label degrades gracefully to a comment rather than breaking the run. The label *names* are harness config held by the orchestrator; the adapter only knows the mechanism.

### Needs-info checklist (umbrella §4.1)

The SKILL.md carries the "required to proceed" checklist verbatim from the umbrella contract (expected behavior; actual/symptom incl. error/stack; reproducibility context) so the orchestrator can post exactly the missing items when it drives `setStatus … needs-info`. This is policy text in the skill, not logic in the script.

---

## 7. Testing approach

- **Runner:** `node:test` (built-in; zero external deps — A7).
- **What is tested:** the pure `projectIssue(ghJson) → Ticket` function, against a recorded `gh issue view --json …` fixture (`tests/fixtures/issue-view.json`). Assertions cover: id/title/body mapping, full comment-array passthrough, label flattening, and that `severity`/`attachments`/`links` are empty.
- **Why fixtures, not live `gh`:** `gh` is a harness/runtime dependency and is **not present in every environment** (it was absent from the design sandbox — A1). Fixture-based tests make the adapter's projection verifiable anywhere Node runs. The thin `runGh` I/O wrapper is not unit-tested against a live API.
- **Live end-to-end** validation (real self-assign, comment, label on a throwaway issue) happens in the developer's authed environment during the build, and is recorded in the build's verification step — not in the shipped test suite.

---

## 8. Jira slot (documented, unbuilt)

`provider = jira` exits nonzero with `{"error": "provider 'jira' not implemented", "code": "not_implemented"}`. `references/jira.md` sketches the intended mapping so the extensibility is proven by shape, built by nobody:

| Verb | Intended Jira mechanism |
|------|-------------------------|
| `getTicket` | `GET /rest/api/3/issue/{key}` → project fields onto `Ticket` |
| `assign` | `PUT …/issue/{key}/assignee` |
| `setStatus` | issue **transitions** (`POST …/issue/{key}/transitions`); comment fallback where no transition matches |
| `comment` | `POST …/issue/{key}/comment` |
| `linkPullRequest` | remote issue link or smart-commit on merge |

---

## 9. Deferred / not built

- **`listCandidates`** — the "pick the next bug" entry mode. Its only consumer is a future orchestrator entry-path that doesn't exist yet; the current entry model is "developer invokes with a specific bug id" (per the user). Documented as a contract slot; **not implemented in v1** (avoids building a verb no consumer calls).
- **Enriching-field parsing** — deriving `links[]` from `#`-refs in the body, or `severity` from a label convention. Left empty; add if a stage actually needs it.
- **Jira provider** — stub + reference doc only.

---

## 10. Build vs reuse

**Build (this cycle):** `skills/tracker-adapter/` — `adapter.mjs` (dispatch + `projectIssue` + `runGh` + the five implemented verbs + jira stub), `SKILL.md` (contract + status/needs-info policy), `references/github.md`, `references/jira.md`, `tests/project.test.mjs` + fixture, and the `.gitignore` whitelist line.

**Reuse:** nothing — the adapter is genuinely new code (it's the plumbing the rest of the workflow delegates *to*). `gh` is the external dependency; no toolkit skill is invoked by the adapter.

---

## 11. Verified assumptions

Checked on 2026-07-25 before finalizing this spec:

- **A1 — `gh` present + authenticated (environmental).** ✅ `gh` v2.46.0 is installed in the VM and **authenticated for reads** (token supplied via `~/.netrc`, `read` scope; sufficient for `gh api`/`gh issue view`). Read API calls are now run-verified (A2/A6). It is a harness dependency (umbrella §7 "GitHub via `gh` CLI"). Still pending build: the **live write smoke test** (self-assign/comment/label) needs a repo the token can write to (a fork/throwaway, not `umbraco/Umbraco-CMS`). The fixture-based test approach (§7) means the shipped tests don't depend on auth regardless.
- **A2 — `gh issue view --json` fields.** ✅ **run-verified** against live gh 2.46.0 (`gh issue view … --json bogusfield` field-list probe, authed). The fields `getTicket` fetches (`number, title, body, comments, labels`) are all present; the full field set is `assignees, author, body, closed, closedAt, comments, createdAt, id, labels, milestone, number, projectCards, projectItems, reactionGroups, state, title, updatedAt, url` (`assignees`/`state`/`url` present but unused in v1).
- **A3 — repo inference from cwd.** ✅ Confirmed by existing callsite `Umbraco-CMS/.claude/skills/umb-review/SKILL.md:28` (`gh pr view --json baseRefName` with no `-R`).
- **A4 — `gh issue edit` flags.** ✅ run-verified against installed gh 2.46.0: `--add-assignee login` ("Use \"@me\" to assign yourself") and `--add-label name`.
- **A5 — `gh issue comment` body.** ✅ run-verified against installed gh 2.46.0: `-b, --body` and `-F, --body-file` ("use \"-\" to read from standard input").
- **A6 — no native enriching fields.** ✅ **run-verified** against the live field list (A2): no `severity`, no `attachments`, no free-form `links` anywhere in the field set; leaving those Ticket fields empty is faithful.
- **A7 — Node + `node:test`.** ✅ Node v24.18.0; `require('node:test')` succeeds (floor is ≥18).
- **A8 — Node-script precedent, no runtime pin.** ✅ Toolkit ships `thorough-brainstorming/scripts/{helper.js,server.cjs}`; no root `package.json`/engines pin to conflict with a new `.mjs`.
- **A9 — `.gitignore` recursion.** ✅ `git ls-files` shows `skills/sproc-xray/references/**` and `skills/thorough-brainstorming/scripts/**` tracked — one `!/skills/tracker-adapter/` line suffices.
- **A10 — no name collision.** ✅ No `tracker`/`adapter` skill in `skills/`.
- **A11 — `state/needs-investigation` real.** ✅ Only `state/*` label in `Umbraco-CMS/.github/` (`issue-deduplication.yml`).

---

## 12. Next steps

1. `critical-design-review` against this spec (the team's adversarial-review discipline).
2. `thorough-writing-plans` → `critical-implementation-review` → build the `tracker-adapter` skill.
3. Add the `!/skills/tracker-adapter/` whitelist line as part of the build.
4. Live end-to-end smoke test in the Umbraco harness (self-assign, comment, needs-info label on a throwaway issue).
5. Proceed to the `bugfix` orchestrator's own spec → plan → build cycle, consuming this adapter's invocation contract (§4).
