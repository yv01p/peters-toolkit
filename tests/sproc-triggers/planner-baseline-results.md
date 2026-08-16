# Baseline-arm results — sproc-migration-plan wave-planning (no-skill), trigger fixture `trgplan1`

**Arm:** baseline — `{SKILL_INSTRUCTION}` omitted entirely. No skill instruction of any kind was
sent; each rep worked from its own judgment plus the two input artifacts
(`TRIGGER-SPROC-XRAY-baseline.md` and `app/`). This compares skill vs. no-skill, the same axis as
the sibling fleetbill planner baseline (`tests/sproc-planning/baseline-results.md`) — not
skill-version-vs-skill-version like Task 1's xray baseline in this same directory.
**Fixture:** `tests/sproc-triggers/trgplan1` — the pre-Component-A `TRIGGER-SPROC-XRAY-baseline.md`
report (2 migration logic units: `prc_log_status_change`, `trg_account_status_sync`; the trigger is
present in the Component Manifest and the Dimension-3 Trigger Cascade Map but absent from the
`### Extraction Metrics` table by report design) plus a 3-file synthetic Java application tree
(`AccountStatusService.java`, `StatusChangeBackfillJob.java`, `ConnectionProvider.java`) that calls
`prc_log_status_change` from 2 sites and never references the trigger. Rep-facing copy built by
`prepare-planner-fixture.sh`, `README.md` (the answer key) excluded.
**Reps:** 5, fresh context each (Sonnet, pinned), one neutral leak-free sandbox per rep
(`/tmp/plsb/{b1..b5}/trgplan1`) — REP-ISOLATION (Ruling D / parent Rulings 14/15) applied to every
rep: neutral sandbox path plus the confinement preamble.
**Rubric:** `planner-rep-prompt-template.md` Part 2 (criteria 1–6).

**Outcome: 5 of 5 reps CLEAN. The RED gate does not fire — 0/5 on every RED axis. This is a
stop-and-report, in the same direction as the sibling fleetbill planner baseline and Task 1's xray
baseline in this directory. Component B (trigger-aware wave planning) is UNJUSTIFIED as specified.
The user has decided to DROP Task 4 and ship Component A only (Tasks 1–2, the sproc-xray change)
as this plan's sole deliverable.**

An adversarial Opus reviewer, run independently of the controller's own scoring, confirmed the
CLEAN verdict — see "Adversarial review" below.

## Primary evidence

`/tmp/plsb/{b1,b2,b3,b4,b5}/trgplan1/plan.md` — 5 full rep plans. **These are not committed** —
consistent with the convention `tests/sproc-planning/baseline-results.md` and
`tests/sproc-triggers/xray-baseline-results.md` both document for their own scratch-only evidence
(Ruling F). They are recorded here as a path so the scoring below is re-auditable for as long as
that scratch location survives; the scoring itself, and the summarized citations below, are the
durable record once it is cleared.

## Tell-scan / isolation check

All 5 reps tell-scan CLEAN: zero hits for any string that would indicate a rep saw outside its
sandbox or was told about the harness (`peters-toolkit`, `sproc-triggers`, `trigger-first-class`,
`worktree`, `trgplan1/README`, `baseline arm`, `planner-rep-prompt-template`, `scoring rubric`,
`blind rep`). All 5 ran under a neutral sandbox path (`/tmp/plsb/b1/trgplan1` … `/tmp/plsb/b5/trgplan1`
— no segment naming this repo, branch, or skill), no `{SKILL_INSTRUCTION}` of any kind sent (true
no-skill baseline), consistent with REP-ISOLATION.

## Per-rep scoring (5 reps)

Criteria (`planner-rep-prompt-template.md` Part 2b): (1) trigger present, exactly one partition
class; (2) trigger liveness classification; (3) Dimension-3 cascade respected; (4) citations for
trigger complexity/liveness/ordering claims; (5) runtime-data absence stated; (6)
`prc_log_status_change` placed correctly.

| Rep | 1. Trigger placement | 2. Liveness | 3. Dim-3 cascade | 4. Citations | 5. Runtime absence | 6. `prc` placement | Verdict |
|---|---|---|---|---|---|---|---|
| b1 | SINGLE (Wave 2) | LIVE_ENTRY_POINT | RESPECTED | CITED | STATED | CORRECT | **CLEAN** |
| b2 | body decomposed across W2/3/4, reassembled + retired in W4 — deliberate, cascade-respecting, not an under-count | LIVE_ENTRY_POINT | RESPECTED | CITED | STATED | CORRECT | **CLEAN** |
| b3 | SINGLE (Wave 2) | LIVE_ENTRY_POINT | RESPECTED | CITED | STATED | CORRECT | **CLEAN** |
| b4 | SINGLE (Wave 2) | LIVE_ENTRY_POINT | RESPECTED | CITED | STATED | CORRECT | **CLEAN** |
| b5 | SINGLE (Wave 2) | LIVE_ENTRY_POINT | RESPECTED | CITED | STATED | CORRECT | **CLEAN** |

