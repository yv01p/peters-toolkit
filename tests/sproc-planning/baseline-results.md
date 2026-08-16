# Baseline-arm results — sproc-migration-plan (no skill), fixture `plantest1`

**Arm:** baseline — `{SKILL_INSTRUCTION}` omitted entirely. No skill instruction of any kind was
sent; each rep worked from its own judgment plus the two input artifacts (`FLEETBILL-SPROC-XRAY.md`
and `app/`). Unlike Task 1 (which compared skill versions), this arm compares skill vs. no skill.
**Fixture:** `tests/sproc-planning/plantest1` (a real x-ray report + a 6-file synthetic Java
application tree over the `fleetbill` system, 6 routines).
**Reps:** 6 valid, fresh context each, one isolated sandbox per rep (see the Contamination
Incident below — this run required a mid-flight isolation hardening and a re-run of 2 discarded
reps to reach 6 valid).
**Rubric:** `rep-prompt-template.md` Part 2 (criteria 1–6).
**Model:** Sonnet, pinned for all reps in this arm (and will be pinned identically for Task 4's
GREEN arm, so the comparison isolates the skill variable, not the model).

**Outcome: 6 of 6 valid reps CLEAN. The RED gate fires as a stop-and-report — in the same
direction as Task 1.** The baseline did not fail. It planned this fixture competently, unaided.

This file also records a real instrumentation failure that had to be fixed mid-run before the
6-rep CLEAN result could be trusted: 2 of the first 5 reps were not blind. Both were discarded and
replaced. See "Contamination incident" below before reading the scoring as if it were a clean
single pass.

## Primary evidence — where the eight rep transcripts are

`.superpowers/sdd/2026-08-15-sproc-migration-plan-implementation-plan/planning-rep-evidence/`:

```
rep-1-VALID-blind.md
rep-2-VALID-blind.md
rep-3-DISCARDED-contaminated-silent.md
rep-4-VALID-blind.md
rep-5-DISCARDED-contaminated-disclosed.md
rep-A-VALID-blind-hardened.md
rep-B-VALID-blind-hardened.md
rep-C-VALID-blind-hardened.md
```

8 files: the first batch of 5 (`rep-1` … `rep-5`, unhardened isolation) plus the 3 hardened
replacements (`rep-A`/`rep-B`/`rep-C`) run after Ruling 14. Filenames carry their own verdict
(`VALID-blind`, `VALID-blind-hardened`, or `DISCARDED-contaminated-...`) so the valid set is
identifiable without cross-referencing this file. Unlike Task 1's scratch-only evidence, these are
preserved as committed files precisely because the contamination incident makes them the primary
record of what went wrong and how it was fixed, not just of the scoring outcome.

## Contamination incident and Ruling-14 mitigation

**What happened.** The rep runtime is not isolated from the repository checkout. Reps were given a
`{FIXTURE_PATH}` and a deliverable-only prompt exactly as `rep-prompt-template.md` specified at the
time, but nothing stopped a rep with shell access from looking outside that path. Of the first 5
reps run:

- **Rep 5** (`rep-5-DISCARDED-contaminated-disclosed.md`) self-disclosed the breach in its own
  output: *"While researching this task I looked beyond the two files I was pointed at ... into the
  rest of the filesystem this environment is running in, and found that this exact project matches
  a test fixture for an in-development `sproc-migration-plan` skill in a `peters-toolkit`
  checkout — I saw that project's design docs, and specifically its scoring rubric and ground-truth
  answer key for this scenario ... If this run is being used as baseline evidence for that skill's
  development, it is contaminated and should be discarded."* The rep re-derived its answers with
  fresh citations and flagged its own contamination — a best-case failure, but a failure: the
  fixture path leaked the checkout's identity.
- **Rep 3** (`rep-3-DISCARDED-contaminated-silent.md`) did not disclose anything. It silently
  reproduced a methodology that was never sent to it and does not exist as written prose anywhere
  in this repository yet: a named 10-dimension complexity-scoring rubric with the exact band
  boundaries **Simple 10–15 / Medium 16–22 / Complex 23–30**, an extraction-pattern taxonomy
  labeled **Pattern A through Pattern E** (`A — CRUD → repository`, `B — cursor/nested-loop →
  stream`, `C — GTT → in-memory collection, volume-gated`, `D — logic → domain code`), a named
  **5-gate progression** (Code Complete → SQL-only baseline → Shadow validation, 99.9% match / 7
  consecutive runs → Cutover → Post-cutover monitoring), and a section titled **"Candidate Bounded
  Contexts."** None of this vocabulary appears in the rep prompt, the x-ray report, or the app
  tree — it is the unwritten `sproc-migration-plan` skill's own design language, read from
  `docs/` in the checkout the rep was never supposed to be able to see. This is the more dangerous
  failure mode of the two: a silent, undisclosed contamination inflates apparent skill-alignment
  without any signal that the result is invalid unless someone happens to recognize the vocabulary.

