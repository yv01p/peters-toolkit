# Tracker Adapter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Source spec:** `docs/specs/2026-07-25-tracker-adapter-design.md` (uncommitted at plan-write time — spec is a git-ignored working file; repo HEAD = `6d36d76`). Parent/umbrella authority for the `Ticket` shape + verb vocabulary: `docs/specs/2026-07-25-bug-fixing-workflow-design.md:123`.

**Goal:** Build the GitHub reference provider of the tracker adapter — the only tracker-specific edge of the bug-fixing workflow — as an executable Node script, a thin contract skill, and per-provider reference docs.

**Architecture:** A single ESM script (`adapter.mjs`) separating a pure `projectIssue(ghJson) → Ticket` function (unit-tested against a recorded fixture, no I/O) from a thin `runGh(args, input) → stdout` wrapper (the only part that shells to `gh`). A `SKILL.md` carries the invocation contract + the non-mechanical policy (status model, needs-info checklist); `references/` documents the per-provider mapping. The adapter reads no files and holds no ambient config beyond `gh`'s own cwd repo inference plus an optional `--label` on `setStatus`.

**Tech stack:** Node ESM, stdlib only — `node:child_process` (execFileSync), `node:url` (pathToFileURL), `node:test` + `node:assert/strict` for tests. `gh` CLI is the external dependency. No third-party packages, no new runtime (spec TA2; verified assumptions A7/A8).

---

## Global Constraints

Project-wide rules every task must hold to:

- **Ship-only tracking.** The toolkit repo `.gitignore` denylists everything (`/*`) then whitelists shippable plugin files. Only files under a whitelisted `!/skills/<name>/` path (plus `.claude-plugin/`, README/CHANGELOG/LICENSE, `/tests/`) are committable. `docs/**` and `handoffs/**` are git-ignored working files — never `git add -f` them.
- **A new skill's subtree is untracked until its whitelist line exists.** `skills/tracker-adapter/**` is currently ignored by `.gitignore:15` (`/skills/*`). The `!/skills/tracker-adapter/` whitelist line MUST be added before the first `git add` of any skill file, or `git add` silently skips the ignored paths. (This is why Task 1 adds the whitelist as its first step.)
- **Do not reintroduce removed-Superpowers-path tokens.** The provenance guard (`tests/provenance/check-companion-provenance.sh:13`) greps `skills/` for `spec-reviewer-prompt|code-quality-reviewer|config/superpowers/worktrees` and fails if any reappears. The new skill's text must contain none of these.
- **No version bump / README / CHANGELOG edits.** Publishing a skill in this repo touches only `.gitignore` + the skill's own files (precedent: `sproc-xray` publish, commit `6d36d76`). The version-lockstep guard does not enumerate skills, so it stays green untouched.
- **Commit convention:** Conventional Commits with a scope, e.g. `feat(tracker-adapter): …`. Stage specific paths (never `git add -A`/`-.`). End commit messages with the repo's `Co-Authored-By` trailer.

## File Structure

**Create (skill subtree):**
- `skills/tracker-adapter/scripts/adapter.mjs` — entry point: dispatch `<provider> <verb> [args]`; pure `projectIssue`; `runGh` I/O wrapper; the five implemented verbs + jira stub + `listCandidates` deferral.
- `skills/tracker-adapter/tests/project.test.mjs` — `node:test` over the fixture; asserts the pure projection only.
- `skills/tracker-adapter/tests/fixtures/issue-view.json` — a recorded-shape `gh issue view --json …` sample (shape verified against `umbraco/Umbraco-CMS#23464`).
- `skills/tracker-adapter/SKILL.md` — invocation contract + status/needs-info policy + required harness config.
- `skills/tracker-adapter/references/github.md` — exact `gh` command + `Ticket` projection per verb (reference provider).
- `skills/tracker-adapter/references/jira.md` — documented-but-unbuilt slot: intended mapping sketch.

**Modify:**
- `.gitignore` — add one whitelist line `!/skills/tracker-adapter/` (alphabetical slot: after `!/skills/tma/`, before `!/skills/update-design-doc/`).

## Inherited from spec

Verified by `thorough-brainstorming` at spec-write time (spec §11) and by `critical-design-review` (rounds 1–2, ✅ approve as-is). Trusted as ground truth; NOT re-verified here:

- **A1** — `gh` v2.46.0 present + authenticated for reads (harness dependency).
- **A2** — `gh issue view --json` exposes `number, title, body, comments, labels` (full set also has `assignees, closed, closedAt, createdAt, id, milestone, projectCards, projectItems, reactionGroups, state, updatedAt, url` — unused in v1).
- **A3** — `gh` infers the repo from cwd (no `-R`); precedent `Umbraco-CMS/.claude/skills/umb-review/SKILL.md:28`.
- **A4** — `gh issue edit` supports `--add-assignee <login>` (`@me` supported) and `--add-label <name>`.
- **A5** — `gh issue comment` supports `-b, --body` and `-F, --body-file` (`-` = stdin).
- **A6** — GitHub has no native `severity`/`attachments`/free-form `links` field → those `Ticket` fields stay empty faithfully.
- **A7** — Node ≥18 with built-in `node:test` (env is v24.18.0).
- **A8** — Node-script precedent in the toolkit (`thorough-brainstorming/scripts/`); no root `package.json`/engines pin to conflict with a new `.mjs`.
- **A9** — one `!/skills/<name>/` line recursively tracks the skill's subdirs (`sproc-xray/references/**`, `thorough-brainstorming/scripts/**` tracked via exactly this pattern).
- **A10** — no `tracker`/`adapter` name collision in `skills/`.
- **A11** — `state/needs-investigation` is a real Umbraco label.
- **`Ticket` shape** (umbrella §5, `docs/specs/2026-07-25-bug-fixing-workflow-design.md:123`): `{ id, title, body, comments[], labels[], severity?, attachments[], links[] }` — the projection conforms exactly, adding no fields.

## Verified plan-level assumptions

Newly introduced by this plan (paths, signatures, commands, ordering, consumer impact), verified at plan-write time (2026-07-25, repo HEAD `6d36d76`, Node v24.18.0):

| # | Category | Assumption | Evidence |
|---|----------|-----------|----------|
| 1 | File path | `skills/tracker-adapter/` does not exist — all files are new (Create, not overwrite). | `ls -d skills/tracker-adapter` → "No such file or directory". |
| 2 | File path | `.gitignore` exists at repo root; the per-skill whitelist block is lines 16–28; alphabetical slot for `tracker-adapter` is after `!/skills/tma/` (line 26), before `!/skills/update-design-doc/` (line 27). | `sed -n '22,28p' .gitignore`. |
| 3 | Ordering (hazard) | Skill files are git-ignored until the whitelist line exists → the `.gitignore` edit must precede the first `git add` of skill files. | `git check-ignore -v skills/tracker-adapter/SKILL.md` → `.gitignore:15:/skills/*` (ignored). Resolved by making the whitelist Task 1 Step 1. |
| 4 | Consumer impact (Cat 6) | Adding the skill + whitelist line keeps `tests/run-tests.sh` green: provenance `sha256sum -c` covers only the 6 companion files (none in this skill), the removed-path grep matches nothing in the new skill, and lockstep ignores `skills/`. | `bash tests/run-tests.sh` → `ALL TESTS PASSED` at baseline; guard scripts read (`check-companion-provenance.sh:9-16`, `check-version-lockstep.sh`). |
| 5 | Command | `node --test <dir>` FAILS on v24.18.0 (`Cannot find module …/tests`). The reliable form is the explicit file: `node --test skills/tracker-adapter/tests/project.test.mjs` (also works: no-arg auto-discovery, and glob `'…/tests/**/*.test.mjs'`). | `/tmp` probe: dir form → exit 1 `MODULE_NOT_FOUND`; explicit-file form → exit 0, `pass 1`. |
| 6 | Code validity | ESM `export function projectIssue` is importable from the test via `import { projectIssue } from '../scripts/adapter.mjs'`; CLI dispatch is gated by `import.meta.url === pathToFileURL(process.argv[1]).href` so the test import does not run `main()`. | `/tmp` probe: test importing the export → green; running the module directly → `DISPATCH RAN`. |
| 7 | Code validity | `.mjs` runs as ESM with no `package.json "type"` field; top-level `import`/`export` and `import.meta` work on v24.18.0. | `/tmp` probe used `.mjs` with top-level import/export, no package.json → ran. |
| 8 | Signature | `execFileSync('gh', args, { input, encoding: 'utf8' })` pipes `input` to `gh` stdin (for `--body-file -`) and throws on nonzero exit with `.status`/`.stderr`/`.stdout`. | Node stdlib API; `input` option exercised in `/tmp` probe pattern; standard `child_process` behavior. |
| 9 | Data shape | `comments[].author` is an **object** `{login}` (not a string) → `projectIssue` passes it through as-is (faithful, per TA7); `labels[]` are objects with `.name` → flattened. | `gh issue view 23464 -R umbraco/Umbraco-CMS --json …` → `comment0_author: {"login":"github-actions"}`; `label0: {color,description,id,name}`. |
| 10 | Command | `gh issue comment` reads the body from stdin via `--body-file -`; on success it prints the created comment's URL to stdout (captured for `comment`'s `{ok, url}`). | `gh issue comment --help` → `-F, --body-file … use "-" to read from standard input`. URL-to-stdout confirmed by design (spec §4); finally validated in the deferred live write smoke test (write scope unavailable at plan-write time). |
| 11 | Sibling sweep — verbs | All six contract verbs map to a defined dispatch branch: `getTicket`/`assign`/`setStatus`/`comment`/`linkPullRequest` implemented; `listCandidates` → `not_implemented`. | Spec §4/§5 tables; enumerated in Task 1 Step 4 code. |
| 12 | Sibling sweep — error codes | All five error codes have a concrete trigger: `bad_args` (missing verb args), `unknown_provider`, `unknown_verb`, `not_implemented` (jira / listCandidates), `gh_error` (runGh throw). | Spec §4; enumerated in Task 1 Step 4 code. |
| 13 | Sibling sweep — Ticket fields | All eight `Ticket` fields have a defined source or empty value in `projectIssue`, each covered by a test assertion. | Spec §5 projection table; Task 1 Steps 3–4. |
| 14 | Sibling sweep — statuses | All four statuses (`needs-info`, `in-progress`, `in-review`, `done`) resolve through the single label-else-comment rule; none needs special-casing. | Spec §6 table (only `needs-info` carries a label in the Umbraco harness). |
| 15 | Command (buffer) | `execFileSync`'s default `maxBuffer` is 1 MiB; a large `gh issue view --json comments` dump exceeds it and throws `ENOBUFS` (gh itself exits 0), so `runGh` sets `maxBuffer: 64*1024*1024` to keep `getTicket` a complete dump (TA7). | Probe (Node v24.18.0): `execFileSync` no-maxBuffer → 1024 KiB OK, 1100 KiB `ENOBUFS`; with `maxBuffer` raised → OK. |

