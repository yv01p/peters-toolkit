# GREEN-arm results — sproc-migration-plan (skill staged), fixture `plantest1`

**Arm:** GREEN — the `{SKILL_INSTRUCTION}` line pointed each rep at a STAGED copy of the
`sproc-migration-plan` skill placed inside its own neutral sandbox (`<sandbox>/proj/plantest1/_skilldef/SKILL.md`),
per the Ruling-14 isolation model. Same fixture prep (`prepare-rep-fixture.sh`), same model
(Sonnet, pinned identically to the RED arm so the comparison isolates the skill variable), and the
same deliverable-only prompt as `baseline-results.md`'s RED arm, modulo the documented
`{SKILL_INSTRUCTION}` line and the Ruling-15 single-line skill-copy edit described below.
**Fixture:** `tests/sproc-planning/plantest1` (the same real x-ray report + 6-file synthetic Java
application tree over the `fleetbill` system, 6 routines, used for the RED arm).
**Reps:** 5 valid, fresh context each (g1–g5), one isolated neutral-path sandbox per rep
(`/tmp/rep-sandbox-g{1..5}/proj`), general-purpose subagents (not `fork`, so no controller context
— including the answer key — could leak in).
**Rubric:** `rep-prompt-template.md` Part 2 (criteria 1–6, the same six RED-arm criteria) plus a
contract-conformance checklist derived from the skill's own output contract (Steps 2–3, 5 of the
implementation plan).
**Model:** Sonnet, pinned identically to the RED arm.

**Outcome: 5 of 5 valid reps CLEAN on the RED arm's 6 regression criteria, and FULL on contract
conformance (with one verified exception — see "Implementer verification note" below). Convergence
MET on the first GREEN round; Step-7 REFACTOR has nothing to justify it.** The skill's justified
value — standardizing 6 independently-invented plan formats (RED arm) into one output contract —
shows up cleanly. No new dangerous failure mode was introduced.

## Pre-registration — read this before the scoring below

**This arm is a CONTRACT-CONFORMANCE + regression check, NOT an improvement demonstration.** The
RED baseline (`baseline-results.md`) was already clean — at ceiling on judgment: 6/6 unaided reps
cited every complexity claim, respected the one shared-state cluster, triaged both uncalled
objects, and caught the short-name decoy unaided. A skill written against a clean baseline has
nothing to prove itself against on THIS fixture (the same scope limit Task 2's GREEN arm operated
under after Task 1's clean baseline).

**Decoy-catching in this arm is skill-fed and is explicitly NOT scored as improvement.** The
skill's own Input-Contract illustrative examples reuse this fixture's object names and the exact
short-name decoy (`post_batch_totals` / `POST_BATCH_TOTALS_ARCHIVE` /
`BatchAuditReportService.java`) as its worked example of the over-match caveat. Every GREEN rep
that "catches" the decoy is pattern-matching against an example the skill handed it, not
demonstrating independent judgment the way the 6 RED reps did unaided. GREEN's C4 decoy score is
recorded below for completeness (and to confirm the skill did not somehow make it worse), not as
evidence of a capability gain.

## Primary evidence — where the five rep transcripts are

`.superpowers/sdd/2026-08-15-sproc-migration-plan-implementation-plan/green-evidence/`:

```
green-rep-g1.md   (579 lines)
green-rep-g2.md   (548 lines)
green-rep-g3.md   (477 lines)
green-rep-g4.md   (450 lines)
green-rep-g5.md   (548 lines)
```

All 5 are valid (no discards this round — the Ruling-14/15 isolation held on every rep; see
tell-scan below).

## Ruling 15 — isolation hardening disclosure (GREEN arm only)

The staged skill copy each rep read had **one** navigable repo-path reference neutralized before
staging: `SKILL.md`'s Maintainer note cited `tests/sproc-planning/baseline-results.md` (the
RED-arm answer-key-and-scoring file) by relative path. GREEN reps run via the Agent tool with
`cwd` = the repo root, so that relative path would resolve to the real scoring file from a rep's
shell — a wander channel the RED arm never had (RED reps had no skill pointing them anywhere). In
each of the 5 staged copies, the parenthetical citing that path was replaced with a non-navigable
description of the same fact (why the shrink happened), a single-line diff versus the shipped
skill. No other repo-path channel remained in any staged copy (grep for
`tests/|docs/|.superpowers|peters-toolkit|skills/sproc` → clean in all 5).