No rep scored `OMITTED` or `MULTIPLE` on criterion 1, `DEFERRED_NO_CALLER` or `DEAD` on criterion 2,
`DROPPED` on criterion 3, `ASSERTED` on criterion 4, `SILENTLY_IGNORED`/`FABRICATED_USAGE_CLAIM` on
criterion 5, or `WRONG` on criterion 6. "CLEAN" here means: no dangerous failure mode occurred, not
that every plan took an identical shape — b2's decomposition is a real structural divergence from
the other 4 (see below), scored CLEAN because it respects rather than breaks the trigger's
liveness, singularity of role, and cascade ordering.

### Per-rep detail

- **b4** diagnosed the fixture's central trap unprompted, in its own words: *"it's not in the
  Extraction Metrics table because it's a trigger... decompose it from the Trigger Cascade Map."*
  It correctly reasons past the Extraction Metrics table's scope (procedures/functions only) to the
  Component Manifest and Dimension-3 Cascade Map, and places the trigger as a single Wave-2 unit,
  `LIVE_ENTRY_POINT`, with the report's own "prc first, trigger last" Extraction Sequencing note
  cited directly.
- **b1, b3, b5** independently reach the same shape as b4: a single Wave-2 placement for the
  trigger, `LIVE_ENTRY_POINT` liveness reasoned from the trigger's own definition and its cited
  firing DML (not from an app-caller search), and the Dimension-3 cascade cited to bind
  `prc_log_status_change` and `trg_account_status_sync` into the same wave with the report's
  documented internal order.
- **b2** is the one structural outlier: rather than treating the trigger as one atomic unit, it
  decomposes the trigger body into pieces distributed across Waves 2, 3, and 4 (e.g. separating the
  `account_holds` cursor-loop release logic from the self-referential `accounts` update from the
  final call into `prc_log_status_change`), then explicitly reassembles and retires the original
  trigger object in Wave 4. This is not an under-count — the trigger's full logic is accounted for
  exactly once across the plan, the cascade order to `prc_log_status_change` is preserved, and the
  decomposition is stated as a deliberate extraction strategy (moving trigger sub-behaviors into
  application code incrementally) rather than a byproduct of missing or misreading the trigger. The
  adversarial reviewer specifically probed this rep (see below) and ruled it CLEAN.

## Aggregate (5 reps)

- **C1 — trigger placement: 5/5 non-failing** (4/5 `SINGLE`, 1/5 a deliberate cross-wave
  decomposition that still accounts for the trigger exactly once end-to-end). **Zero `OMITTED`,
  zero unintentional `MULTIPLE`.** No rep built its migration-unit set from the
  `### Extraction Metrics` table alone — every rep drew from the Component Manifest and/or the
  Dimension-3 Cascade Map to recover the trigger.
- **C2 — liveness: 5/5 `LIVE_ENTRY_POINT`.** Zero reps routed the trigger to
  `DEFERRED_NO_CALLER`, "no caller found," "needs investigation," or `DEAD` for want of an
  app-tree reference. Every rep reasoned liveness from the trigger's own definition and its cited
  (externally-firing) DML, exactly as the report itself does in its Dead/Orphan Code section.
- **C3 — Dimension-3 cascade: 5/5 `RESPECTED`.** Every plan binds and sequences
  `trg_account_status_sync` and `prc_log_status_change` per the report's own cascade — none treats
  them as independent, unrelated units.
- **C4 — citations: 5/5 `CITED`.** Every trigger complexity/liveness/ordering claim in every plan
  traces to a specific x-ray report fact (the Component Manifest trigger row, the Dimension-2
  Dependency Graph, the Dimension-3 Cascade Map, or the Dead/Orphan Code section). Zero `ASSERTED`.
- **C5 — runtime-data absence: 5/5 `STATED`.** Every plan explicitly names the missing runtime
  evidence pack, several echoing the report's own Recommended Next Steps section directly. Zero
  `SILENTLY_IGNORED`, zero `FABRICATED_USAGE_CLAIM`.
- **C6 — `prc_log_status_change` placement: 5/5 `CORRECT`.** Every plan places it as a normal, live
  migration unit, citing both its app callers and its DB-internal caller (the trigger).

**Aggregate: 0/5 on every RED axis** (partition under-count, `DEFERRED_NO_CALLER`/`DEAD` routing,
dropped Dim-3 cascade, uncited trigger claims, silent/fabricated runtime-data treatment, wrong
`prc_log_status_change` placement).

## Root cause

The pre-Component-A x-ray report already carries every bit of trigger-awareness Component B was
designed to add to the planner:

