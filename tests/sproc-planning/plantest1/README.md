# plantest1 — ground truth (SCORER ONLY — never sent to a rep)

This fixture exists to be scored, so the answer key is recorded here. Every fact below was
produced by running a command against `FLEETBILL-SPROC-XRAY.md` and `app/`, not by reading them
casually. **This file is the answer key a migration-planning rep must independently compute — it
must never be part of what a rep sees.** See `../prepare-rep-fixture.sh`, which builds the
rep-facing copy (the report plus `app/`, this file excluded) both arms of the harness use.

## Inputs this ground truth is built from

- `FLEETBILL-SPROC-XRAY.md` — the real x-ray report produced by running the amended `sproc-xray`
  skill (v0.4.0) over `tests/sproc-metrics/xraytest1/sql/`. Its `GLOBAL_STATE` rows (Dimension 5)
  and its `### Extraction Metrics` table (Dimension 1) are the planner's legitimate input — citing
  them is not leakage.
- `app/` — a synthetic Java application tree, 6 files, that calls some of the 6 fleetbill routines
  by name (in varying casings) and not others.
- **No runtime evidence pack exists for this fixture.** No execution-statistics export (call
  frequency, row volumes) was supplied alongside the report or the app tree. A correct plan states
  this absence explicitly rather than inventing usage data — the x-ray report's own "Optional
  runtime evidence pack" note under Recommended Next Steps already says none was provided; a rep
  is expected to carry that forward, not contradict or silently drop it.

## Per-routine call-site classification (all 6 manifest objects)

| Object | App-called? | DB-internal-called? | Ground truth | Evidence |
|---|---|---|---|---|
| `prc_apply_rate_rules` | No | Yes — by `prc_settlement_sweep` | **DB-internal-only** | No occurrence anywhere in `app/`. X-ray report Dimension 2: `prc_settlement_sweep` → `prc_apply_rate_rules` (`05:33`) is the system's only static call edge. |
| `prc_settlement_sweep` | Yes — 2 call sites, 2 casings | No (it is itself the caller of `prc_apply_rate_rules`, not called by anything in-database) | **App-called** | `SettlementBatchJob.java:25` — `{call PRC_Settlement_Sweep(?, ?)}` (mixed case). `SettlementRetryRunner.java:30` — `{call prc_settlement_sweep(?, ?)}` (lowercase). Oracle identifiers are case-insensitive unless quoted — both call sites are the SAME object; a rep that treats them as two different or unmatched names is wrong. |
| `prc_purge_stale_holds` | Yes — 1 call site | No | **App-called** | `HousekeepingScheduler.java:23` — `{call prc_purge_stale_holds}` (lowercase, exact match to the x-ray report's object name). |
| `fn_trip_surcharge` | No | No | **Uncalled — flag for investigation** | No occurrence anywhere in `app/`. No occurrence anywhere in the x-ray report's Dimension 2 call graph either. This is the fixture's true dead-code candidate: no caller found in the database source AND no caller found in the application tree. A correct plan flags it as dead/needs-investigation rather than silently scheduling it for migration as though it were live. |
| `pkg_fleet_billing.load_driver_batch` | Yes — 1 call site | No | **App-called** | `DriverBatchLoader.java:23` — `{call PKG_FLEET_BILLING.LOAD_DRIVER_BATCH(?, ?, ?)}` (uppercase, package-qualified). |
| `pkg_fleet_billing.post_batch_totals` | No | No | **Uncalled — flag for investigation** | No occurrence anywhere in `app/`. **Short-name over-match hazard:** `BatchAuditReportService.java` contains the substring `post_batch_totals` three times (`POST_BATCH_TOTALS_ARCHIVE`, a field `postBatchTotalsRowCount`, a setter `setPostBatchTotalsRowCount`) — all of it is a *warehouse reporting table/field* used for T+1 reconciliation, not an invocation of the packaged procedure. There is no `{call ...}`, no `CallableStatement`, no JDBC/ORM invocation syntax anywhere in that file. A naive case-insensitive substring search over `app/` for `post_batch_totals` returns a false positive here; a rep that concludes "post_batch_totals is app-called" on the strength of this file alone is wrong — it must check for actual invocation syntax, not name proximity. |

**Summary:** 3 of 6 objects are app-called (`prc_settlement_sweep`, `prc_purge_stale_holds`,
`load_driver_batch`); 1 is DB-internal-called only (`prc_apply_rate_rules`); 2 are uncalled by
anything found in either artifact (`fn_trip_surcharge`, `post_batch_totals`) and must be triaged,
not silently migrated.

## Shared-state clusters (must not be split across migration waves)

Read directly from the x-ray report's Dimension 5 `GLOBAL_STATE` facts (G1–G5):

- **G1 — `g_run_total`** (package variable): written by **both** `load_driver_batch` and
  `post_batch_totals`. Report citations: declared `03:5`; written `03:19` (load), `03:46`/`03:49`
  (post); read `03:49`/`03:57`.
- **G3 — `tmp_settlement_stage`** (global temporary table): written by `prc_settlement_sweep`
  (`05:36`), read by `post_batch_totals` (`03:42`). This is the entire handoff between the two —
  no call edge connects them.

Because `post_batch_totals` appears in BOTH couplings (it shares `g_run_total` with
`load_driver_batch`, and it consumes `tmp_settlement_stage` from `prc_settlement_sweep`), the three
routines form ONE transitively-connected cluster:

```
{ load_driver_batch, post_batch_totals, prc_settlement_sweep }
```

**This cluster must land in a single migration wave.** Splitting it across waves — e.g., extracting
`prc_settlement_sweep` in an early wave and `post_batch_totals` in a later one because
`post_batch_totals` "looks safe" (branch-free, zero cursor-loop-adjacent complexity per the
Extraction Metrics table) — silently breaks the staging handoff and the shared package-variable
total. A rep that scores `post_batch_totals` as low-complexity and schedules it independently,
without checking Dimension 5, will split this cluster.

The other two package variables (`g_batch_id`, `g_last_driver_id`; G2 in the report) each have
exactly one writer and are not shared-state couplings — they do not force a cluster. `SYS_CONTEXT`
(G4) and `seq_settlement_batch` (G5) are read-only/single-consumer ambient state, not migration-wave
couplings either.

## What a correct plan does with `prc_apply_rate_rules`

It is DB-internal-called only — no app caller exists. It must still be migrated (it is live, just
not app-facing), and because `prc_settlement_sweep` calls it (`05:33`) and `prc_settlement_sweep`
is itself in the 3-object shared-state cluster above, a plan that puts `prc_apply_rate_rules` in a
materially different wave from that cluster is worth flagging as a coordination risk, though it is
not part of the shared-*state* cluster itself (it shares no global-state resource with any other
routine per the x-ray report — its only coupling is the call edge).

## No runtime evidence pack

Re-stated for scoring criterion 5 (Task 3 Step 2 rubric): neither the x-ray report nor this fixture
supplies call-frequency, row-volume, or production-invocation data. A plan that asserts something
like "`prc_purge_stale_holds` runs rarely" or "`fn_trip_surcharge` is low-traffic" without citing a
source for that claim is inventing usage data. The correct behavior is to state the absence
explicitly (mirroring the x-ray report's own Recommended Next Steps section) and, if sequencing by
usage matters, recommend obtaining the pack rather than guessing.
