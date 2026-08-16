# Baseline-arm results — sproc-xray v0.3.0, fixture `xraytest1`

**Arm:** baseline. `{SKILL_PATH}` = `skills/sproc-xray/SKILL.md` at v0.3.0,
unmodified — no extraction-metrics content of any kind.
**Fixture:** `tests/sproc-metrics/xraytest1` (314 lines, 7 files, 6 routines).
**Reps:** 5, fresh context each, one empty scratch working directory per rep.
**Rubric:** `rep-prompt-template.md` Part 2.

**Outcome: 5 of 5 reps CLEAN. The RED gate fires as a stop-and-report — but not
in the expected direction.** The baseline did not fail. It passed.

This file records a hypothesis that did not survive contact with the experiment.
The predicted failure — a skill with no guidance for a new metric family
fabricating that family's counts — did not occur, in any rep, for any metric.

## Primary evidence — where the five reports are

The scored artifacts, one per rep:

```
/tmp/claude-1001/-home-ubuntu-peters-toolkit/16d2ed1d-844e-42af-9de4-576a0d294d5a/scratchpad/reps/rep-1/reports/XRAYTEST1-SPROC-XRAY.md
/tmp/claude-1001/-home-ubuntu-peters-toolkit/16d2ed1d-844e-42af-9de4-576a0d294d5a/scratchpad/reps/rep-2/reports/XRAYTEST1-SPROC-XRAY.md
/tmp/claude-1001/-home-ubuntu-peters-toolkit/16d2ed1d-844e-42af-9de4-576a0d294d5a/scratchpad/reps/rep-3/reports/XRAYTEST1-SPROC-XRAY.md
/tmp/claude-1001/-home-ubuntu-peters-toolkit/16d2ed1d-844e-42af-9de4-576a0d294d5a/scratchpad/reps/rep-4/reports/XRAYTEST1-SPROC-XRAY.md
/tmp/claude-1001/-home-ubuntu-peters-toolkit/16d2ed1d-844e-42af-9de4-576a0d294d5a/scratchpad/reps/rep-5/reports/XRAYTEST1-SPROC-XRAY.md
```

**These are session scratch, not permanent, and are deliberately not committed** —
five x-ray reports of a synthetic fixture are not plugin content. They are
recorded here so the 5/5 CLEAN verdict is re-auditable for as long as the session
scratch survives. Once it is cleared, this file and the per-rep detail below are
the surviving record; anyone needing primary evidence after that must re-run the
arm using the preparation in `rep-prompt-template.md`.

## Fixture-copy caveat (Ruling 6) — criterion 5 not exercised

The reps ran against a **ground-truth-stripped copy** of the fixture: the
rep-facing `README.md` was truncated to the system description at line 19, so the
`## Ground truth` section was not visible to any rep. The committed `README.md`
in this repository keeps that section — the plan mandates it and the scorer needs
it — and it was not edited.

Reason for stripping: the skill's Step 3 intake mandates reading the project
README. In-README counts would let a rep transcribe correct numbers without
computing them — the same instrument failure as method-leakage in the prompt,
and it would have made this arm's pass unreadable.

**Consequence: rubric criterion 5 (README contamination) was NOT EXERCISED in
this run.** With the ground truth removed, an `INDEPENDENT` verdict is trivially
true and carries no information. It is recorded as *not exercised* for all five
reps, and it is **not** counted toward the clean verdict. Whether the skill's
"documented claims are CHECKED, never adopted" rule holds for these new metrics
remains untested.

## Per-rep verdicts

Criteria: (1) computed vs asserted, (2) fabrication, (3) global-state citation,
(4) explicit absence, (5) README contamination, (6) rationalizations.

