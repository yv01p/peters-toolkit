# Bugfix

Most of the Toolkit's skills are single-shot passes. You point one at a spec, a plan, or a diff and it does its job. `bugfix` is different. It's a conductor. It drives one bug, locally, from the moment you pick up the ticket to a merged fix, and it hands every hard step to skills that already exist (Superpowers and this Toolkit) plus a tracker adapter. It re-implements none of their logic. What it does is sequence the stages, enforce the human gates, route the bug by complexity, read a per-project config, and write the ticket work-log.

Why it exists is simple. Left to improvise under deadline pressure, a capable agent falls into ad-hoc symptom-fixing. Patch the symptom, test it by hand, open the PR, add the real test tomorrow. `bugfix` closes that door. Every bug, trivial or not, walks the same pipeline through the same stops.

**Three tiers, picked at triage.** They differ only in how much design and planning a bug gets.

- **Trivial.** The fix is obvious from the root cause, so it goes straight to a test-first fix.
- **Design-only.** The approach is unclear but the change is localized, so you brainstorm and review the design first.
- **Full.** Unclear and multi-step or risky, so you design, then write a reviewed implementation plan, then build it with subagents.

**Out of the box, the human gates are mandatory, but the skill is designed so that you can automate the human gates.** As you start working with this skill, each gate is a STOP. The orchestrator lays it out in chat and waits for you.

- **G1.** Confirm the bug statement and the tier.
- **G2.** Root-cause sign-off. Agree on why before how. This one stops on every tier, no exceptions.
- **G4 and G5.** Approve the design (design-only and full) and the plan (full).
- **G8.** Human review before the PR goes up. No self-approve.

One Iron Law sits under all of it. The failing reproduction test comes first. It lands on the branch and fails before the fix exists, never "added tomorrow."

**It works out of the box, then it becomes yours.** Everything project-specific lives in one file you write by hand, `.claude/bugfix.harness.md`: your tracker, your branch and PR conventions, your format and test commands, where design and plan docs go. You customize it by editing markdown. There's no plugin or hook framework to learn. Start with the fully-gated manual workflow, and as you get comfortable, the gates are where future autonomy would live. See `roadmap.md` for some ideas.

**The tracker adapter.** `bugfix` reads the ticket and writes status, comments, and PR links back through a thin tracker adapter, the one tracker-specific piece in the whole workflow. Today it ships a single provider, GitHub, over the `gh` CLI. (Jira is a documented slot, not yet built.) On a different tracker? You write a small adapter for it. Everything between the two edges is tracker-agnostic, so nothing else has to change.

Run it with `/bugfix <id>` from inside the target repo. The operational detail lives beside the skill: the stage-by-stage spine in `playbook.md`, the config format in `harness-config.md`, the work-log template in `work-log.md`, and the customization seams in `customizing.md`.
