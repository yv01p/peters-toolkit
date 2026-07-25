---
name: tracker-adapter
version: 1.0.0
description: Use when the bug-fixing workflow needs to read a ticket from, or write status/comments/PR-links back to, an issue tracker. GitHub via the gh CLI is the reference provider (Jira is a documented, unbuilt slot). Invoked by the bugfix orchestrator; wraps scripts/adapter.mjs. Not a user-facing judgment skill — it is deterministic plumbing at the workflow's tracker edge.
---

# Tracker Adapter

## Overview

The tracker adapter is the only tracker-specific part of the bug-fixing workflow — a thin edge at ingest and writeback that projects an arbitrary tracker's fields onto one normalized `Ticket` model and maps abstract writeback verbs onto concrete tracker actions. Everything between the two edges is tracker-agnostic. This is plumbing, not judgment: it performs mechanical projection and I/O at the workflow's tracker boundary.

## Invocation

```
node scripts/adapter.mjs <provider> <verb> [verb-args…]
```

- **provider:** `github` (implemented) | `jira` (stub, exits `not_implemented`)
- **stdout:** JSON result on success
- **exit code:** 0 on success, nonzero on failure
- **failure:** JSON `{"error": "<message>", "code": "<slug>"}` on stdout plus nonzero exit

**Error codes:** `gh_error` (underlying `gh` command failed — message carries `gh` stderr), `unknown_provider`, `unknown_verb`, `not_implemented`, `bad_args`

**Verbs:**

| Verb | Args | Success output |
|------|------|----------------|
| `getTicket` | `<id>` | `Ticket` JSON object |
| `assign` | `<id> <who>` (`who` typically `@me`) | `{"ok": true}` |
| `setStatus` | `<id> <name> [--label <label>]` | `{"ok": true, "via": "label"\|"comment"}` |
| `comment` | `<id>` (+ markdown on stdin) | `{"ok": true, "url": "<comment-url>"}` |
| `linkPullRequest` | `<id> <url>` | `{"ok": true}` |
| `listCandidates` | — | deferred — exits `not_implemented` |

The adapter reads no files and holds no ambient configuration beyond what `gh` itself infers (the repository, from the current working directory). It is a pure function of its arguments plus the cwd repo.

## Status model

`setStatus` is **advisory and one-way** — the workflow core never reads a status back to branch on it. The adapter resolves each abstract status through a single uniform rule:

> **`--label` given → add that label. No `--label` → post a comment `→ <name>`.**

The arrow is U+2192 (→). Mapping for the four workflow statuses:

| Abstract status | Example call | Native mechanism |
|-----------------|--------------|------------------|
| `needs-info` | `setStatus <id> needs-info --label state/needs-investigation` | label |
| `in-progress` | `setStatus <id> in-progress` | comment fallback (`→ in-progress`) |
| `in-review` | `setStatus <id> in-review` | comment fallback (`→ in-review`) |
| `done` | `setStatus <id> done` | comment fallback (`→ done`) — never closes the issue |

No status is ever silently lost: comments are the mechanical tier every tracker has, so a status with no configured label degrades gracefully to a comment rather than breaking the run. The label *names* (e.g. `state/needs-investigation`) are harness config held by the orchestrator, not the adapter.

**Close-on-merge is not an adapter action.** Closing the issue is delegated to the tracker's native PR linkage — the closing keyword (`Fixes #<id>` on GitHub) in the PR body, emitted at the workflow's final stage, not here.

## Needs-info checklist

When the workflow sets status to `needs-info`, the orchestrator posts a structured request for exactly the missing **required to proceed** items:

- **Expected behavior** — can't define "fixed" without it.
- **Actual behavior / symptom** (incl. error / stack trace if any) — this *is* the bug.
- **Reproducibility context** — steps, and environment/version where relevant.

This checklist is carried verbatim from the umbrella bug-fixing workflow contract so the orchestrator can post exactly the missing items when it drives `setStatus … needs-info`.

## Required harness config

The only injected configuration is the optional `--label` on `setStatus`. The label *names* (e.g. `state/needs-investigation`) are held by the orchestrator as harness config, not by the adapter. The adapter only knows the mechanism (label-else-comment).

## Providers

- **`github`** — implemented; see `references/github.md` for the exact `gh` command and `Ticket` projection per verb.
- **`jira`** — stub (exits `not_implemented`); see `references/jira.md` for the intended mapping.

**Implementation:** `scripts/adapter.mjs`
