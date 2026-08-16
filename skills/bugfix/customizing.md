# Customizing

A **solid, customizable base** is a first-class goal of this skill, not an afterthought. The core is lean; every seam is named and documented; you customize **by editing markdown and config**, never by working around a plugin/hook framework (there isn't one — that would itself be a feature you'd have to understand and defeat).

This doc is installer-facing: the essential "why" so you can change the base safely. The full decisions record lives in the design spec (`docs/specs/2026-07-25-orchestrator-design.md`) for anyone who wants the depth.

## Extension points

| Seam | How you change it |
|---|---|
| Tracker provider | Adapter provider slot — `github` built, `jira` documented; add your own provider in the tracker adapter. |
| Harness values | Edit `.claude/bugfix.harness.md` (labels, branch/PR conventions, `format`/`test` commands, artifact dirs). See harness-config.md. |
| Project review skill | Set `review_skill:` in the harness config (runs at Stage 8) or omit it. |
| Reproduction / verification | `repro_verify:` — `auto` (tests) by default; `browser` / `E2E` / `manual` for UI bugs. |
| Work-log content | Edit `work-log.md` — the template of what lands on your tickets (keep the hidden marker). |
| Tiers / gates / stages | Fork `playbook.md` — each stage is a self-contained block you can adjust. |

## Decisions & rationale (the "why")

Condensed from the design spec's locked decisions (O1–O11). Knowing *why* each choice was made tells you which are safe to change and which are load-bearing.

- **O1 — An LLM conductor, not a script.** The orchestrator's job is judgment and coordination — sequencing stages, enforcing gates, routing tiers, calling sub-skills and the adapter. Only the mechanical parts (resume/status) are a script. *Change freely:* the prose playbook. *Don't:* try to reduce the conducting to code — the judgment is the point.
- **O2 — A dedicated harness-config file** (`.claude/bugfix.harness.md`), echoed at G1. Deterministic, amortized across runs, self-documenting, and the G1 confirm catches drift. *This is the main seam you'll edit.*
- **O3 — Resume is a deterministic Node script** (`status.mjs`), offline (git + filesystem), not LLM inference. "Which stage is bug #123 at" is mechanical fact-gathering; it's load-bearing (a wrong resume redoes work or skips a gate) and unit-tested. *Don't* replace it with guesswork.
- **O4 — The picker is scoped to branch-cut bugs (Stage 3+).** The offline script only sees work with a local footprint, which starts when the branch is cut. Pre-branch bugs are resumed by explicit id (context recovered from the ticket work-log). A tracker-side "list my bugs" query is deliberately deferred.
- **O5 — Three tiers (`trivial` / `design-only` / `full`),** because design-effort and planning-effort are **independent dials**, not one switch. The common "design ON, plan OFF" case (real brainstorming, then a localized TDD fix) has its own tier. The fourth combination (plan without design) never occurs and isn't offered. *This is what stops both over-ceremony on a one-liner and under-tiering a multi-subsystem bug.*
- **O6 — `systematic-debugging` is the shared spine (Stage 2); G2 (root-cause sign-off) is the common fork.** Every bug is investigated the same way to root cause, then trivial tails straight into the fix while design-only/full detour through design (and plan). *Don't* remove the G2 stop — it's the highest-value gate.
- **O7 — UI / non-code bugs use the *same* pipeline;** the base is test-stack-agnostic. The reproduction/verification method is the `repro_verify` seam. When no automated UI-test path exists, the manual fallback is **recorded and flagged manual** — never a silent skip. *Plug your own browser/E2E tooling in here.*
- **O8 — "Solid, customizable base" is the design goal itself.** Lean core; named, documented seams; decisions recorded; customize-by-editing; **no plugin/hook framework.** Every feature in the base is something you'd have to understand to fork it, so ruthless YAGNI keeps it forkable.
- **O9 — The adapter is invoked by absolute path, cwd = the target repo.** `gh` infers the repo from cwd, so the adapter runs cwd'd in the target repo; the orchestrator resolves the adapter as a sibling of its own skill base dir.
- **O10 — Documentation at two altitudes.** This `customizing.md` is the focused, installer-facing "why"; the design spec is the full decisions record for the team. You shouldn't have to read the spec to customize safely — but it's there if you want the depth.
- **O11 — Status is advisory; `done` closes via the PR closing keyword, not a label.** The harness `status_labels` map lists only statuses with a native label; the rest fall back to a comment. The orchestrator holds the label *names* (harness config); the adapter holds the mechanism.

## Deliberately not built (so you don't go looking)

- **A tracker-side "list my in-flight bugs" query** — the picker is offline/branch-cut only.
- **Browser-automation tooling** — `repro_verify` is a seam; the base ships automated-test + the flagged manual fallback only.
- **An autonomy dial** — the gates are the future dial; only the fully-gated manual version is built. See `roadmap.md` for ideas on how graduated, per-gate autonomy could work.
- **A Jira provider** — a documented, unbuilt adapter slot.
