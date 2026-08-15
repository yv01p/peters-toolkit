# Jira Provider Reference

**Status:** Documented, unbuilt. `provider = jira` currently exits with `{"error": "provider 'jira' not implemented", "code": "not_implemented"}`.

This document sketches the intended mapping for Jira so the extensibility is proven by shape, built by nobody.

## Intended verb → Jira mechanism mapping

| Verb | Intended Jira mechanism |
|------|-------------------------|
| `getTicket` | `GET /rest/api/3/issue/{key}` → project fields onto `Ticket` |
| `assign` | `PUT /rest/api/3/issue/{key}/assignee` |
| `setStatus` | Issue **transitions** (`POST /rest/api/3/issue/{key}/transitions`); comment fallback where no transition matches |
| `comment` | `POST /rest/api/3/issue/{key}/comment` |
| `linkPullRequest` | Remote issue link or smart-commit on merge |

## Notes

- **Jira transitions** are workflow-specific and vary by project configuration. The `setStatus` implementation would need to query available transitions and match by name, falling back to a comment where no matching transition exists (consistent with the adapter's comment-fallback policy).
- **Smart-commits** (e.g., `JRA-123 #comment Linked PR: <url>`) or the **remote issue link** API can associate a PR with a Jira issue.
- The `Ticket` projection would map Jira's `key` to `id`, `summary` to `title`, `description` to `body`, and `comment.comments[]` to `comments[]`. Enriching fields like `priority` could populate `severity` if present.

## Authentication

Jira REST API access requires authentication (typically API token or OAuth). The implementation would need to accept credentials via environment variables (e.g., `JIRA_API_TOKEN`, `JIRA_BASE_URL`) or rely on a configured Jira CLI tool (e.g., `jira-cli`), analogous to how the GitHub provider relies on `gh` CLI's authentication.

## Build status

This provider is **not implemented in v1**. The reference documentation exists to prove the adapter's extensibility to additional trackers without requiring changes to the workflow core.
