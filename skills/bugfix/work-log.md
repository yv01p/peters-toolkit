# Work-log

The **ticket is the work-log.** There is no separate state store — each bug's durable record lives as structured markdown comments the orchestrator posts to its own ticket (via the adapter `comment` verb) at each milestone. This is both the human-readable history and the recovery source for pre-branch resume (a bug at Stages 0–2 has no branch or artifacts, so its ticket comments are the only place its root-cause agreement is recorded — see playbook.md "First: resolve state").

## Entry format

Each block carries a **hidden marker** so the orchestrator can find its own entries when it reads the ticket back (`getTicket` returns a faithful comment dump; the marker distinguishes bugfix entries from human comments):

```markdown
### 🔧 bugfix · <milestone>
<!-- bugfix-worklog stage=<n> -->
<fields>
```

`<n>` is the stage number the entry records. The `<!-- … -->` comment is invisible in rendered markdown but present in the raw body the orchestrator parses.

## Milestone → fields

Post one entry per milestone below. Keep them lean — this is a durable summary, not a transcript.

| Milestone | Marker stage | Fields |
|---|---|---|
| Triage (G1) | `stage=1` | Classification: `trivial` \| `design-only` \| `full` · Expected: … · Actual: … |
| Root cause (G2) | `stage=2` | Root cause (the *why*): … |
| Design (G4) | `stage=4` | Options considered: … · Chosen: … · Design doc: `<path>` |
| Plan (G5) | `stage=5` | Plan: `<path>` · Summary: … |
| Verify (7) | `stage=7` | Test added: … · `format` ✅ · `test` ✅ · Original repro gone: ✅ |
| Done (9) | `stage=9` | PR: `<url>` · Status: done |

Additional entries the orchestrator posts as they occur:
- **Needs-info** (Stage 2, if the reproduction is blocked): the "required to proceed" checklist of exactly the missing items, plus `stage=2`. The bug re-enters at Stage 2 by explicit id when the reporter responds.
- **Manual-fallback flag** (Stage 3, only when no automated test path exists): record the manual reproduction steps + expected/actual and **explicitly flag that regression protection is manual, not automated** (playbook.md Stage 3). Never omit this — an un-flagged manual fallback is a silent skip.

## Example

```markdown
### 🔧 bugfix · Root cause (G2)
<!-- bugfix-worklog stage=2 -->
Root cause (the *why*): the price DTO is cached in three layers (CDN, Redis,
in-process LRU); the write path invalidates only Redis, so CDN + LRU serve
stale prices until TTL. Confirmed by reproducing with each layer isolated.
```

## This is a seam

The template is deliberately lean and is a named extension point (see customizing.md). Teams edit **this file** to change what lands on their tickets — add or drop fields, adjust the marker text — without touching skill logic. Keep the hidden `<!-- bugfix-worklog stage=<n> -->` marker on every entry so resume/recovery keeps working.