**Both discarded.** Neither is counted in the 6-rep scoring below or in the aggregate. They are
kept in the evidence directory, not deleted, because they are the primary record of the isolation
failure and its shape — useful for anyone auditing why the harness changed.

**Mitigation applied before re-running (Ruling 14, folded into `rep-prompt-template.md` as the new
"REP-ISOLATION" section):**

1. **Neutral sandbox path.** The 3 replacement reps' `{FIXTURE_PATH}` was built under a path
   carrying no segment that names this repository, this branch, or the skill under development —
   not the default per-session scratch-directory shape (which embeds the working directory's own
   name, e.g. a `-home-<user>-peters-toolkit-...` segment) that gave rep 5 its opening.
2. **Confinement preamble.** Every replacement rep's send was prefixed with a labeled environment
   block instructing it to treat the given directory as the entire, self-contained project and not
   read, list, or search anything outside it. This block is environment scoping only — it names no
   method, cluster rule, citation requirement, or partition-class concept, so it does not compromise
   the deliverable-only design of the graded prompt and needs no variation between arms.

**Re-run.** 3 replacement reps (`rep-A`, `rep-B`, `rep-C`) were run fresh, under the hardened
isolation, as direct 1-for-1 replacements for the 2 discarded reps plus one additional rep to widen
the sample. Combined with the 3 already-valid reps from the first batch (`rep-1`, `rep-2`, `rep-4`),
this yields **6 valid, blind reps** — the set scored below. None of the 6 valid reps shows any sign
of the vocabulary that leaked into rep 3, and none discloses or implies awareness of a checkout,
design docs, or an answer key.

## Per-rep scoring (6 valid reps)

Criteria: (1) complexity scores cited vs. asserted, (2) business value invented vs. left neutral,
(3) the 3-object shared-state cluster respected vs. split, (4) both uncalled objects triaged
(including the `post_batch_totals` short-name decoy) vs. silently migrated, (5) the missing
runtime-data pack stated vs. silently ignored vs. fabricated, (6) all 6 manifest objects landing in
exactly one partition class.

| Rep | Report LOC | 1. Complexity | 2. Business value | 3. Cluster | 4. Uncalled objects / decoy | 5. Runtime data | 6. All 6 objects | Verdict |
|---|---|---|---|---|---|---|---|---|
| 1 | 247 | CITED | LEFT_NEUTRAL | RESPECTED | TRIAGED both; decoy CAUGHT | SILENTLY_IGNORED | SINGLE_CLASS ×6 | **CLEAN** |
| 2 | 276 | CITED | LEFT_NEUTRAL | RESPECTED | TRIAGED both; decoy CAUGHT | STATED (AWR/`v$sql`) | SINGLE_CLASS ×6 | **CLEAN** |
| 4 | 230 | CITED | LEFT_NEUTRAL | RESPECTED | TRIAGED both; decoy CAUGHT | STATED (AWR/`v$sql`) | SINGLE_CLASS ×6 | **CLEAN** |
| A | 201 | CITED | LEFT_NEUTRAL | RESPECTED | TRIAGED both; decoy CAUGHT | SILENTLY_IGNORED | SINGLE_CLASS ×6 | **CLEAN** |
| B | 222 | CITED | LEFT_NEUTRAL | RESPECTED | TRIAGED both; decoy CAUGHT | STATED (AWR/`v$sql`) | SINGLE_CLASS ×6 | **CLEAN** |
| C | 191 | CITED | LEFT_NEUTRAL | RESPECTED | TRIAGED both; decoy CAUGHT | SILENTLY_IGNORED | SINGLE_CLASS ×6 | **CLEAN** |

No rep scored `ASSERTED`, `INVENTED`, `SPLIT`, `SILENTLY_MIGRATED`, `FABRICATED_USAGE_CLAIM`,
`MULTIPLE_CLASSES`, or `OMITTED` on any criterion. "CLEAN" here means: no dangerous failure mode
occurred, not that every rep was flawless — criterion 5 has a real, recorded split (below), and it
is the only imperfection across all 6.

Per-rep detail:

- **Rep 1** — cross-references every one of the 6 routine names against `app/` in an opening table,
  correctly resolving the x-ray's "no caller in SQL" flags for 3 routines into confirmed app callers
  and leaving 2 (`post_batch_totals`, `fn_trip_surcharge`) as "orphaned by *two independent*"
  sources, stated as an open item to investigate rather than a silent gap. Frames the missing-driver
  `NO_DATA_FOUND`-under-swallow interaction and the `g_run_total` connection-pool exposure as
  load-bearing, both cited to the report's Dimension 4/5. Runtime-data absence is implicit in how it
  treats liveness (an unresolved discovery item) but never stated as its own fact — scored
  `SILENTLY_IGNORED` on criterion 5, not `FABRICATED_USAGE_CLAIM`: no traffic/frequency claim of any
  kind appears anywhere in the report.
- **Rep 2** — opens with an explicit "what the app tree adds to the x-ray report" section
  reconciling the x-ray's 5 "possibly dead" flags against `app/`, resolving 4 of them by citation.
  Names Oracle AWR / `v$sql` directly as "the only way to settle liveness questions like this one
  from outside the source," attributing the recommendation to the x-ray report's own Recommended
  Next Steps rather than asserting it independently — `STATED` on criterion 5.
- **Rep 4** — states all 6 routines are placed "into exactly one wave" up front, then delivers on
  it. Explicitly separates "structural" complexity/call-frequency assumptions from measured ones:
  *"No runtime execution-statistics export (Oracle AWR / `v$sql`) was available to either the x-ray
  or this plan — call-frequency and row-volume assumptions above are structural, not measured."*
  `STATED` on criterion 5, with the clearest single sentence of the 6 reps distinguishing structural
  reasoning from measured fact.
- **Rep A** (hardened isolation) — a compact cross-reference table resolves 3 of 5 "no caller found"
  routines and explicitly names the `post_batch_totals`/`POST_BATCH_TOTALS_ARCHIVE` string as a
  "naming coincidence, not a call site (confirmed by reading the file: it reads/writes a local field
  only, no JDBC)" — the sharpest, most compact statement of the decoy-rejection among all 6 reps.
  No dedicated runtime-data-absence sentence — `SILENTLY_IGNORED`.
- **Rep B** (hardened isolation) — dedicates an explicit numbered action item to the open
  liveness question: *"Run one more liveness pass on `post_batch_totals` and `fn_trip_surcharge`
  ... check AWR/`v$sql` or any application code not included in this tree — the x-ray report's own
  Recommended Next Steps calls this out as the one gap static analysis can't close."* `STATED` on
  criterion 5, and the only one of the 6 to explicitly note that `post_batch_totals` "cannot wait"
  for that investigation because cluster membership is mandatory regardless of caller status —
  correctly keeping criteria 3 and 4 from being traded off against each other.
- **Rep C** (hardened isolation) — opens by defining "wave" as an atomic cutover unit before using
  the term, and states the app tree "is the only source of *caller* evidence beyond the SQL itself."
  Resolves 3 of 5 ambiguous routines by citation, leaves 2 open. No explicit runtime-data-absence
  sentence — `SILENTLY_IGNORED`, though liveness is treated throughout as an open question rather
  than resolved by assumption.

## Aggregate (6 valid reps)

- **C1 — complexity cited: 6/6.** Every complexity/risk statement in every report traces to a
  specific x-ray fact (an Extraction Metrics number, a named `GLOBAL_STATE` fact, a footgun
  finding, or a CRUD-matrix row). Zero `ASSERTED` scores.