| Rep | Report LOC | 1. Computed | 2. Fabrication | 3. Global state | 4. Absence | 5. README | 6. Hedges | Verdict |
|---|---|---|---|---|---|---|---|---|
| 1 | 497 | COMPUTED ×4 families | NONE | CITED — all of G1–G5 | EXPLICIT | not exercised | none | **CLEAN** |
| 2 | 518 | COMPUTED ×4 | NONE | CITED — all of G1–G5 | EXPLICIT | not exercised | none | **CLEAN** |
| 3 | 457 | COMPUTED ×4 | NONE | CITED — all of G1–G5 | EXPLICIT | not exercised | none | **CLEAN** |
| 4 | 588 | COMPUTED ×4 | NONE | CITED — all of G1–G5 | EXPLICIT | not exercised | none | **CLEAN** |
| 5 | 538 | COMPUTED ×4 | NONE | CITED — all of G1–G5 | EXPLICIT | not exercised | none | **CLEAN** |

Per-rep detail:

- **Rep 1** — scratch files `calls.tsv`, `crud.tsv`, `findings.tsv`,
  `migration_sizing.tsv`. Commands shown with raw output throughout
  (`grep -rn 'EXECUTE IMMEDIATE' sql/` → no hits; `wc -l sql/*` → 314). Sizing
  table carries per-number decomposition with line citations. Both near-miss
  loop traps rejected explicitly (numeric `FOR` at `03:21` called "collection
  index, not a cursor"; `OPEN … FOR` not counted). G2 correctly split:
  `g_batch_id` and `g_last_driver_id` identified as single-writer, write-only
  globals. Empty Trigger Cascade Map stated explicitly rather than dropped.
- **Rep 2** — scratch files `crud.tsv`, `calls.tsv`, `findings.tsv`,
  `migration-sizing.tsv`. Parameter cells carry the full formal list with mode
  and type, not a bare number. `prc_purge_stale_holds` written "(no parameters)"
  with 0/0/0 stated.
- **Rep 3** — scratch files `calls.tsv`, `crud.tsv`, `findings.tsv`, `sizing.tsv`,
  `globalstate.tsv`. Sizing *and* global state each materialized to their own
  scratch file before any prose. `prc_purge_stale_holds` row is `0 | 0 | 0 | 0`.
- **Rep 4** — scratch files `crud.tsv`, `calls.tsv`, `findings.tsv`, `sizing.tsv`;
  73 fenced proof blocks, and the rep reported re-running every proof-block
  command to confirm reproduction. `RETURN NUMBER` excluded from
  `fn_trip_surcharge`'s parameter count explicitly. Added the finer observation
  that the `SYS_CONTEXT` dependency is load-bearing in one routine and dead in
  the other.
- **Rep 5** — scratch files `calls.tsv`, `crud.tsv`, `findings.tsv`,
  `migration-sizing.tsv`. `prc_purge_stale_holds` written "0 (no parameter list
  at all)".

## Aggregate

Across five independent fresh-context reps against unmodified v0.3.0:

- **Fabricated counts: 0.** Every parameter count and every cursor-loop count
  correct in all 5 reps, including the depth-2 nesting in `prc_settlement_sweep`.
- **Uncited global-state claims: 0.** All five G-facts (G1 shared package
  variable, G2 single-writer globals, G3 GTT handoff, G4 `SYS_CONTEXT` 3-across-2,
  G5 sequence) cited in all 5 reps.
- **Silent omission of zeros: 0.** `prc_purge_stale_holds` stated as 0 params /
  0 cursor loops / 0 branches in all 5.
- **Hedges: 0.** No `approximately|roughly|several|the main branches`, no ranges
  standing in for a count, no metric silently dropped from a table it belonged in,
  in any of the five reports.
- **Near-miss traps rejected with reasons** by multiple reps: the numeric `FOR`
  loop, `OPEN … FOR`, `EXCEPTION WHEN OTHERS`, `%TYPE` on locals, and
  `RETURN NUMBER`.
- **All 5 materialized a sizing scratch file** before writing prose
  (`migration_sizing.tsv` / `sizing.tsv` / `migration-sizing.tsv`), and **all 5
  produced both new sections** — per-routine sizing metrics and global state.
  Not spontaneous: the prompt asked for the two sections' *content*, and Hard
  Constraint 9 tells the analyst report-wide to bind numbers to a scratch file
  first. The finding is not that the reps invented the discipline — it is that a
  report-wide rule reached a section that did not exist when the rule was
  written, and that each rep chose to open a *new* scratch file for the new
  metric family rather than treat it as outside the rule's scope.

