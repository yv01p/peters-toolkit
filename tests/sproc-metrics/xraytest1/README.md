# fleetbill

Settlement schema for a small vehicle-fleet operator. Trips accumulate against
vehicles; a nightly sweep prices every unsettled trip for one region, stages the
priced rows, and a second routine totals the staging area and stamps the batch
header. Pricing policy (driver status, zone multiplier, tier adjustment) lives
entirely in the database. There are no triggers and no views — the whole system
is seven tables, one staging table, and six routines.

Layout:

- `sql/01-schema.sql` — tables, the global temporary staging table, the batch sequence, the charge-code collection type
- `sql/02-pkg_fleet_billing.pks` — package spec (ref cursor type, two procedure signatures)
- `sql/03-pkg_fleet_billing.pkb` — package body, holds the session-scoped package state
- `sql/04-prc_apply_rate_rules.sql` — pricing policy for one driver/class/zone (decision logic only)
- `sql/05-prc_settlement_sweep.sql` — the nightly sweep (vehicles → trips), stages priced rows
- `sql/06-prc_purge_stale_holds.sql` — housekeeping, releases expired driver holds
- `sql/07-fn_trip_surcharge.sql` — per-zone surcharge for one trip

## Ground truth

This fixture exists to be measured, so the measurements are recorded here. Every
number below was produced by running a command against the files in `sql/`, not
by reading them.

**Counting bases.** A *parameter* is one formal parameter in the routine's own
signature (the package spec and body declare the same signature once each; that
is one parameter set, not two). A *cursor loop* is a `FOR … IN <cursor> LOOP`
over an explicitly declared cursor; a numeric `FOR i IN 1 .. n LOOP` is not one,
and `OPEN <ref cursor> FOR` is not a loop at all. A *branch point* is an `IF`
statement, an `ELSIF` clause, or a `CASE` `WHEN` arm; the `ELSE` arm is not a
branch point, and an `EXCEPTION WHEN` handler is not a branch point.

### Per-object metrics

| Object | Kind | Defined at | Params | Cursor loops | Branch points | Branch breakdown |
|---|---|---|---|---|---|---|
| `prc_apply_rate_rules` | standalone procedure | `04-prc_apply_rate_rules.sql:1` | 4 | 0 | 11 | IF 4 + ELSIF 2 + CASE arms 5 |
| `prc_settlement_sweep` | standalone procedure | `05-prc_settlement_sweep.sql:1` | 2 | 2 | 1 | IF 1 |
| `prc_purge_stale_holds` | standalone procedure | `06-prc_purge_stale_holds.sql:1` | 0 | 0 | 0 | none |
| `fn_trip_surcharge` | standalone function | `07-fn_trip_surcharge.sql:1` | 2 | 0 | 2 | CASE arms 2 |
| `pkg_fleet_billing.load_driver_batch` | packaged procedure | `02-…pks:7`, `03-…pkb:9` | 3 | 0 | 0 | none |
| `pkg_fleet_billing.post_batch_totals` | packaged procedure | `02-…pks:14`, `03-…pkb:37` | 1 | 1 | 0 | none |
| **Totals** | 6 routines | — | **12** | **3** | **14** | — |

Points the table is built to make explicit:

- **Zero-parameter case.** `prc_purge_stale_holds` takes no parameters at all —
  its banner is `CREATE OR REPLACE PROCEDURE prc_purge_stale_holds IS`, with no
  parameter list. Its parameter count is 0, not blank and not omitted.
- **Branch-free case.** `prc_purge_stale_holds` also has zero branch points: a
  `DELETE`, an `UPDATE` and a `COMMIT`, no conditional of any kind. The two
  packaged procedures are likewise branch-free.
- **Densest case.** `prc_apply_rate_rules` carries 11 of the system's 14 branch
  points and zero loops: `IF` at lines 30, 31, 57, 69; `ELSIF` at 37, 40;
  `CASE` `WHEN` arms at 47, 49, 51 (statement `CASE`, closed at 55) and 64, 65
  (expression `CASE`).
- **Nested cursor loop.** `prc_settlement_sweep` declares `c_vehicles`
  (`05:7`) and `c_trips` (`05:12`) and runs the second inside the first:
  outer `FOR v IN c_vehicles(...)` at `05:27`, inner `FOR t IN c_trips(...)` at
  `05:31`, closing `END LOOP` at `05:40` and `05:42`. Nesting depth 2. It is the
  only nested loop in the system.