This is not instrument tampering: the Maintainer note is a meta-note about *why* the skill is
shaped as it is, not a planning method any rep follows, and the edit closes an answer-key channel
without altering any behavior the skill instructs — the same class of move as excluding
`plantest1/README.md` from the RED-arm fixture (Ruling 13). **The full, verbatim skill is what
ships in `skills/sproc-migration-plan/`; only the throwaway staged test copies under
`/tmp/rep-sandbox-g{1..5}/` were edited, and those copies are not part of this commit.**

## Tell-scan: 5/5 CLEAN / blind

Unlike the RED-arm tell-scan (which looks for skill-methodology vocabulary a blind rep should
never produce), the GREEN tell-scan looks for the **inverse** signal: answer-key/rubric vocabulary
("RED gate," "SILENTLY_MIGRATED," "verdict") or any disclosure of reading something outside the
sandbox. Skill-methodology vocabulary (waves, clusters, Pattern A–E, the 5-gate progression,
complexity bands) is **expected** in this arm, since every rep read the staged skill — it is not a
contamination tell here the way it was in the RED arm.

All 5 reps: zero answer-key/rubric vocabulary, zero out-of-sandbox disclosure. Every one of the 6
call-site classifications is derived inline from a cited x-ray fact or a cited `app/` grep hit,
never asserted as if transcribed. One phrase was inspected and cleared: g5 writes
`FLEETBILL-SPROC-XRAY.md (repo root)`, which — read in context — means the top of *that rep's own
sandbox* (where the report file sits), not the real repository; every citation in g5 resolves to a
fixture file. The Ruling-15 neutralization held: no rep's output cites or alludes to
`baseline-results.md` or any other repository path.

## Contract conformance

**FULL on every structural element checked, with one verified exception on the terminal-stop
textual marker (g4) — see the verification note below.**

- All 5 reps produced a single wave-sequenced plan document consuming `FLEETBILL-SPROC-XRAY.md`
  and `app/`, with no other input assumed.
- All 8 method steps are present in all 5 (intake/validation; consumer analysis; dead-code triage;
  10-dimension complexity scoring; cluster detection; pattern assignment A–E; wave assembly;
  validation stamping — the last folded into each wave brief's "Validation requirements"
  subsection rather than a separate top-level heading in any of the 5, which is a legitimate
  placement of the same content, not a divergence between reps).
