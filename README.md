# Peter's Agentic Toolkit

**Version 2.2.0** · targets Superpowers 6.0.x–6.1.x (verified against 6.1.1)

Peter's Agentic Toolkit is a Claude Code plugin. It's a set of skills that shape how an agent handles design, planning, review, and implementation. The idea is simple: **agentic work deserves the same discipline you'd apply to writing critical software.** You brainstorm an idea into a spec, review the spec adversarially and revise it, turn the spec into a plan, review the plan adversarially and revise it, then hand the plan to sub-agents to build. Security gets assessed along the way.

Each step is explicit, and load-bearing assumptions get checked against the real codebase before they harden into code.

The Toolkit builds on [Superpowers](https://github.com/obra/superpowers) by Jesse Vincent. It augments Superpowers' core loop rather than replacing it. **Superpowers is a hard requirement.** The Toolkit builds on Superpowers' skills (it invokes `subagent-driven-development` directly and reaches the others through it) and lives *on top of* them, so you need Superpowers installed for any of this to work.

## Methodology and principles

The Toolkit inherits Superpowers' **planning-first, test-driven-development** methodology: design and plan before you write code, and drive the implementation with tests (TDD). On top of that, two disciplines run through the whole cycle (brainstorming, design review, planning, implementation, and the security pass alike):

- **Ruthless YAGNI.** Build the smallest thing that solves the actual problem. No speculative generality, no features nobody asked for.
- **Strict DRY.** No duplicated logic or knowledge. One source of truth for every decision.

## Installation

### Prerequisite: Superpowers (required)

The Toolkit will not function without [Superpowers](https://github.com/obra/superpowers) version 6.0.x–6.1.x (verified against 6.1.1; the toolkit-facing skills are unchanged across that range). It invokes `subagent-driven-development` directly (which in turn reaches `requesting-code-review` and `using-git-worktrees`), and `thorough-brainstorming` / `thorough-writing-plans` extend Superpowers' `brainstorming` / `writing-plans`. Install it first:

```
/plugin install superpowers@claude-plugins-official
```

(`claude-plugins-official` is registered automatically. Or use the community marketplace: `/plugin marketplace add obra/superpowers-marketplace` then `/plugin install superpowers@superpowers-marketplace`.) See the [Superpowers README](https://github.com/obra/superpowers) for details.

### Install the Toolkit

```
/plugin marketplace add https://AIPurveyors.com/peterz/peters-toolkit.git
/plugin install peters-toolkit@peters-toolkit
```

Skills are namespaced under the plugin, so they're invoked as `/peters-toolkit:<skill>` (for example `/peters-toolkit:tma`). Most skills auto-trigger from their description, so you rarely type them by hand.

To update later:

```
/plugin marketplace update peters-toolkit
```

## What it augments

Superpowers establishes a clean brainstorm, plan, implement loop:

```
brainstorming  ->  writing-plans  ->  implement (via subagent-driven-development)
```

Peter's Agentic Toolkit wraps each of those steps in an **adversarial review-and-revise cycle**, so nothing moves forward until it survives scrutiny.

**1. Design cycle**

```
thorough-brainstorming  ->  critical-design-review  ->  update-design-doc
                                    ^                          |
                                    +----------- re-review ----+
```

`thorough-brainstorming` turns the idea into a design spec (verifying load-bearing assumptions against the real codebase first). `critical-design-review` (CDR) reviews that spec adversarially for literal wrongness. `update-design-doc` (UDD) applies the findings one by one. The loop repeats until the spec survives a clean review.

**2. Planning cycle**

```
thorough-writing-plans  ->  critical-implementation-review  ->  update-implementation-plan
                                       ^                                  |
                                       +-------------- re-review ---------+
```

Once the spec is approved, `thorough-writing-plans` (TWP) turns it into an implementation plan (again verifying plan-level assumptions empirically). `critical-implementation-review` (CIR) reviews the plan adversarially. `update-implementation-plan` (UIP) applies the findings. The loop repeats until the plan survives a clean review.

**3. Implementation and security review**

You hand the approved plan to Superpowers' `subagent-driven-development` (SDD) to build. `critical-security-review` is optional and you run it yourself, once the implementation is done (usually post-SDD, over the finished code). If you already have a TMA threat model, point it there with `tma_path`.

## Security skills

Two skills add a security track to the pipeline.

- **`critical-security-review` (CSR)** is a focused, code-level security review with three passes: reconnaissance, systematic vulnerability hunting, then cross-cutting analysis. Because it reviews **code**, it runs after `subagent-driven-development` has implemented the entire plan, as a security pass over the finished code. It can optionally take a TMA threat model as its attack-surface map. The vulnerability taxonomy and severity rubric are built in, so it has no external dependencies.
- **`tma` (Threat Model Analysis)** produces a full threat model (STRIDE-per-element) for a system: architecture and data flows with trust boundaries, threat actors, mitigations, and a prioritized findings roadmap. Run it when a security trigger fires during design (new auth model, new tenant boundary, new external integration, a new class of sensitive data, and so on), before a first deploy, or after a major architectural change. Its output feeds CSR.

## Managing the context window

Two skills exist specifically to protect work quality across long sessions.

We've found that on the Anthropic models with a 1,000,000-token context window, **quality drops off hard once usage passes roughly 40% of the window.** Our status line shows current context usage, so we can watch it climb toward that line.

When usage nears that threshold, the workflow is:

1. **`create-handoff`** captures the full session state (mental models, decisions, open threads, file state) into a structured handoff document.
2. **Clear the context window.**
3. **`resume-handoff <handoff-file>`** rebuilds a fresh context from that document and picks up exactly where you left off, with state validated against the current repo.

Every session stays in the part of the window where the model still does its best work, and nothing gets lost in the switch.

## Inventory

| Category | Skill | One-liner |
|---|---|---|
| **Design cycle** | `thorough-brainstorming` | Turn ideas into design specs, verifying load-bearing assumptions empirically before committing |
| | `critical-design-review` | Adversarial review of a design spec, focused on literal wrongness, over multiple iterative rounds |
| | `update-design-doc` | Apply `critical-design-review`'s findings to the spec, one by one with user approval |
| **Planning cycle** | `thorough-writing-plans` | Turn an approved spec into an implementation plan, verifying plan-level assumptions before committing |
| | `critical-implementation-review` | Adversarial review of an implementation plan, focused on literal wrongness, over multiple iterative rounds |
| | `update-implementation-plan` | Apply `critical-implementation-review`'s findings to the plan, one by one with user approval |
| **Security** | `critical-security-review` | Code-level security review (3-pass), optionally grounded by a TMA threat model |
| | `tma` | Threat Model Analysis (STRIDE-per-element) with a prioritized findings roadmap |
| **Context management** | `create-handoff` | Capture session state into a structured handoff document for resumption later |
| | `resume-handoff` | Resume work from a handoff document with full state validation against the current repo |
| **Architecture and domain** | `arch-review` | Architectural review of an existing codebase against a stated trigger (scaling, migration, incident, due diligence) |
| | `cobol-xray` | X-ray analysis of legacy COBOL codebases for migration, modernization, or refactoring |

## Attribution

This Toolkit builds on [Superpowers](https://github.com/obra/superpowers) by Jesse Vincent (obra), an open-source skill set for Claude Code that establishes brainstorm-first / plan-before-code conventions and provides the agentic primitives the Toolkit composes on. The Toolkit invokes `subagent-driven-development` directly and unmodified. `requesting-code-review` and `using-git-worktrees` come along transitively through it, not by direct calls.

Two Toolkit skills extend Superpowers' originals. `thorough-brainstorming` extends `brainstorming` by adding empirical assumption verification before spec finalization, and `thorough-writing-plans` extends `writing-plans` by adding empirical plan-level assumption verification.

The Toolkit's own contribution is the review-and-revise layer (CDR/UDD, CIR/UIP), the security layer (CSR, TMA), the context-management pair (create-handoff / resume-handoff), and the standalone `arch-review` and `cobol-xray` skills. All of it composes on top of the Superpowers base.

## License

MIT. See [LICENSE](LICENSE). Copyright (c) 2026 Peter Zadrozny.
