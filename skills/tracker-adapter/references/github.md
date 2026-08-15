# GitHub Provider Reference

This document describes the exact `gh` command and `Ticket` projection for each implemented verb in the GitHub reference provider.

## Read

### `getTicket(id)`

**Command:**

```bash
gh issue view <id> --json number,title,body,comments,labels
```

**Projection: `projectIssue(ghJson) → Ticket`**

The `Ticket` shape is defined by the umbrella bug-fixing workflow specification. This projection conforms exactly, adding no fields:

| Ticket field | Source | Notes |
|--------------|--------|-------|
| `id` | `number` | Issue number (stable within the repo) |
| `title` | `title` | |
| `body` | `body` | |
| `comments[]` | `comments[]` → `{author, body, createdAt}` | Full array, faithful dump — all comments passed through |
| `labels[]` | `labels[].name` | Flattened to names |
| `severity?` | — | **empty** — GitHub has no native severity field |
| `attachments[]` | — | **empty** — no native field |
| `links[]` | — | **empty in v1** — no structured field; `#`-ref parsing deferred |

The `comments[].author` field is passed through faithfully as the full author object (`{login, ...}`) from GitHub's JSON response.

## Write

| Verb | `gh` command |
|------|--------------|
| `assign(id, who)` | `gh issue edit <id> --add-assignee <who>` (`@me` supported) |
| `setStatus(id, name, --label L)` | `gh issue edit <id> --add-label <L>` |
| `setStatus(id, name)` *(no label)* | `gh issue comment <id> --body-file -` with body `→ <name>` |
| `comment(id, md)` | `gh issue comment <id> --body-file -` (markdown via stdin — avoids arg-length/escaping issues) |
| `linkPullRequest(id, url)` | `gh issue comment <id> --body "Linked PR: <url>"` |

**Notes:**

- The `--body-file -` flag reads from stdin, avoiding argument-length and escaping issues for markdown content.
- The `setStatus` comment fallback posts a single-line comment with the body `→ <name>` where the arrow is Unicode U+2192.
- `@me` is a `gh` CLI convention for the authenticated user.

## Repository inference

All `gh` commands operate on the current repository, inferred from the current working directory's git remote. No `--repo` or `-R` flag is passed — the adapter follows the same convention as all other skills.

## Close-on-merge delegation

**Close-on-merge is not an adapter action.** It is delegated to GitHub's native PR linkage — the closing keyword (`Fixes #<id>`) in the PR body, emitted at the workflow's final stage. The adapter does not close the issue itself; the `done` status degrades to a comment, and the issue remains open until the linked PR is merged.
