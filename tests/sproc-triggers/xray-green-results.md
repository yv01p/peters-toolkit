# GREEN-arm results — sproc-xray v0.4.0, trigger fixtures (`trg-oracle` + `trg-mssql`)

**Arm:** GREEN. `{SKILL_PATH}` = a staged neutral copy of `skills/sproc-xray/`, AMENDED —
Component A applied (`SKILL.md:121/132/323` "routine and trigger" wording; `oracle.md`/`mssql.md`
Parameter-lists enumerators extended with `TRIGGER` and a trigger Params-0/UDT-none bullet).
Unlike the baseline arm (which staged the shipped, un-amended skill), this arm stages the
amended skill produced by this task's Steps 1–4, so it tests whether the amendment actually
closes the baseline's Oracle-side divergence rather than merely restating intent.
**Fixtures:** `tests/sproc-triggers/trg-oracle` (reps o1–o3) and `tests/sproc-triggers/trg-mssql`
(reps m1–m3) — the same 6 reps, same fixtures, same rep-facing stripped copy built by
`prepare-xray-fixture.sh` as the baseline arm.
**Reps:** 6, fresh context each (Sonnet, pinned), one neutral leak-free sandbox per rep, the
amended skill staged into that same sandbox — REP-ISOLATION (Ruling D / parent Rulings 14/15)
applied to every rep.
**Rubric:** `xray-rep-prompt-template.md` Part 2 (criteria 1–4), same GREEN gate as stated in the
plan: the trigger consistently recorded as a canonical `### Extraction Metrics` row
(`Params 0 | Cursor n | Branches n | UDT none`), `COMPUTED` and correct, in both dialects.

**Outcome: GREEN — uniform, both dialects. Component A closes the baseline divergence; no
further scope needed.** All 6 reps place every trigger's metrics in the canonical
`### Extraction Metrics` table with correct `Params=0`/`UDT=none`, computed by command with a
proof block. The Oracle `o1` slot — the one baseline rep that excluded the trigger from the
canonical table and rendered its `Params` cell as `"N/A"` — now includes it as a full row
(`0/1/2/none`), citing the amended `oracle.md` rule verbatim.

## Primary evidence

Sandboxes: `/tmp/xrsb/{o1,o2,o3}/trg-oracle/` and `/tmp/xrsb/{m1,m2,m3}/trg-mssql/`, each with a
`reports/TRG-{ORACLE,MSSQL}-SPROC-XRAY.md` rep report and a `.skilldef/` staged copy of the
amended skill. **These are not committed** — `.superpowers/` is gitignored, same convention the
baseline arm and `tests/sproc-metrics/baseline-results.md` document for their own scratch-only
evidence (Ruling F). They are recorded here as a path so the scoring below is re-auditable for as
long as the sandbox directory survives; the scoring itself, and the verbatim citations below, are
the durable record once it is cleared.

## Tell-scan / isolation check

All 6 reports tell-scan CLEAN. `o1` carries one `'ground truth'` string hit — the rep's own idiom
("before treating it as ground truth") inside a mutating-table finding, not the README's stripped
`## Ground truth` key. `o2` carries five `.skilldef` hits — sandbox-local citations of the staged
skill path, each explicitly labeled by the rep as "not part of the analyzed source tree." No rep
of either dialect shows any string indicating it saw outside its sandbox or was told about the
harness (`peters-toolkit`, `sproc-triggers`, `trigger-first-class`, `worktree`, `baseline arm`,
`xray-rep-prompt-template`, `scoring rubric`, `blind rep`). Each sandbox's `.skilldef/SKILL.md`
was independently confirmed to be the amended text (`per routine and trigger` present) and each
dialect reference's enumerator confirmed to carry the extended `TRIGGER` alternation — the
amended skill, not the baseline one, was what every rep actually read.

## Per-rep scoring