## Tasks

### Task 1: Adapter script + projection tests

**Files:**
- Modify: `.gitignore` (add `!/skills/tracker-adapter/`)
- Create: `skills/tracker-adapter/tests/fixtures/issue-view.json`
- Create: `skills/tracker-adapter/tests/project.test.mjs`
- Create: `skills/tracker-adapter/scripts/adapter.mjs`

**Interfaces:**
- Produces: the `adapter.mjs` CLI contract (`<provider> <verb> [args]` → JSON on stdout / error JSON + nonzero exit) and the exported `projectIssue` function — consumed conceptually by Task 2's documentation.

- [ ] **Step 1: Whitelist the skill subtree in `.gitignore`** (must come first — see plan-level assumption #3). Insert the line between `!/skills/tma/` and `!/skills/update-design-doc/`:
```
!/skills/tma/
!/skills/tracker-adapter/
!/skills/update-design-doc/
```

- [ ] **Step 2: Create the recorded fixture** `skills/tracker-adapter/tests/fixtures/issue-view.json`. Keys mirror the verified real `gh issue view --json` shape (evidence: `umbraco/Umbraco-CMS#23464`); comment/body text is a minimal representative sample. It deliberately includes extra comment keys (`authorAssociation`, `id`, `url`, `reactionGroups`, `viewerDidAuthor`) so the test proves the projection drops them:
```json
{
  "number": 23464,
  "title": "Can't click away the toast notification in infinite editing mode",
  "body": "### Which Umbraco version are you using?\n\n18.0.0-rc\n\n### Bug summary\n\nIn infinite editing mode the toast notification cannot be dismissed.",
  "comments": [
    {
      "author": { "login": "github-actions" },
      "authorAssociation": "NONE",
      "body": "Hi there @reporter! Thanks for reporting this issue.",
      "createdAt": "2026-07-23T09:27:53Z",
      "id": "IC_kwDOAAAAAA1",
      "url": "https://github.com/umbraco/Umbraco-CMS/issues/23464#issuecomment-1",
      "reactionGroups": [],
      "viewerDidAuthor": false
    },
    {
      "author": { "login": "someuser" },
      "authorAssociation": "CONTRIBUTOR",
      "body": "I can reproduce this on 18.0.0-rc.",
      "createdAt": "2026-07-23T09:29:06Z",
      "id": "IC_kwDOAAAAAA2",
      "url": "https://github.com/umbraco/Umbraco-CMS/issues/23464#issuecomment-2",
      "reactionGroups": [],
      "viewerDidAuthor": false
    }
  ],
  "labels": [
    { "id": "MDU6TGFiZWwxMTM0Mzg4MTUy", "name": "state/needs-investigation", "description": "This requires input from HQ or community to proceed", "color": "eaf0f7" },
    { "id": "LA_kwDOAAAAAA3", "name": "area/backoffice", "description": "", "color": "0e8a16" }
  ]
}
```

- [ ] **Step 3: Write the failing test** `skills/tracker-adapter/tests/project.test.mjs` (TDD red — `projectIssue` does not exist yet). Assertions cover exactly what spec §7 mandates: id/title/body mapping, full comment-array passthrough projected to `{author, body, createdAt}` (author object passed through; extra keys dropped), label flattening to names, and empty `severity`/`attachments`/`links`:
```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { projectIssue } from '../scripts/adapter.mjs';

const fixture = JSON.parse(
  readFileSync(new URL('./fixtures/issue-view.json', import.meta.url), 'utf8')
);

test('projectIssue maps scalar fields', () => {
  const t = projectIssue(fixture);
  assert.equal(t.id, 23464);
  assert.equal(t.title, fixture.title);
  assert.equal(t.body, fixture.body);
});

test('projectIssue passes comments through as {author, body, createdAt}, dropping extra keys', () => {
  const t = projectIssue(fixture);
  assert.equal(t.comments.length, 2);
  assert.deepEqual(t.comments[0], {
    author: { login: 'github-actions' },
    body: 'Hi there @reporter! Thanks for reporting this issue.',
    createdAt: '2026-07-23T09:27:53Z',
  });
  // faithful dump: author stays an object (TA7), not flattened to a string
  assert.equal(typeof t.comments[1].author, 'object');
});

test('projectIssue flattens labels to names', () => {
  const t = projectIssue(fixture);
  assert.deepEqual(t.labels, ['state/needs-investigation', 'area/backoffice']);
});

test('projectIssue leaves enriching fields empty (A6)', () => {
  const t = projectIssue(fixture);
  assert.equal(t.severity, undefined);
  assert.deepEqual(t.attachments, []);
  assert.deepEqual(t.links, []);
});
```
> The fixture is loaded via `new URL('./fixtures/issue-view.json', import.meta.url)` (a `URL` accepted directly by `readFileSync`) so the test is cwd-independent.

- [ ] **Step 4: Implement `skills/tracker-adapter/scripts/adapter.mjs`** to make the test pass (TDD green). Pure `projectIssue` + thin `runGh` + dispatch over the six verbs + jira stub, with the error-code contract emitted as JSON on stdout and a nonzero exit:
```js
import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

// --- Pure projection (unit-tested; no I/O) ------------------------------------
export function projectIssue(gh) {
  return {
    id: gh.number,
    title: gh.title,
    body: gh.body,
    comments: (gh.comments ?? []).map((c) => ({
      author: c.author,        // faithful dump: {login, ...} passed through (TA7)
      body: c.body,
      createdAt: c.createdAt,
    })),
    labels: (gh.labels ?? []).map((l) => l.name),
    severity: undefined,       // GitHub has no native severity field (A6)
    attachments: [],           // no native field (A6)
    links: [],                 // no structured field in v1 (A6)
  };
}

// --- Thin I/O wrapper (the only part that shells out) -------------------------
function runGh(args, input) {
  return execFileSync('gh', args, { input, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
}

// --- Error helper: emit contract error JSON on stdout, exit nonzero ----------
function fail(code, message) {
  process.stdout.write(JSON.stringify({ error: message, code }) + '\n');
  process.exit(1);
}

function ok(obj) {
  process.stdout.write(JSON.stringify(obj) + '\n');
  process.exit(0);
}

// --- Verb handlers (GitHub reference provider) -------------------------------
function getTicket(id) {
  if (!id) return fail('bad_args', 'getTicket requires <id>');
  const out = runGh(['issue', 'view', id, '--json', 'number,title,body,comments,labels']);
  ok(projectIssue(JSON.parse(out)));
}

function assign(id, who) {
  if (!id || !who) return fail('bad_args', 'assign requires <id> <who>');
  runGh(['issue', 'edit', id, '--add-assignee', who]);
  ok({ ok: true });
}

function setStatus(id, name, rest) {
  if (!id || !name) return fail('bad_args', 'setStatus requires <id> <name> [--label <label>]');
  const li = rest.indexOf('--label');
  const label = li !== -1 ? rest[li + 1] : undefined;
  if (label) {
    runGh(['issue', 'edit', id, '--add-label', label]);
    ok({ ok: true, via: 'label' });
  } else {
    runGh(['issue', 'comment', id, '--body-file', '-'], `→ ${name}`);
    ok({ ok: true, via: 'comment' });
  }
}

function comment(id) {
  if (!id) return fail('bad_args', 'comment requires <id> and markdown on stdin');
  const md = readFileSync(0, 'utf8');        // markdown from stdin
  const out = runGh(['issue', 'comment', id, '--body-file', '-'], md);
  ok({ ok: true, url: out.trim() });
}

function linkPullRequest(id, url) {
  if (!id || !url) return fail('bad_args', 'linkPullRequest requires <id> <url>');
  runGh(['issue', 'comment', id, '--body', `Linked PR: ${url}`]);
  ok({ ok: true });
}

// --- Dispatch ----------------------------------------------------------------
function main(argv) {
  const [provider, verb, ...rest] = argv;
  if (provider === 'jira') return fail('not_implemented', "provider 'jira' not implemented");
  if (provider !== 'github') return fail('unknown_provider', `unknown provider: ${provider ?? '(none)'}`);

  try {
    switch (verb) {
      case 'getTicket':       return getTicket(rest[0]);
      case 'assign':          return assign(rest[0], rest[1]);
      case 'setStatus':       return setStatus(rest[0], rest[1], rest.slice(2));
      case 'comment':         return comment(rest[0]);
      case 'linkPullRequest': return linkPullRequest(rest[0], rest[1]);
      case 'listCandidates':  return fail('not_implemented', 'listCandidates is deferred (spec §9)');
      default:                return fail('unknown_verb', `unknown verb: ${verb ?? '(none)'}`);
    }
  } catch (err) {
    // runGh threw → gh exited nonzero; carry its stderr
    const msg = (err.stderr && err.stderr.toString().trim()) || err.message;
    return fail('gh_error', msg);
  }
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  main(process.argv.slice(2));
}
```
> Note: handlers call `ok()`/`fail()` which `process.exit()`, so the `try` in `main` catches only `runGh` throws (the exit-based returns never fall through to the catch). `setStatus`'s no-label branch pipes `→ <name>` (U+2192) to `gh issue comment` stdin, matching spec §5/§6.

- [ ] **Step 5: Run the test suite — expect green.**
```bash
node --test skills/tracker-adapter/tests/project.test.mjs
```
Expected: `pass 4 … fail 0`, exit 0. (Do NOT use `node --test skills/tracker-adapter/tests/` — the bare-directory form fails on Node v24.18.0; see plan-level assumption #5.)

- [ ] **Step 6: Commit.**
```bash
git add .gitignore skills/tracker-adapter/scripts/adapter.mjs skills/tracker-adapter/tests/project.test.mjs skills/tracker-adapter/tests/fixtures/issue-view.json
git commit -m "$(cat <<'EOF'
feat(tracker-adapter): adapter script + projection tests; whitelist in .gitignore

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 7 (deferred, manual — not a shipped test): live write smoke test.** In an authed environment with a **writable** throwaway repo/fork (the harness token cannot write to `umbraco/Umbraco-CMS`), exercise the write verbs against a scratch issue and record the results in the build's verification notes (spec §7, §11 A1). This also finally confirms plan-level assumption #10 (`gh issue comment` prints the comment URL to stdout):
```bash
# from inside a writable repo clone (cwd repo inference, TA4):
node <path>/adapter.mjs github assign <id> @me
echo "smoke: work started" | node <path>/adapter.mjs github comment <id>
node <path>/adapter.mjs github setStatus <id> needs-info --label <some-label>
node <path>/adapter.mjs github setStatus <id> in-progress   # comment fallback
```

### Task 2: Contract skill + provider references

**Files:**
- Create: `skills/tracker-adapter/SKILL.md`
- Create: `skills/tracker-adapter/references/github.md`
- Create: `skills/tracker-adapter/references/jira.md`

**Interfaces:**
- Consumes: Task 1's `adapter.mjs` CLI contract — the SKILL.md and `references/github.md` document the exact commands/outputs the script implements (they must match Task 1's dispatch behavior verb-for-verb).

- [ ] **Step 1: Write `skills/tracker-adapter/SKILL.md`.** Frontmatter (matching the repo convention — see `sproc-xray/SKILL.md:1-5`):
```yaml
---
name: tracker-adapter
version: 1.0.0
description: Use when the bug-fixing workflow needs to read a ticket from, or write status/comments/PR-links back to, an issue tracker. GitHub via the gh CLI is the reference provider (Jira is a documented, unbuilt slot). Invoked by the bugfix orchestrator; wraps scripts/adapter.mjs. Not a user-facing judgment skill — it is deterministic plumbing at the workflow's tracker edge.
---
```
Body sections (thin contract skill, TA3):
  1. **Overview** — one paragraph: the adapter is the only tracker-specific part of the workflow; plumbing not judgment (spec §1, TA1/TA7).
  2. **Invocation** — `node scripts/adapter.mjs <provider> <verb> [verb-args…]`; the verb/args/success-output table (spec §4); the failure contract (JSON `{error, code}` on stdout + nonzero exit) and the five error codes.
  3. **Status model** — the uniform rule verbatim: **`--label` given → add that label; no `--label` → post a comment `→ <name>`**; the four-status table (spec §6); `setStatus` is advisory and one-way; `done` never closes (closing is delegated to the PR closing keyword at Stage 9).
  4. **Needs-info checklist** — the "required to proceed" items carried verbatim from the umbrella contract (umbrella §4), so the orchestrator can post exactly the missing items when it drives `setStatus … needs-info`:
     - **Expected behavior** — can't define "fixed" without it.
     - **Actual behavior / symptom** (incl. error / stack trace if any) — this *is* the bug.
     - **Reproducibility context** — steps, and environment/version where relevant.
  5. **Required harness config** — the only injected config is the optional `--label` on `setStatus`; the label *names* (e.g. `state/needs-investigation`) are held by the orchestrator, not the adapter (spec TA5).
  6. **Providers** — `github` (implemented; see `references/github.md`); `jira` (stub → `not_implemented`; see `references/jira.md`). Pointer to `scripts/adapter.mjs`.

- [ ] **Step 2: Write `skills/tracker-adapter/references/github.md`.** Transcribe spec §5: the `getTicket` command (`gh issue view <id> --json number,title,body,comments,labels`), the `projectIssue → Ticket` projection table (id←number, title, body, comments[]→{author,body,createdAt}, labels[]→name, severity/attachments/links empty), and the write-verb → `gh` command table (`assign`/`setStatus` label & comment-fallback/`comment`/`linkPullRequest`). Note that close-on-merge is delegated to the PR closing keyword (`Fixes #<id>`), not an adapter action.

- [ ] **Step 3: Write `skills/tracker-adapter/references/jira.md`.** Transcribe spec §8: the intended per-verb Jira mechanism table (REST `issue/{key}`, assignee PUT, transitions with comment fallback, comment POST, remote link / smart-commit) — documented so extensibility is proven by shape; built by nobody. State that `provider = jira` currently exits `not_implemented`.

- [ ] **Step 4: Commit.**
```bash
git add skills/tracker-adapter/SKILL.md skills/tracker-adapter/references/github.md skills/tracker-adapter/references/jira.md
git commit -m "$(cat <<'EOF'
feat(tracker-adapter): contract skill + provider references (v1)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 5: Confirm repo guards still pass.**
```bash
bash tests/run-tests.sh   # expect: ALL TESTS PASSED
```

## Tasks NOT in this plan

Inherited from the spec's out-of-scope (spec §1) and deferred (spec §9) sections. A new spec → plan cycle is required to add any of these:

- The `bugfix` orchestrator (its own spec → plan → build cycle). This plan builds only the interface the orchestrator will call.
- `listCandidates` implementation — its only consumer is a future orchestrator entry-path that doesn't exist yet; shipped as a contract slot that exits `not_implemented`.
- Building the Jira provider — stub + reference doc only.
- Parsing enriching fields GitHub has no native source for (`severity`, `attachments`, deriving `links[]` from `#`-refs) — left empty in v1.

## Known issues inherited from spec

Accepted during brainstorming (spec §9) — these exist in the v1 implementation by design:

- **`listCandidates` deferred** — no consumer calls it yet (avoids building a verb nothing uses).
- **Enriching-field parsing not done** — `links[]` from `#`-refs and `severity` from a label convention are left empty; add only if a workflow stage actually needs them.
- **Jira unbuilt** — provider stub + reference doc only.
