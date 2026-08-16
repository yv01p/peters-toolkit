# trgplan1 — ground truth (SCORER ONLY — never sent to a rep)

This fixture exists to be scored, so the answer key is recorded here. Every fact below cites
`TRIGGER-SPROC-XRAY-baseline.md` and/or the files under `app/`, not casual re-reading. **This file
is the answer key a migration-planning rep must independently compute — it must never be part of
what a rep sees.** See `../prepare-planner-fixture.sh`, which builds the rep-facing copy (the
report plus `app/`, this file excluded) both arms of the harness use.

## Inputs this ground truth is built from

- `TRIGGER-SPROC-XRAY-baseline.md` — a committed `sproc-xray` report (the pre-Component-A baseline
  — see the trigger-first-class plan's Task 1) for a small Oracle account-status system: 3 tables
  (`accounts`, `account_holds`, `account_status_log`), 1 sequence (`seq_status_log`), 1 standalone
  procedure (`prc_log_status_change`), 1 trigger (`trg_account_status_sync`) — 6 objects total (the
  report's Component Manifest grand total, line ~133). **This report's shape is itself part of the
  fixture:** its `### Extraction Metrics` table (line ~182) carries exactly ONE row —
  `prc_log_status_change` — because that table is scoped to routines (procedures/functions) only;
  the report says so explicitly at line ~152: *"`trg_account_status_sync` is a trigger, not a
  procedure or a function — it does not appear in this table."* The trigger is not absent from the
  report — it is present in the Component Manifest (line ~116) and, in full cascade detail, in the
  Dimension-3 Trigger Cascade Map (lines ~302–312) — it is only absent from the Extraction Metrics
  table specifically.
- `app/` — a synthetic Java application tree, 3 files, that calls `prc_log_status_change` directly
  from two call sites and never references the trigger.
- **No runtime evidence pack exists for this fixture.** The report's own "Recommended Next Steps"
  section (line ~456) states directly that no execution-statistics export (Oracle AWR / `v$sql`)
  was supplied, and that static source cannot show call frequency or row volumes. A correct plan
  states this absence explicitly rather than inventing usage data.

## The two migration logic units

Tables (`accounts`, `account_holds`, `account_status_log`) and the sequence (`seq_status_log`) are
**resources**, not migration logic units, per the report's own Component Manifest (they carry no
extraction-metrics row and no branch/cursor logic of their own). There are exactly two logic units
in this corpus: the standalone procedure and the trigger.

### `prc_log_status_change` — app-called AND DB-internal-called → live, normal migration unit

| Evidence | Citation |
|---|---|
| App-called, 2 call sites | `app/src/main/java/com/bankcore/accounts/AccountStatusService.java` — `{call prc_log_status_change(?, ?, ?)}` (support-desk audit-trail backfill for a manually corrected account); `app/src/main/java/com/bankcore/accounts/batch/StatusChangeBackfillJob.java` — `{call prc_log_status_change(?, ?, ?)}` (nightly bulk-loader status-log backfill) |
| DB-internal-called, 1 caller | The trigger — report Dimension 3, `03-trg_account_status_sync.sql:38`, cited in the report's Component Manifest ("Called by trigger at `03:38`", line ~115) and Dimension 2's Liveness Claims ("`prc_log_status_change` HAS a caller — cited at `03-trg_account_status_sync.sql:38`", line ~232) |
| Extraction Metrics row | `prc_log_status_change\|3\|0\|0\|none\|02-prc_log_status_change.sql` (report line ~149) — 3 params, 0 cursor loops, 0 branches, no UDT usage |

This unit is unambiguous: it has both an app caller and a DB-internal caller, and it is the corpus's
one Extraction Metrics row. A correct plan places it as a normal, live migration unit.

### `trg_account_status_sync` — NOT app-called, but a LIVE DB-internal entry point

| Fact | Citation |
|---|---|
| **No occurrence anywhere in `app/`.** No file in the app tree names the trigger, calls it, or contains the DML that fires it. | Verified: `grep -rn "trg_account_status_sync\|UPDATE accounts" app/` returns nothing. |
| **It is nonetheless live.** The report's Dead/Orphan Code section states directly: *"`trg_account_status_sync` is a trigger — always an entry point (see Dimension 2). Its firing statement (`UPDATE accounts SET status = ...`) is external to this corpus (application code or another routine not provided here) — this is a coverage-honesty note ..., not evidence of dead code."* | Report line ~204, restated at Dimension 2 line ~226 and ~232, and Dimension 2's own Extraction Sequencing note (line ~243). |
| **It is the entry point of the only call/cascade edge in the system.** `UPDATE accounts SET status = ...` (external) → `TRIGGER trg_account_status_sync` → `CALL prc_log_status_change` → `INSERT INTO account_status_log`. | Report Dimension 2 Dependency Graph (lines ~219–224) and Dimension 3 Trigger Cascade Map (lines ~304–312). |

**This is the fixture's central trap.** The trigger has no app caller — by construction, the app
tree in this fixture never references it, mirroring the real report's own stated gap ("No
application-tier caller of the triggering `UPDATE accounts SET status = ...` statement is included
in this source", Coverage Declaration, line ~21). A plan that classifies liveness purely by
"did I find an app call site for this" will misroute `trg_account_status_sync` to
`DEFERRED_NO_CALLER` / `DEAD` / "no caller found, needs investigation" — this is **wrong**. A
trigger's liveness comes from the trigger definition itself plus its firing DML (which the report
states exists externally, e.g. some other application flow that does `UPDATE accounts SET
status = ...`) — never from an app-caller grep. The correct classification is
**`LIVE_ENTRY_POINT`**, and the correct partition placement is a single migration wave/class, not
an "omit" or "defer indefinitely for lack of evidence" bucket.