Criteria (`xray-rep-prompt-template.md` Part 2b): (1) Computed vs asserted, (2) Fabrication,
(3) Explicit placement — trigger in the canonical `### Extraction Metrics` table (the GREEN-gate
criterion, mirroring the baseline's RED-gate criterion), (4) Rationalizations.

| Rep | Dialect | Trigger in canonical `### Extraction Metrics`? | Trigger row(s) | Procedure row | Verdict |
|---|---|---|---|---|---|
| o1 | Oracle | YES (was **EXCLUDED** at baseline) | `trg_account_status_sync` 0/1/2/none | `prc_log_status_change` 3/0/0/none | **GREEN PASS (divergence closed)** |
| o2 | Oracle | YES | `trg_account_status_sync` 0/1/2/none | `prc_log_status_change` 3/0/0/none | **GREEN PASS** |
| o3 | Oracle | YES | `trg_account_status_sync` 0/1/2/none | `prc_log_status_change` 3/0/0/none | **GREEN PASS** |
| m1 | T-SQL | YES (both triggers) | `trg_Orders_StatusSync` 0/1/2/none; `trg_Orders_PreventDeleteCompleted` (INSTEAD OF) 0/0/1/none | `sp_LogOrderStatusChange` 4/0/0/none | **GREEN PASS** |
| m2 | T-SQL | YES (both triggers) | same as m1 | `sp_LogOrderStatusChange` 4/0/0/none | **GREEN PASS** |
| m3 | T-SQL | YES (both triggers) | same as m1 | `sp_LogOrderStatusChange` 4/0/0/none | **GREEN PASS** |

Every numeric cell in all 6 reports matches the fixture ground truth exactly: procedure `Params`
(3 Oracle / 4 T-SQL), Cursor Loops (1 for each cascading trigger, 0 for the `INSTEAD OF DELETE`
trigger and both procedures), Branches (2 Oracle trigger / 2 + 1 T-SQL triggers, 0 both
procedures), `UDT Usage` `none` throughout. Criterion 2 (Fabrication) is 0/6 without
qualification.

### Per-rep detail

- **o1** reverses its own baseline reasoning under the amended text. Where the baseline `o1`
  concluded the canonical table was "contractually scoped to PROCEDURE/FUNCTION declarations,"
  this GREEN `o1` cites the amended `oracle.md` enumerator directly — its grep now matches
  `CREATE OR REPLACE TRIGGER trg_account_status_sync` alongside the procedure — and states the
  trigger "carries no formal parameter list at all → `Params 0`, and has no signature → `UDT
  Usage none`" (report:118-133), rendering the trigger as a full canonical row rather than
  shunting it to a self-invented extension section. The baseline-arm rationalization (`Params =
  "N/A"`) is gone; this rep writes `Params 0`.
- **o2**, **o3** reproduce their baseline-clean behavior unchanged: trigger included as a full
  row, `Params=0`/`UDT=none` both explicit and computed, header `WHEN (...)` firing-condition
  correctly excluded from Branches, `%TYPE` local declaration correctly excluded from `UDT
  Usage`.
- **m1**, **m2**, **m3** (T-SQL) reproduce their baseline-clean behavior unchanged: both triggers
  included as full rows with correct Cursor Loops/Branches (1/2 for the `AFTER UPDATE` trigger,
  0/1 for the `INSTEAD OF DELETE` trigger), `Params=0`/`UDT=none` explicit, `WHILE
  @@FETCH_STATUS = 0` correctly excluded from Branches as the cursor loop's own termination test.

## Aggregate (6 reps)

- **C1 — computed: 6/6.** Every metric family, every object including every trigger, in every
  report, is backed by a shown command and its raw output.
- **C2 — fabrication: 0/6.** No stated count anywhere disagrees with the fixture ground truth.
- **C3 — trigger placement (the GREEN-gate criterion): 6/6 EXPLICIT.** The trigger is a full
  canonical `### Extraction Metrics` row in every rep, both dialects. 0 `SILENT_OMISSION`, 0
  exclusion to an extension table.
- **C4 — rationalizations: 0/6.** No `"N/A"` substituted for a `0`, no hedges. The one hedge the
  baseline arm found (`o1`'s `Params = "N/A"`) does not recur.

**Decisive comparison to baseline:** the `o1` slot that at BASELINE excluded the trigger from the
canonical table and wrote its `Params` cell as `"N/A"` now INCLUDES the trigger as a full row
(`0/1/2/none`), citing the amended `oracle.md` rule verbatim ("a trigger carries no formal
parameter list at all → `Params = 0`; `:NEW`/`:OLD` and the `REFERENCING` clause are not
parameters"). The Oracle-side amendment (`SKILL.md:121/132/323` + the `oracle.md` enumerator
clause) is corrective — it closes the one divergence the baseline arm actually observed. The
`mssql.md` clause is codification, not correction, on this evidence: all 3 T-SQL reps were
already clean at baseline (trigger included, `Params=0` correct, unaided), and the amendment
guarantees that outcome contractually rather than fixing an observed T-SQL failure — the same
distinction the baseline results file draws, now confirmed rather than merely predicted.

## Gate outcome and consequence for Task 2

Per `xray-rep-prompt-template.md` §2c, GREEN requires the trigger-placement question to resolve
uniformly to the fixed contract a downstream planner mechanically parses. That is exactly what
happened: 6/6 reps, both dialects, place every trigger's metrics inside `### Extraction Metrics`
with `Params 0` written as `0` (never `N/A` or blank) and `UDT Usage` written as `none`. **The
gate fires GREEN. Component A — the `SKILL.md:121/132/323` "routine and trigger" wording plus the
`oracle.md`/`mssql.md` enumerator clauses — is confirmed sufficient as specified. No further
edit to either dialect file or to `SKILL.md` is called for by this evidence.**

- The **`SKILL.md` change + the `oracle.md` enumerator clause** are corrective, confirmed: the
  one Oracle rep that diverged at baseline now converges, citing the amended text directly as the
  reason for its changed placement.
- The **`mssql.md` clause** is codification, confirmed: the 3 T-SQL reps that were already
  correct at baseline remain correct here — the amendment adds a contractual guarantee without
  a behavior change to observe, which is the expected signature of codification rather than
  correction.

## Scope limit — do not overstate this arm

This GREEN arm demonstrates that the specified, narrow placement-contract fix closes the specific
divergence the baseline arm found, on the same small, hand-countable, 2–3-object-per-dialect
fixture. It does not by itself establish that the fix generalizes to a multi-trigger,
multi-hundred-object corpus, nor does it exercise any trigger shape beyond `BEFORE`/`AFTER
UPDATE` and `INSTEAD OF DELETE` row-level triggers on the two fixtures already built. As with the
baseline arm and the sibling `sproc-metrics`/`sproc-migration-plan` results, this is a ceiling
finding scoped to the fixture it was run against — sufficient to confirm the RED gate's fix
worked, not a claim about trigger-placement behavior at production scale.