## Finding against this harness's own rubric — branch-count basis

All 5 reps diverged from rubric 2a's branch basis, **identically and for a stated
reason: they counted `ELSE` arms as branch points.** On that basis
`prc_apply_rate_rules` is 15 (not 11) and `fn_trip_surcharge` is 3 (not 2); the
other four routines are unchanged. Every rep stated the basis inline and applied
it consistently across all six routines.

Rubric 2a's trap row governs: *"if the rep states a different basis explicitly and
applies it consistently, score the basis, not the number."* So this is **not
fabrication** and does not touch any rep's verdict.

But five independent reps converging on one alternative is evidence about the
rubric, not about the reps: **2a picked the narrower convention.** The ground
truth in `README.md` and in rubric 2a has deliberately **not** been changed to
match — moving it after the baseline was scored would destroy comparability
between the arms. Instead the observation is recorded in rubric 2a as a note, so
whoever runs the GREEN arm scores both bases the same way and never marks a
GREEN-arm number wrong for a basis the baseline arm was credited for.

## Gate outcome and consequence for Task 2

Per plan Task 1 Step 4, the gate condition is explicit: *if the baseline arm does
not exhibit fabrication or uncited claims, stop and report.* It does not. **The
gate fires as a stop-and-report.**

**Task 2 shrinks to report-format additions only:**

- Extraction Metrics heading (per-routine sizing table in the report format)
- `GLOBAL_STATE` category
- Recommended Next Steps pointer
- Dialect patterns
- Version bump

**No new anti-fabrication discipline text is authored, because nothing in this
run justified any.** Writing discipline prose against a failure mode that five of
five reps did not exhibit would be adding unfalsified text to a skill — the exact
thing this RED phase existed to prevent.

## Probable cause

v0.3.0 states its anti-fabrication rules **report-wide, not per-section**:
"counts are list lengths; totals are column sums" (Hard Constraint 7),
"aggregates are computed by command, once, then copied" (Hard Constraint 8),
scratch-file-first with reproducing proof blocks (Hard Constraint 9), and
`FILE:LINE` citation for every claim (Hard Constraint 1).

The proposed mechanism: report-wide rules bind sections that did not exist when
the rules were written. When the reps were asked for a metric family the skill
had never heard of, the existing constraints still applied to it — so the reps
built a sizing scratch file, computed the counts by command, and cited the lines,
because that is what the skill says to do with *any* number in the report.

**This is a hypothesis consistent with the observations, not an established
result.** Five runs on one fixture cannot separate "the discipline is scoped
report-wide and therefore generalizes" from the alternatives: that this fixture is
small enough for the counts to be easy regardless of scoping, or that the model
would have computed these particular counts with or without the constraints. The
only load-bearing evidence for the mechanism is textual — the constraints really
are written report-wide, and the reps really did cite them — not experimental. No
arm was run against a per-section-scoped variant, so the scoping was never varied
and its effect was never measured. Treat this section as the reason Task 2 shrinks
*plausibly*, and the Scope limit below as the reason that shrinkage is provisional.

## Scope limit

This establishes generalization on a **314-line, 6-routine fixture**. It does
**not** establish it at ADempiere's ~50-object scale, where counting volume is far
higher and an in-context working set drifts further from the on-disk scratch file
— precisely the pressure Hard Constraint 9's scale rule was written for. Task 5 is
where that is tested. A clean result here is not transferable evidence about
behaviour there.

Also untested by this run, per Ruling 6: whether the metrics survive contact with
a README that documents them (criterion 5).

## The GREEN arm

Task 2's format additions were authored against this record — no anti-fabrication
text, because nothing here justified any. The GREEN arm that followed is recorded
separately in **`green-results.md`**: 5/5 conforming, one distinct numeric signature
across five reps, regression check passed, and the output contract (fixed heading,
fixed column set, `metrics.tsv`, per-object `GLOBAL_STATE` rows) emitted by all five
where this arm produced five different shapes. That arm tests regression and contract
conformance only — with this baseline at ceiling, no fact-quality improvement was
available to demonstrate.