- The **Dimension-3 Trigger Cascade Map**, which gives the full `UPDATE accounts → TRIGGER →
  CALL prc_log_status_change → INSERT` chain with file:line citations.
- The **Dimension-2 Dependency Graph**, which names `trg_account_status_sync` as the corpus's one
  entry point.
- The **"prc first, trigger last" Extraction Sequencing note**, which states the correct
  leaf-then-entry-point order directly.
- The **Dead/Orphan Code analysis**, which states explicitly that "a trigger is always an entry
  point... not evidence of dead code" — pre-empting the DEFERRED_NO_CALLER/DEAD misroute this
  fixture was designed to bait.

A capable unguided planner reads the *whole* report, not just the `### Extraction Metrics` table,
and every one of the 5 reps did exactly that — b4's unprompted diagnosis ("it's not in the
Extraction Metrics table because it's a trigger... decompose it from the Trigger Cascade Map") is
the clearest single statement of this, but all 5 reps' citations trace to the same non-Metrics
sections. The fixture's intended trap — a planner that keys its unit list off the Extraction
Metrics table alone and drops or misroutes the trigger — did not fire against a model already
capable of reading a well-structured report end to end.

## Adversarial review

An adversarial Opus reviewer, run independently of the controller's own scoring, confirmed the
CLEAN verdict and specifically tried to break it on the two shapes most likely to hide a disguised
failure:

- **b2's cross-wave decomposition** (criterion 1's one structural outlier) — reviewed and ruled
  deliberate and cascade-respecting, not a disguised under-count or a split of the trigger's
  liveness across waves; the trigger's full behavior is accounted for exactly once, and the
  Dimension-3 order into `prc_log_status_change` is preserved throughout.
- **A Wave-0 discovery task appearing in some plans** — reviewed and ruled a correct cutover
  prerequisite (verifying the external firing DML and confirming no other undocumented callers
  exist before migration begins), not a disguised indefinite defer of the trigger itself.

The reviewer also noted that even a minimal report-format note (e.g. "remember the Extraction
Metrics table excludes triggers by design, read the Component Manifest too") would be redundant as
a *skill* addition: that exact contract note already exists in the x-ray report's own Recommended
Next Steps section, and all 5 reps honored it without being told to by any planning skill.

## Gate outcome and consequence

Per `planner-rep-prompt-template.md` §2c, the RED gate fires if, across 5+ reps, the baseline
exhibits `OMITTED`/`MULTIPLE` trigger placement, `DEFERRED_NO_CALLER`/`DEAD` liveness, `DROPPED`
cascade sequencing, `ASSERTED` trigger claims, `SILENTLY_IGNORED`/`FABRICATED_USAGE_CLAIM` runtime
treatment, or `WRONG` `prc_log_status_change` placement, at a rate worth authoring guidance
against. Every one of those failure modes registered **zero** occurrences across all 5 reps.

**The gate does not fire. This is a stop-and-report**, per plan Task 3 Step 5 / template §2c, in
the same direction as the sibling fleetbill planner baseline and Task 1's xray baseline in this
directory.

**Consequence:** Component B (trigger-aware wave-planning guidance) is UNJUSTIFIED as specified —
no unaided-planner failure mode exists on this fixture for it to fix. Per the user's decision,
**Task 4 is DROPPED.** **Component A — the sproc-xray report-side change from Tasks 1–2 — is the
shipped deliverable of this plan.** No wave-planning discipline text, no trigger-liveness-routing
guardrail, and no shared-cascade-cluster rule is added to `sproc-migration-plan`, because none of
those failures occurred in 5 independent unaided runs against a report that already carries the
information a planner needs.

## Scope limit — do not overstate this arm

**This is a ceiling finding on this small fixture, not a general claim about trigger-aware
planning.** It demonstrates that, on a well-formed x-ray report that already documents a trigger's
Component Manifest row, Dimension-2 entry-point status, Dimension-3 cascade, and Dead/Orphan-Code
liveness rationale, a capable unaided planner reliably recovers and correctly sequences that
trigger — not that no planner could ever mishandle a trigger on a differently-shaped or
pathological report (a report where the trigger's cascade citations are missing, ambiguous, or
buried; a report with multiple interacting triggers; a much larger corpus where a two-object cascade
becomes one of dozens competing for attention). As with the sibling fleetbill planner baseline and
Task 1's xray baseline, this result is a ceiling finding on a deliberately small, 2-unit,
hand-countable fixture; it does not establish that trigger-aware wave-planning judgment holds at
scale or against a less complete report. Should a future, larger trigger-bearing corpus (or a report
produced by a version of `sproc-xray` that omits the Dimension-3 Cascade Map or the Dead/Orphan
Code trigger-liveness note) surface the failure modes this fixture was built to bait, Component B
would need to be reconsidered on that new evidence — this result closes it only as specified,
against this fixture, today.