**Summary:** both of the corpus's 2 logic units are live. `prc_log_status_change` is app-called and
DB-internal-called; `trg_account_status_sync` is DB-internal-only but is itself the system's one
entry point (a trigger, always live per the report's own convention, Dimension 2 line ~232).
Neither unit is dead, orphaned, or "needs investigation" in this fixture — that distinguishes this
fixture from the fleetbill `plantest1` fixture, which has two genuinely uncalled objects. This
fixture's trap is not "misses a truly dead routine" — it is "misclassifies a genuinely live routine
as dead/deferred because it has no app caller," and/or "drops it from the unit count entirely
because it isn't in the Extraction Metrics table."

## The partition-under-count trap, stated explicitly

The report's `### Extraction Metrics` table (line ~182) lists exactly one row:
`prc_log_status_change`. **A plan that builds its migration-unit set by reading only that table**
— treating it as "the list of routines to migrate" — **omits the trigger entirely**, because the
report itself explains (line ~152) that the table is scoped to procedures/functions and a trigger
does not appear there by design. The trigger is still fully present in this same report — in the
Component Manifest (a `Type: Trigger` row, line ~116, with LOC, notable flags, and its caller
relationship) and in the Dimension-3 Trigger Cascade Map (lines ~302–312), which gives its complete
cascade with file:line citations. **A correct plan must draw its migration-unit set from the
Component Manifest (or equivalently, from the union of Extraction Metrics + Manifest rows typed
Trigger/Procedure/Function), not from the Extraction Metrics table alone.** A plan that ends up with
only one migration unit (`prc_log_status_change`) for this corpus has under-counted the partition by
exactly one — the trigger.

## Dimension-3 cascade cluster — `trg_account_status_sync` ↔ `prc_log_status_change`

The report's Dimension-3 Trigger Cascade Map (lines ~304–312) and Dimension-2 Dependency Graph
(lines ~219–224) both establish a single cascade binding the two units:

```
UPDATE accounts SET status = ...   (external, not in this corpus)
  -> TRIGGER trg_account_status_sync (03-trg_account_status_sync.sql:9)
     -> ... (account_holds reads/updates, self-referential accounts UPDATE — Dimension 3 detail)
     -> CALL prc_log_status_change (03-trg_account_status_sync.sql:38)
        -> INSERT INTO account_status_log (02-prc_log_status_change.sql:10)
```

This is the same edge the report's Dimension 2 records in `calls.tsv`
(`trg_account_status_sync|prc_log_status_change|03-trg_account_status_sync.sql:38`) and the only
call/cascade edge in the entire corpus (report line ~241: "One edge, one caller, one callee.").
The report's own Extraction Sequencing (line ~243) states the order explicitly: *"(1)
`prc_log_status_change` — leaf, zero outgoing calls, extract first; (2) `trg_account_status_sync` —
the trigger, always last (it is the entry point that invokes the chain)."*

**A correct plan recognizes this binding** — the two units are not independent, unrelated pieces of
work; they are a two-node cascade with a defined leaf-then-entry-point order — **and sequences them
accordingly, per the report's own stated order** (`prc_log_status_change` before
`trg_account_status_sync`, or at minimum in the same wave with that internal order noted). It does
**not** bind the cluster via an app call-graph edge — there is none for the trigger; the app tree
in this fixture, by design (see above), contains no reference to
`trg_account_status_sync` at all. The binding is visible only through the report's own call/cascade
graph (Dimensions 2 and 3), exactly as the report presents it — not through anything discoverable
in `app/`. A plan that treats the trigger as an isolated, unrelated unit with no relationship to
`prc_log_status_change` has dropped this cascade binding.

## No runtime evidence pack

Re-stated for scoring (mirrors `plantest1/README.md`'s equivalent note): neither the x-ray report
nor this fixture supplies call-frequency, row-volume, or production-invocation data for either
logic unit. The report's own Recommended Next Steps section (line ~456) states this directly: *"No
such pack was provided for this analysis — stated here explicitly, not implied."* A plan that
asserts something like "the trigger fires rarely" or "`prc_log_status_change` is a hot path" without
citing a source is inventing usage data. The correct behavior is to state the absence explicitly and,
if sequencing by usage matters, recommend obtaining the pack rather than guessing.
