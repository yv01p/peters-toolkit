# Bugfix roadmap: ideas for graduated autonomy

**These are ideas, not a plan.** Nothing here is built.

Today `bugfix` is fully manual, so every gate stops for a human. What follows is one way the skill could grow as you get comfortable handing steps to the conductor. Treat it as a menu: take what fits how you work, leave the rest, or build something different.

The shape of the idea is manual now, autonomous later, one gate at a time. You don't flip the whole workflow over in a single move. You graduate one gate the moment you trust the conductor with that specific step, and not before.

## 1. A per-gate map in the harness config

Add a small `gates:` block to the `.claude/bugfix.harness.md` file you already have, one entry per gate, each set to `manual` or `auto`.

```
gates:
  G1: auto      # you trust the triage
  G4: manual    # you still want eyes on the design
  G5: manual
```

A team graduates a gate by editing one line. This is the most granular way to say "manual now, autonomous later." Every gate is its own switch, flipped exactly when you're comfortable with that step, instead of one coarse level for the whole workflow.

The harness config is the right home for it. That file is already read on every run and echoed back to you at G1, so if the autonomy state lives there, the current posture ("G1 is auto, everything else manual") shows up on every single invocation. You can't forget that a gate went autonomous three weeks ago. It also stays true to the skill's core idea: one config file you write by hand, customize by editing markdown, no framework to understand and work around. The cost is close to nothing. The conductor reads a few extra keys and decides whether to stop or keep going at each gate.

## 2. Auto-proceed with a work-log audit

The orchestrator is an LLM conductor, not a script, so "autonomous" can't mean skip the step. The judgment at each gate still has to happen. An `auto` gate would mean the conductor does the gate's work itself (classify the tier, sign off the root cause, approve the design) and posts that decision to the ticket work-log exactly as it would have shown you in chat. It just doesn't block waiting for your yes.

The step still happens and it still gets recorded. The only thing removed is the pause.

The audit trail is the load-bearing part here, not a nice-to-have. It's what makes graduated autonomy reversible. Say you review a shipped fix and find the conductor made a bad call at G4. The reasoning is sitting right there in the work-log, and the fix is to flip G4 back to `manual`. Autonomy without that recorded decision would be a silent skip, which is the exact failure the whole skill exists to prevent. Keeping the work-log entry mandatory on `auto` gates is what lets you turn autonomy up safely, and turn it back down when you need to.

## 3. A safety floor

Some gates are worth keeping human no matter how comfortable you get. G2 (root-cause sign-off, agree on why before how) and G8 (human review before the PR, no self-approved PRs) are written into SKILL.md as Iron-Law non-negotiables. A floor means those two are simply not eligible for `auto`. The config rejects `G2: auto` outright, or it demands an explicit lead-authored override. G1, G4, and G5 stay freely graduatable.

That keeps the two highest-value checkpoints intact by construction, so autonomy can raise throughput without ever quietly erasing the guarantees that separate this pipeline from ad-hoc symptom-fixing.

It also keeps the docs honest. If every gate were dialable, the "non-negotiable, no exceptions" language in SKILL.md would be false. Lock G2 and G8 and the non-negotiables stay non-negotiable in both the config and the docs, so the dial and the Iron Laws describe the same reality.

Which gates sit on the floor is your call. Locking both G2 and G8 is what I'd recommend. A team could decide on G8 only, or trust itself with neither locked. That's exactly the kind of choice this roadmap leaves to you.

## Why this shape, and not the alternatives

- **Not one coarse autonomy level.** A single "autonomy: high" switch can't say "I trust triage but not the design." The per-gate map can.
- **Not a hook or plugin framework.** The dial lives in the same markdown file you already edit. Nothing new to learn, nothing to defeat.
- **Not a silent skip.** An `auto` gate still does the work and records it. The difference between `auto` and `manual` is whether the conductor waits for you, never whether the step happens.

See also the "Deliberately not built" note in `customizing.md`. The autonomy dial was always meant to be the future seam. This file is just a sketch of what it could look like.