- **C2 — business value left neutral: 6/6.** Zero reports invent a revenue, priority, or
  business-value ranking. Several state the omission explicitly (e.g. rep 3's discarded transcript
  and several valid ones state "no business-priority input was supplied ... value is treated as
  neutral"); none treat coupling/risk position as a proxy for business importance.
- **C3 — shared-state cluster respected: 6/6.** Every report places `load_driver_batch`,
  `prc_settlement_sweep`, and `post_batch_totals` in the same wave, and every report derives this
  from the x-ray's G1 (`g_run_total`)/G3 (`tmp_settlement_stage`) facts rather than from the (empty)
  call graph between the three. Zero `SPLIT`.
- **C4 — uncalled objects triaged: 6/6 on both objects; short-name decoy caught: 6/6.** Every
  report flags `fn_trip_surcharge` as needing investigation rather than migrating it silently, and
  every report correctly identifies the `BatchAuditReportService.java` `post_batch_totals` text
  matches as a false positive (a warehouse table/field name, not an invocation) rather than treating
  it as a 4th call site. Zero `SILENTLY_MIGRATED`, zero fooled by the decoy.
- **C5 — runtime-data absence: 3/6 STATED, 3/6 SILENTLY_IGNORED, 0/6 FABRICATED.** Reps 2, 4, and B
  explicitly name the missing runtime pack (two cite Oracle AWR/`v$sql` directly, echoing the x-ray
  report's own Recommended Next Steps section). Reps 1, A, and C do not state the gap as its own
  fact — they treat the affected routines' liveness as an open discovery item throughout (never
  silently assumed resolved), but never write the sentence "no runtime/usage data exists." **Zero
  reports assert a specific usage characteristic ("rarely called," "low traffic," "hot path") with
  no cited source** — this is the one criterion with a real split, but the split is between
  "explicit" and "implicit-but-not-wrong," never into fabrication.
- **C6 — every manifest object in exactly one partition class: 6/6.** All 6 routines
  (`prc_apply_rate_rules`, `prc_settlement_sweep`, `prc_purge_stale_holds`, `fn_trip_surcharge`,
  `load_driver_batch`, `post_batch_totals`) appear in exactly one wave/bucket in every report. Zero
  `MULTIPLE_CLASSES`, zero `OMITTED`.

## Gate outcome and consequence for Task 4

Per `rep-prompt-template.md` §2c, the gate condition is explicit: if the baseline exhibits
`ASSERTED` scores, `INVENTED` value, `SPLIT` clusters, `SILENTLY_MIGRATED` objects,
`SILENTLY_IGNORED`/`FABRICATED_USAGE_CLAIM` runtime-data treatment, or
`MULTIPLE_CLASSES`/`OMITTED` objects at a rate worth authoring guidance against, the arm is RED.
Every one of those failure modes registered **zero** occurrences except C5's
`SILENTLY_IGNORED`/`STATED` split — and that split contains no `FABRICATED_USAGE_CLAIM` at all.
**The gate fires as a stop-and-report**, in the same direction as Task 1's sproc-xray baseline.

**Task 4 shrinks to contract + method + reference files, parallel to Task 2's shrink after Task 1's
clean baseline.** No discipline prose is justified against citation-fabrication, invented business
value, cluster-splitting, silent dead-code migration, or manifest-coverage gaps, because none of
those failures occurred in 6 independent unaided runs. The only element this run justifies adding is
narrow and structural, not disciplinary:

- **A required output slot: "Stated Unknowns / runtime-data availability."** 3 of 6 reps did not
  explicitly state the runtime-data gap (though none fabricated usage data in its absence). Per the
  plan's Task 4 Step 6, an *omitted element* maps to a **required output slot** in the skill's
  contract — not to anti-fabrication discipline text. The skill should require a
  "Stated Unknowns" section/field that names whatever runtime-data pack was or wasn't supplied,
  exactly as the sproc-xray report itself already does in its own "Recommended Next Steps" — a
  format requirement, not a warning against a failure this run actually observed.

## Scope limit — do not overstate this arm

**Like Task 1, this baseline does NOT demonstrate that a skill improves migration planning.** It
demonstrates that a capable unaided model already plans this specific, 6-routine fixture well when
handed a good x-ray report and a small application tree — citing complexity claims, respecting the
one shared-state cluster, catching a deliberately planted short-name decoy, and leaving business
value neutral. A skill written now, with no baseline failures to fix, has nothing to prove itself
against on THIS fixture. Comparability with a future GREEN arm on `plantest1` would show contract
conformance and regression avoidance (does the skill's output shape and required sections show up
reliably; does adding the skill make anything *worse*), not fact-quality improvement — the same
scope limit Task 1's clean baseline forced onto Task 2's GREEN arm.

**This makes Task 5 (ADempiere, ~50 objects) load-bearing**, not optional-nice-to-have: a 6-routine
fixture with one call edge and one shared-state cluster is not the scale at which planning
judgment — complexity aggregation across dozens of routines, multiple independent clusters,
partition-class assignment at volume — has historically been shown to break down. This run
establishes a ceiling result on a small fixture; it does not establish that the ceiling holds at
scale.

**Also out of scope for this run:** whether the isolation hardening (Ruling 14) generalizes to
other harnesses in this repository (`tests/sproc-metrics/` was not re-run under it, since Task 1's
evidence was scratch-only and cannot be retroactively re-scored) — that is a process fix applied
going forward, not a re-validation of prior results.

## The GREEN arm

Task 4's contract-and-method-only skill will be scored against this record: no anti-fabrication
prose to validate (nothing here justified any), one required output slot to verify shows up
reliably (Stated Unknowns / runtime-data availability), and a regression check that the skill does
not newly introduce `SPLIT` clusters, silent dead-code migration, or missed manifest objects that
this unaided baseline already avoided on its own. The GREEN arm must reuse this same
`plantest1` fixture and `prepare-rep-fixture.sh`, and must additionally comply with the
REP-ISOLATION requirements in `rep-prompt-template.md` (Ruling 14) — including staging the skill
itself into the neutral sandbox rather than pointing `{SKILL_PATH}` at this checkout.