- **Loops that are not cursor loops.** `load_driver_batch` runs a numeric
  `FOR i IN 1 .. p_charge_codes.COUNT LOOP` at `03:21` and opens a ref cursor
  with `OPEN p_charges FOR` at `03:30`. Neither is a cursor loop; its cursor-loop
  count is 0. The system's third and last cursor loop is `FOR r IN c_staged(...)`
  at `03:48`, over the cursor declared at `03:40`.
- **Exception handler is not a branch.** `prc_settlement_sweep` has
  `EXCEPTION WHEN OTHERS THEN NULL;` at `05:45-47`. Under the stated basis it is
  not counted; its branch count stays 1. (It is a genuine error-swallow finding
  on its own account.)

### User-defined type usage in signatures

All three UDT forms appear in one signature — `pkg_fleet_billing.load_driver_batch`
— and nowhere else in the system:

| Form | Parameter | Type | Spec | Body | Type defined at |
|---|---|---|---|---|---|
| `%ROWTYPE` | `p_driver IN` | `drivers%ROWTYPE` | `02-…pks:8` | `03-…pkb:10` | anchored on `drivers` (`01-schema.sql:7`) |
| VARRAY | `p_charge_codes IN` | `t_charge_code_list` | `02-…pks:9` | `03-…pkb:11` | `01-schema.sql:77` |
| `REF CURSOR` | `p_charges OUT` | `t_charge_cur` | `02-…pks:10` | `03-…pkb:12` | `02-…pks:4` |

No other routine has a UDT parameter. Scalar `%TYPE` anchors do appear, but only
on **local variables**, never on a parameter: `04:9`, `04:10`, `04:11`, `04:12`
and `07:6`. `%TYPE` on a local is not a UDT parameter and must not be counted as
one.

### Global and shared state

| Kind | Object | Written by | Read by | Citations |
|---|---|---|---|---|
| Package variable | `g_run_total` | **both** `load_driver_batch` and `post_batch_totals` | `post_batch_totals` | declared `03:5`; written `03:19` (load), `03:46`, `03:49` (post); read `03:49`, `03:57` |
| Package variable | `g_batch_id` | `post_batch_totals` only | — | declared `03:6`; written `03:45` |
| Package variable | `g_last_driver_id` | `load_driver_batch` only | — | declared `03:7`; written `03:18` |
| Global temporary table | `tmp_settlement_stage` | `prc_settlement_sweep` (INSERT, `05:36`) | `pkg_fleet_billing.post_batch_totals` (SELECT via `c_staged`, `03:42`) | defined `01-schema.sql:68`, `ON COMMIT PRESERVE ROWS` |
| Session context | `SYS_CONTEXT` | — | `prc_apply_rate_rules` ×2, `pkg_fleet_billing.load_driver_batch` ×1 | `04:17` (`fleet_ctx`/`region_code`), `04:58` (`userenv`/`client_identifier`), `03:16` (`fleet_ctx`/`region_code`) |
| Sequence | `seq_settlement_batch` | `prc_settlement_sweep` (`NEXTVAL`, `05:22`) | — | defined `01-schema.sql:75` |

Points the table is built to make explicit:

- The **two procedures sharing a package variable** are `load_driver_batch` and
  `post_batch_totals`, sharing `g_run_total`. The other two package variables are
  each written by exactly one procedure.
- The **two procedures sharing the global temporary table** are
  `prc_settlement_sweep` (writer) and `pkg_fleet_billing.post_batch_totals`
  (reader). The staging table is the entire handoff between them — there is no
  call edge from one to the other.
- **`SYS_CONTEXT` appears 3 times across 2 objects.** Occurrences and objects are
  different numbers; both are stated so either basis can be checked.
- **Exactly one procedure consumes the sequence:** `prc_settlement_sweep`, at
  `05:22`. No other routine references `seq_settlement_batch`.

### Object inventory

7 permanent tables (`drivers`, `vehicles`, `trips`, `rate_rules`, `charges`,
`settlement_batches`, `driver_holds`), 1 global temporary table
(`tmp_settlement_stage`), 1 sequence, 1 VARRAY type, 1 package (spec + body,
2 procedures), 3 standalone procedures, 1 standalone function. Zero triggers,
zero views, zero test scripts. 314 lines across 7 files.

The only call edge in the system is `prc_settlement_sweep` →
`prc_apply_rate_rules` at `05:33`. `fn_trip_surcharge` and both packaged
procedures have no caller anywhere in the source.