- Every wave carries the 6-part wave-brief contract (theme & rationale; unit table; cluster
  constraints; blocking dependencies; validation requirements; rollback expectation), and every
  unit table uses the same 6-column shape — `Object | Complexity(+band) | Per-dimension evidence |
  Pattern | SQL retained? | x-ray FILE:LINE` — in all 5. (Minor formatting note, not a conformance
  gap: g1's header cell reads `Complexity`, the other four read `Complexity (sum + band)`; every
  cell's *content* in all 5 carries both the sum and the band regardless of the header label.)
- All 6 plan-level sections are present in all 5: deletion candidates, retained-in-DB objects,
  deferred/needs-investigation, inherited coverage, candidate bounded contexts (flagged only), and
  the required Stated-Unknowns/runtime-data-availability slot.
- Self-consistency reconciliation is shown inline in all 5: partition arithmetic
  (`5 wave-assigned + 0 deletion + 0 retained-in-DB + 1 deferred = 6`, matching the Extraction
  Metrics routine count), wave-table row counts equal each wave's stated unit count, and a
  dedicated dual-path reconciliation line.
- Business value is stated as neutral, with the reason given (no Input-4 user constraints
  supplied), in all 5 — zero invented business-value terms.
- Terminal-stop **behavior** (no auto-invocation of `thorough-brainstorming` or any other skill) is
  honored in all 5 — none of the 5 documents invokes anything. The **textual marker** is present in
  4 of 5: g1 and g5 carry it as an explicit `## Terminal STOP` heading; g2 states it in prose
  ("This plan is the terminal handoff..."); g3 states it as bolded lead-in prose ("**Terminal
  STOP.** This plan is the handoff..."). **g4 contains no terminal-stop or no-auto-invoke statement
  anywhere in the document** (verified by direct grep for "terminal" — zero hits; the document ends
  after its Stated-Unknowns section). See the verification note below — this is a real,
  independently-confirmed gap, not a scoring dispute over wording.

## Regression (RED-arm 6 criteria, scored against fixture ground truth)

| # | Criterion | Result |
|---|---|---|
| C1 | Complexity cited vs. asserted | **CITED 5/5** — every non-baseline dimension traces to a named x-ray fact (Extraction Metrics number, GLOBAL_STATE row, CRUD Matrix row, or Dimension-5 finding). Zero `ASSERTED`. |
| C2 | Business value invented vs. left neutral | **LEFT_NEUTRAL 5/5** — zero invented business-value terms; all 5 state the Input-4 omission explicitly. |
| C3 | Shared-state cluster respected vs. split | **RESPECTED 5/5** — `{load_driver_batch, prc_settlement_sweep, post_batch_totals}` land in Wave 2 together in every rep, derived from G1 (`g_run_total`)/G3 (`tmp_settlement_stage`), never from the (empty) call graph. Zero `SPLIT`. |
| C4 | Uncalled objects triaged; short-name decoy caught | **TRIAGED 5/5 on both objects; decoy CAUGHT 5/5** — every rep read `BatchAuditReportService.java` per-hit and rejected `POST_BATCH_TOTALS_ARCHIVE`/`postBatchTotalsRowCount` as name proximity, not invocation. `post_batch_totals` is wave-assigned as a forced cluster member in all 5, with its own no-caller-found status stated explicitly in every rep (TRIAGED, not SILENTLY_MIGRATED). (Per the pre-registration note above: this decoy is skill-fed in this arm, not scored as a capability gain.) |
| C5 | Runtime-data absence stated vs. silently ignored vs. fabricated | **STATED 5/5, FABRICATED 0/5** — every rep's required Stated-Unknowns section names the absent runtime pack as its own fact. This is an improvement on the RED arm's 3/6 STATED (3/6 SILENTLY_IGNORED) — the required output slot did the job it was added for. |
| C6 | Every manifest object in exactly one partition class | **SINGLE_CLASS 5/5** — all 6 routines (5 wave-assigned + 1 deferred, `fn_trip_surcharge`) appear in exactly one partition class in every rep, with the arithmetic shown inline. Zero `MULTIPLE_CLASSES`, zero `OMITTED`. |

All 6 fixture classifications are correct in all 5 reps: `prc_apply_rate_rules` DB-internal-only
(caller `prc_settlement_sweep` migrates too, so it is wave-assigned, not retained-in-DB);
`prc_settlement_sweep` app-called at 2 independent sites/2 casings; `prc_purge_stale_holds`
app-called; `fn_trip_surcharge` uncalled → deferred; `load_driver_batch` app-called;
`post_batch_totals` uncalled by call graph → cluster-bound, wave-assigned.

## Per-rep summary

| Rep | Tell-scan | Conformance | Regression | Notable feature |
|---|---|---|---|---|
| g1 | CLEAN | FULL | CLEAN | Unique among the 5: states explicitly that `prc_apply_rate_rules` has no direct app call site, so its Gates 3–5 execute inside Wave 2's own integration/validation cycle rather than standalone — the most sophisticated gate-mechanics reasoning of the 5. |
| g2 | CLEAN | FULL | CLEAN | The only rep with **0** dual-path units — reasons that `prc_apply_rate_rules`'s SQL is not permanently retained, only covered by the standard 30-day window, since no DB-internal caller survives Wave 2's own cutover. Also the sharpest cross-cluster note on the `trips` hub-table ownership question. |
| g3 | CLEAN | FULL | CLEAN | Frames the CRITICAL exception-swallow bug as a decision for Wave 2's own TB session ("reproduce vs. fix," explicitly not resolved by this plan) rather than mandating a pre-wave SQL patch. |
| g4 | CLEAN | FULL except: no terminal-stop/no-auto-invoke statement anywhere in the document (verified; see note below) | CLEAN | The most directive of the 5 on the CRITICAL swallow bug: treats the SQL patch as a **blocking pre-wave action item** ("must be patched in the SQL routine first... under its own small-blast-radius change, with stakeholder sign-off") rather than a flagged TB-session decision. |
| g5 | CLEAN | FULL | CLEAN | Names the "ADempiere-precedent (retained-in-DB) exception" explicitly by that name when explaining why `prc_apply_rate_rules` is wave-assigned rather than retained-in-DB. Its own Stated-Unknowns section self-disclosed the Dimension-8 judgment call as a reproducible, non-unique planner choice — the only rep to flag its own scoring judgment that way. |

## Convergence / REFACTOR decision

**MET on the first GREEN round. Step-7 REFACTOR has nothing to justify it** — parallel to Task 2's
GREEN arm. Contrast with the RED arm: 6 blind reps produced 6 divergent formats (Wave 0–3 / Wave
0–2 / Wave 1–4 numbering, divergent section schemes, no shared unit-table shape). The GREEN arm
produced 5 plans that all conform to **one** output contract — exactly the standardization the
skill was authored to produce.

The remaining rep-to-rep differences are **content judgments the skill deliberately leaves to the
planner**, not output-shape divergences a refactor could or should fix:

**(a) Dual-path count.** g1, g3, g4, g5 mark `prc_apply_rate_rules` `SQL retained: yes` (retained
at least through Wave 2's own SQL_ONLY/rollback window, since Wave 2's `prc_settlement_sweep` still
calls it from inside the database until its own cutover). g2 marks it `SQL retained: no`, reasoning
that once Wave 2's cutover lands, no DB-internal caller of `prc_apply_rate_rules` survives, so only
the universal 30-day post-cutover window applies — not a permanent dual-path attribute. Both
positions are cited and internally consistent, and the dual-path reconciliation **line** required
by the contract is present in all 5 regardless of which way each rep resolved the judgment.

**(b) Dimension-8 (External calls) scoring of `prc_settlement_sweep`'s `FROM dual`.** The x-ray
itself characterizes `FROM dual` as "a normal, universal Oracle construct... not flagged as a
risk" that "disappears on migration to a bare SELECT." Whether to count it under Dimension 8's
literal fed-from source (Dimension 2's External/Unresolvable Edges) anyway, for mechanical
scoring consistency, or to exclude it because the x-ray itself disclaims it as risk-free, is a
genuine judgment call — and g5 says so explicitly in its own Stated Unknowns: *"a different,
equally defensible planner could score it 1 instead of 2 without changing the Medium band."*
**Verified split: g1, g3, g4 score it 1 (excluded); g2, g5 score it 2 (counted).** Every rep states
its reasoning inline, and the band is unaffected either way (`prc_settlement_sweep` lands Medium at
16 or 17 regardless) — this is a labeled judgment call, not a format defect.

**(c) Wave-1 gate mechanics.** g1 is the only rep to note that `prc_apply_rate_rules` has no direct
application call site of its own, so while Gates 1–2 complete standalone in Wave 1, Gates 3–5
(shadow, cutover, monitoring) require live call traffic that only exists once Wave 2 wires
`prc_settlement_sweep`'s app-side sweep logic to call it — so those gates execute inside Wave 2's
own integration/validation cycle rather than being blocked or skipped. This is a more sophisticated
reading of the gate progression than the other 4 reps state, and it is cited and self-consistent —
a richer judgment, not a contract violation by the other 4 (whose plans do not contradict it; they
simply do not spell out the mechanism as explicitly).

None of (a)–(c) is a format defect a REFACTOR could fix — the skill's contract-shaped sections
(unit table, plan-level sections, self-consistency reconciliation, Stated Unknowns) are identical
in structure across all 5, and the three items above are exactly the class of judgment the skill's
Overview states is the planner's own to make, each one cited to the fact it rests on.

## Implementer verification note (spot-check against the preserved evidence)

Per the task brief, the 5 preserved rep plans were spot-checked against the controller ledger's
GREEN-arm scoring (`progress.md`, "Task 4 — Step 9 GREEN arm" section) before this file was
written. Two points where direct verification (`grep`/inline reading of all 5 transcripts)
produced a different result than the ledger's stated characterization are recorded here rather
than silently corrected, per the task's explicit instruction — these are controller-scoring
questions, not something this authoring pass resolves unilaterally:

1. **Dimension-8 attribution.** The ledger's controller-log entry states the split as "g1 scores 1
   ... vs g2/g4/g5 score 2." Direct reading of all 5 transcripts' complexity tables (cited above,
   variance (b)) found the split to be **g1/g3/g4 score 1 vs g2/g5 score 2** — the opposite
   3-vs-2 grouping on two of the five reps (g3 and g4 land on the "1" side, not the "2" side). The
   band conclusion the ledger draws ("band unchanged") is still correct regardless of grouping.
   This file's variance-(b) writeup above uses the verified grouping, not the ledger's.
2. **Terminal-stop textual marker on g4.** The ledger states "g2/g4 state the terminal-handoff/
   no-auto-invoke in prose." Direct `grep -in "terminal"` and a full read of `green-rep-g4.md`
   found **zero** occurrences of "terminal," "handoff," or "auto-invok(e/ed)" language anywhere in
   that document — it ends after its Stated-Unknowns section with a business-value bullet. g2 does
   carry such a prose statement; g4 does not. The behavioral rule (no skill is actually
   auto-invoked) still holds trivially for g4, since the document contains no invocation of
   anything — so this does not change the convergence/no-REFACTOR conclusion above, and the ledger
   itself notes the textual marker is "not a required section." But the specific claim that g4
   contains such a statement is not supported by the preserved evidence, and this file's
   "Contract conformance" section above states the verified 4-of-5 result rather than the ledger's
   5-of-5 characterization.

Neither point changes the arm's headline outcome (5/5 regression-clean, convergence met, no
REFACTOR justified) — both are narrow, single-fact corrections inside an otherwise-confirmed
scoring record. They are surfaced here, and in the Task 4 implementer report, for the controller
to reconcile with the ledger; this file does not alter `progress.md`.

## Scope limit — do not overstate this arm

Per the pre-registration above: this arm demonstrates that the skill's output contract reliably
standardizes 5 independent reps onto one plan format, without regressing any of the 6 RED-arm
regression criteria, and that the one required addition (the Stated-Unknowns slot) closed the gap
it was added for (3/6 → 5/5 on runtime-data disclosure). It does **not** demonstrate that the skill
improves planning judgment on this fixture — the RED baseline was already clean, and the skill's
own worked examples feed this fixture's short-name decoy, so decoy-catching here is not independent
evidence of anything. As `baseline-results.md` already states, Task 5 (ADempiere, ~50 objects) is
where the skill's judgment-carrying value must be demonstrated at a scale this 6-routine fixture
cannot exercise.
