# FLEETBILL — Sproc X-Ray Report

Source analyzed: local directory `tests/sproc-metrics/xraytest1/sql/` (7 files, PL/SQL). Working
directory for this run: scratch analysis directory; scratch files (`metrics.tsv`, `calls.tsv`,
`crud.tsv`, `findings.tsv`) were materialized before any table in this report was written, per the
skill's scratch-file-first discipline.

---

## Executive Summary — Critical Red Flags

Ranked, cited, severity-tagged concrete hazards. NOT a score, NOT a verdict.

- **[CRITICAL]** `prc_settlement_sweep` has a blanket exception swallow —
  `EXCEPTION WHEN OTHERS THEN NULL;` (`05-prc_settlement_sweep.sql:45-47`) — that wraps the entire
  nested sweep (`05:27-42`), including its call to `prc_apply_rate_rules` (`05:33`), whose own
  `SELECT ... INTO` (`04-prc_apply_rate_rules.sql:19-22`) raises `NO_DATA_FOUND` if a vehicle's
  `driver_id` has no matching row in `drivers`. Any such error is silently discarded — the batch
  header row already inserted (`05:24-25`) is left orphaned, with zero, some, or all trips staged,
  and the caller sees a normal return.
- **[CRITICAL]** The same swallow interacts with `prc_settlement_sweep`'s own `OUT` parameter:
  `p_out_batch_id` (`05-prc_settlement_sweep.sql:1-4`) is not assigned until line `44`, which sits
  **after** the loop the exception handler wraps and **before** the `EXCEPTION` block starts at
  line `45`. Any exception raised inside the loop skips line 44 entirely, so `p_out_batch_id` is
  never assigned. Combined with PL/SQL's copy-out-on-normal-return semantics for `OUT` parameters
  (no `NOCOPY` is declared on any `OUT`/`IN OUT` parameter in this source — see Dimension 5), the
  caller receives a normal return with an unassigned `p_out_batch_id` and no error — there is no
  way, from the caller's side, to distinguish "batch 1000 fully staged" from "nothing staged, id
  unknown."
- **[HIGH]** Package variable `g_run_total` (declared `03-pkg_fleet_billing.pkb:5`) is written by
  **both** `load_driver_batch` (`03:19`) and `post_batch_totals` (`03:46`, `03:49`), and read by
  `post_batch_totals` (`03:49`, `03:57`). This state survives for the life of the database session
  — under a connection pool, a leftover value from one logical request can leak into the next
  request that reuses the same pooled connection. There is no call edge between the two routines;
  the coupling is invisible to the dependency graph in Dimension 2.
- **[HIGH]** Global temporary table `tmp_settlement_stage` (defined `01-schema.sql:68`,
  `ON COMMIT PRESERVE ROWS`) is the entire handoff channel between `prc_settlement_sweep` (writer,
  `INSERT` at `05:36`) and `pkg_fleet_billing.post_batch_totals` (reader, `SELECT` via cursor
  `c_staged` at `03:42`). No call edge connects these two routines — the call graph in Dimension 2
  shows zero static relationship between them, yet they must run in the same extraction wave.
- **[MEDIUM]** Resource `trips` is touched by 3 distinct objects with no single owner:
  `prc_settlement_sweep` (read, `05:12-16`), `pkg_fleet_billing.post_batch_totals` (update,
  `03:51-53`), and `fn_trip_surcharge` (read, `07:8`) — see the Resource Touch Tally in
  Dimension 3. Extraction must decide which application service owns `trips` writes.
- **[MEDIUM]** `SYS_CONTEXT` ambient session state is read by 2 distinct objects across 3
  occurrences — `prc_apply_rate_rules` (`04:17`, `04:58`) and `load_driver_batch` (`03:16`) — and
  its value (`'fleet_ctx'/'region_code'`, `'userenv'/'client_identifier'`) is set by something
  outside these files. Extraction must locate and reproduce whatever sets this context.
- **[MEDIUM]** Pricing policy is hardcoded as procedural literals rather than data: zone
  multipliers (`04:48,50,52,54`), hold/pending tier adjustments (`04:35,41`), surcharge thresholds
  (`04:64-65`), the 90-day stale-hold window (`06:6`), and per-zone surcharge rates
  (`07:11-12`). None of these are parameterized — see Dimension 5, category `HARDCODED_VALUE`.
- **[LOW]** 5 of the system's 6 routines — `prc_settlement_sweep`, `prc_purge_stale_holds`,
  `fn_trip_surcharge`, `load_driver_batch`, `post_batch_totals` — have **no caller found anywhere
  in the analyzed source**. Only `prc_apply_rate_rules` has a static caller
  (`prc_settlement_sweep` at `05:33`). This is expected for likely job-scheduled or
  application-invoked entry points, but it is unverifiable from source alone — see Dimension 1
  Dead/Orphan Code and Dimension 2 Liveness Claims.

---

## Coverage Declaration

- **Objects provided:** 17 objects across 7 files (7 tables, 1 global temporary table, 1 sequence,
  1 user-defined type, 1 package container, 2 packaged procedures, 3 standalone procedures, 1
  standalone function) — provided means DEFINED in the source.
- **Objects referenced but missing:** 0 (none)
- **Estimated coverage:** 100% of referenced objects analyzed (17 of 17 — see Coverage Honesty
  Check in Dimension 1)
- **Reduced-confidence dimensions:** None — no dynamic SQL (`EXECUTE IMMEDIATE`, `DBMS_SQL`) was
  detected in the analyzed source (see Dimension 2); Dimension 2's dynamic-SQL confidence flagging
  is unexercised in this analysis.
- **Key gaps:** No full DDL export with `CHECK` constraints, indexes, or grants was provided —
  only the `CREATE TABLE` bodies shown in `01-schema.sql`. No trigger, view, or job-scheduler
  definitions exist in this source (confirmed zero via Component Manifest, not merely undocumented
  — see Context Intake). No runtime execution-statistics export (AWR / `v$sql`) was supplied
  alongside this report — see Recommended Next Steps.

---

## 1. Inventory & Completeness

### Context Intake

**Encoding and line-ending detection.** `file` reports all 7 source files as `ASCII text`. A
per-file `grep -c $'\r'` search for carriage-return bytes returned `0` for every file — no CRLF
line endings, no mixed encodings, no non-English comments encountered.

```
$ file sql/*
01-schema.sql:                ASCII text
02-pkg_fleet_billing.pks:     ASCII text
03-pkg_fleet_billing.pkb:     ASCII text
04-prc_apply_rate_rules.sql:  ASCII text
05-prc_settlement_sweep.sql:  ASCII text
06-prc_purge_stale_holds.sql: ASCII text
07-fn_trip_surcharge.sql:     ASCII text
```

**Documentation check.** The project `README.md` was read during intake. Its introductory
paragraph (before any per-object detail) makes three structural claims, each checked against a
same-category parsed count:

| Claim | Documented N | Parsed M (same category) | N = M? | Verdict |
|---|---|---|---|---|
| "seven tables" (README:8) | 7 | 7 (`CREATE TABLE` count, Component Manifest) | yes | VERIFIED |
| "one staging table" (README:8) | 1 | 1 (`CREATE GLOBAL TEMPORARY TABLE` count) | yes | VERIFIED |
| "six routines" (README:8) | 6 | 6 (3 standalone procedures + 1 standalone function + 2 packaged procedures) | yes | VERIFIED |

The README's `Layout` section (lines 10-18) names each of the 7 `sql/` files and a one-line
description of its contents:

| Path claim | Verdict |
|---|---|
| `sql/01-schema.sql` — tables, GTT, sequence, VARRAY type | VERIFIED — matches actual content |
| `sql/02-pkg_fleet_billing.pks` — package spec (ref cursor type, two procedure signatures) | VERIFIED |
| `sql/03-pkg_fleet_billing.pkb` — package body, session-scoped package state | VERIFIED |
| `sql/04-prc_apply_rate_rules.sql` — pricing policy | VERIFIED |
| `sql/05-prc_settlement_sweep.sql` — nightly sweep | VERIFIED |
| `sql/06-prc_purge_stale_holds.sql` — housekeeping | VERIFIED |
| `sql/07-fn_trip_surcharge.sql` — per-zone surcharge | VERIFIED |

No mismatch was found between documentation and parsed reality on any of the claims checked above.

**Context-intake table:**

| Artifact Type | Extensions | Found? | Count |
|---------------|-----------|--------|-------|
| Stored procedures | `.sql`, CREATE PROCEDURE | Yes | 5 (3 standalone + 2 packaged) |
| Scalar functions | `.sql`, CREATE FUNCTION RETURNS scalar | Yes | 1 |
| Table-valued functions | `.sql`, CREATE FUNCTION RETURNS TABLE | No | 0 |
| Triggers | `.sql`, CREATE TRIGGER, `.trg` | No | 0 |
| Views (with logic) | `.sql`, CREATE VIEW | No | 0 |
| DDL / table schemas | `.sql`, CREATE TABLE, `.ddl` | Yes | 8 (7 permanent tables + 1 global temporary table) |
| Jobs / scheduled tasks | `.sql`, CREATE JOB, SQL Agent | No | 0 |
| Packages (Oracle) | `.pks`, `.pkb`, CREATE PACKAGE | Yes | 1 (spec + body) |
| Test scripts | `*Test*.sql`, `*_test.sql` | No | 0 |

No test scripts were found (`find ... -iname '*test*'` over the source tree returned only the
`xraytest1` directory name itself, no file). Nothing is excluded from the production logic
inventory below.

### Component Manifest

```
$ grep -nE '^CREATE TABLE' sql/*.sql | wc -l
7
$ grep -nE '^CREATE GLOBAL TEMPORARY TABLE' sql/*.sql | wc -l
1
$ grep -nE '^CREATE SEQUENCE' sql/*.sql | wc -l
1
$ grep -nE '^CREATE (OR REPLACE )?TYPE' sql/*.sql | wc -l
1
$ grep -nE '^CREATE (OR REPLACE )?(PROCEDURE|FUNCTION)' sql/*.sql | wc -l
4
$ grep -nE '^[[:space:]]+(PROCEDURE|FUNCTION)[[:space:]]' sql/*.pks sql/*.pkb | wc -l
4
```

The last count (4) is the package spec's 2 declarations plus the package body's 2 definitions for
the SAME 2 routines — per the "package SPEC and BODY declare the SAME routine" rule, this counts
as **2** packaged routines, not 4.

Counting basis for this manifest: the package (spec `CREATE OR REPLACE PACKAGE` +
body `CREATE OR REPLACE PACKAGE BODY`, one container) is counted as one manifest object in its own
right, and its two packaged procedures are listed as their own manifest rows because they are the
units the Extraction Metrics table and the call graph operate on.

| Type | Object Name | File | LOC | Notable Flags |
|------|------------|------|-----|---------------|
| Table | `drivers` | 01-schema.sql | 7 (lines 7-13) | Referenced by 2 routines (Dimension 3) |
| Table | `vehicles` | 01-schema.sql | 8 (lines 15-22) | FK to `drivers` |
| Table | `trips` | 01-schema.sql | 9 (lines 24-33) | FK to `vehicles`; hub resource, 3 objects (Dimension 3) |
| Table | `rate_rules` | 01-schema.sql | 6 (lines 35-41) | — |
| Table | `charges` | 01-schema.sql | 7 (lines 43-50) | — |
| Table | `settlement_batches` | 01-schema.sql | 6 (lines 52-58) | — |
| Table | `driver_holds` | 01-schema.sql | 5 (lines 60-65) | — |
| Global Temporary Table | `tmp_settlement_stage` | 01-schema.sql | 6 (lines 68-73) | `ON COMMIT PRESERVE ROWS`; cross-routine handoff (Dimension 5) |
| Sequence | `seq_settlement_batch` | 01-schema.sql | 1 (line 75) | Single consumer (Dimension 5) |
| Type (VARRAY) | `t_charge_code_list` | 01-schema.sql | 1 (line 77) | Used in `load_driver_batch` signature |
| Package | `pkg_fleet_billing` | 02-pkg_fleet_billing.pks, 03-pkg_fleet_billing.pkb | 19 + 64 | Holds session-scoped package state (Dimension 5) |
| Packaged Procedure | `pkg_fleet_billing.load_driver_batch` | 02:7-11, 03:9-35 | — | All 3 UDT forms in signature (Dimension 1 Extraction Metrics) |
| Packaged Procedure | `pkg_fleet_billing.post_batch_totals` | 02:14-16, 03:37-61 | — | Reads `tmp_settlement_stage`, writes `g_run_total` |
| Standalone Procedure | `prc_apply_rate_rules` | 04-prc_apply_rate_rules.sql | 73 | Densest branch count in the system (11) |
| Standalone Procedure | `prc_settlement_sweep` | 05-prc_settlement_sweep.sql | 49 | Only nested cursor loop; blanket exception swallow (CRITICAL) |
| Standalone Procedure | `prc_purge_stale_holds` | 06-prc_purge_stale_holds.sql | 15 | Zero params, zero branches |
| Standalone Function | `fn_trip_surcharge` | 07-fn_trip_surcharge.sql | 16 | No caller found in source |

```
$ echo $((7+1+1+1+1+2+3+1))
17
$ wc -l sql/*.sql sql/*.pks sql/*.pkb | tail -1
314 total
```

**Grand total: 17 objects (= 7 tables + 1 global temporary table + 1 sequence + 1 type + 1 package
+ 2 packaged procedures + 3 standalone procedures + 1 standalone function), 314 LOC (= 78 + 19 + 64
+ 73 + 49 + 15 + 16).**

Per-type LOC subtotals (from `wc -l`): `01-schema.sql` 78, `02-pkg_fleet_billing.pks` 19,
`03-pkg_fleet_billing.pkb` 64, `04-prc_apply_rate_rules.sql` 73, `05-prc_settlement_sweep.sql` 49,
`06-prc_purge_stale_holds.sql` 15, `07-fn_trip_surcharge.sql` 16.

### Extraction Metrics

**Scratch file (`metrics.tsv`) materialized first:**

```
prc_apply_rate_rules|4|0|11|none|04-prc_apply_rate_rules.sql|73
prc_settlement_sweep|2|2|1|none|05-prc_settlement_sweep.sql|49
prc_purge_stale_holds|0|0|0|none|06-prc_purge_stale_holds.sql|15
fn_trip_surcharge|2|0|2|none|07-fn_trip_surcharge.sql|16
pkg_fleet_billing.load_driver_batch|3|0|0|%ROWTYPE, VARRAY, REF CURSOR|02-pkg_fleet_billing.pks:7-11 / 03-pkg_fleet_billing.pkb:9-13|27
pkg_fleet_billing.post_batch_totals|1|1|0|none|02-pkg_fleet_billing.pks:14-16 / 03-pkg_fleet_billing.pkb:37-39|25
```

**Params — detection command and raw output:**

```
$ grep -nE '^[[:space:]]*(CREATE[[:space:]]+(OR[[:space:]]+REPLACE[[:space:]]+)?)?(PROCEDURE|FUNCTION)[[:space:]]+[A-Za-z_][A-Za-z0-9_$#]*' sql/*
04-prc_apply_rate_rules.sql:1:CREATE OR REPLACE PROCEDURE prc_apply_rate_rules (
05-prc_settlement_sweep.sql:1:CREATE OR REPLACE PROCEDURE prc_settlement_sweep (
06-prc_purge_stale_holds.sql:1:CREATE OR REPLACE PROCEDURE prc_purge_stale_holds IS
07-fn_trip_surcharge.sql:1:CREATE OR REPLACE FUNCTION fn_trip_surcharge (
02-pkg_fleet_billing.pks:7:  PROCEDURE load_driver_batch (
02-pkg_fleet_billing.pks:14:  PROCEDURE post_batch_totals (
03-pkg_fleet_billing.pkb:9:  PROCEDURE load_driver_batch (
03-pkg_fleet_billing.pkb:37:  PROCEDURE post_batch_totals (
```

Each banner's parameter list was then read through its closing `)`: `prc_apply_rate_rules(04:1-6)`
= `p_driver_id, p_class_code, p_zone_code, p_out_rate` = 4. `prc_settlement_sweep(05:1-4)` =
`p_region_code, p_out_batch_id` = 2. `prc_purge_stale_holds(06:1)` has no parenthesized list at
all = 0 (written as `0`, not blank). `fn_trip_surcharge(07:1-4)` = `p_trip_id, p_zone_code` = 2
(its `RETURN NUMBER` at line 4 is the return type, not a parameter — never incremented into this
column). `load_driver_batch(02:7-11 / 03:9-13)` = `p_driver, p_charge_codes, p_charges` = 3, one
parameter set counted once even though the spec and body each declare it.
`post_batch_totals(02:14-16 / 03:37-39)` = `p_batch_id` = 1.

**Cursor Loops — detection command and raw output:**

```
$ grep -nE 'CURSOR[[:space:]]+[A-Za-z_]|FOR[[:space:]]+[A-Za-z_][A-Za-z0-9_$#]*[[:space:]]+IN[[:space:]]|OPEN[[:space:]]+|FETCH[[:space:]]+' sql/*
05-prc_settlement_sweep.sql:7:  CURSOR c_vehicles (cp_region VARCHAR2) IS
05-prc_settlement_sweep.sql:12:  CURSOR c_trips (cp_vehicle_id NUMBER) IS
05-prc_settlement_sweep.sql:27:  FOR v IN c_vehicles(p_region_code) LOOP
05-prc_settlement_sweep.sql:31:    FOR t IN c_trips(v.vehicle_id) LOOP
03-pkg_fleet_billing.pkb:21:    FOR i IN 1 .. p_charge_codes.COUNT LOOP
03-pkg_fleet_billing.pkb:30:    OPEN p_charges FOR
03-pkg_fleet_billing.pkb:40:    CURSOR c_staged (cp_batch_id NUMBER) IS
03-pkg_fleet_billing.pkb:48:    FOR r IN c_staged(p_batch_id) LOOP
```

Exclusions applied, each named with its line: `03:21` (`FOR i IN 1 .. p_charge_codes.COUNT LOOP`)
is a numeric `FOR` over a collection bound, not a declared cursor — excluded, contributes 0.
`03:30` (`OPEN p_charges FOR`) opens a `REF CURSOR` handed to the caller — it is not a loop at
all — excluded. `05:7` and `05:12` are cursor *declarations*, not loops themselves — the loop is
the `FOR ... IN` that drives each (`05:27`, `05:31`). `03:40` is likewise a declaration, driven by
`03:48`. That leaves 3 real cursor loops: `05:27` (outer, `c_vehicles`), `05:31` (inner, `c_trips`,
nested inside `05:27` — depth 2, closing `END LOOP` at `05:40` and `05:42`), and `03:48`
(`c_staged`). `prc_settlement_sweep` = 2 (nested, depth 2). `pkg_fleet_billing.post_batch_totals`
= 1. `pkg_fleet_billing.load_driver_batch` = 0 (its only loop-shaped construct, `03:21`, is
excluded above). All other routines = 0 (no cursor construct at all in their source).

**Branches — detection command and raw output:**

```
$ grep -nEw 'IF|ELSIF|WHEN|WHILE|ELSE|EXCEPTION|EXIT' sql/*
04-prc_apply_rate_rules.sql:30:  IF v_status = 'HOLD' THEN
04-prc_apply_rate_rules.sql:31:    IF v_hold_until > SYSDATE THEN
04-prc_apply_rate_rules.sql:34:    ELSE
04-prc_apply_rate_rules.sql:36:    END IF;
04-prc_apply_rate_rules.sql:37:  ELSIF v_status = 'SUSPENDED' THEN
04-prc_apply_rate_rules.sql:40:  ELSIF v_status = 'PENDING' THEN
04-prc_apply_rate_rules.sql:42:  ELSE
04-prc_apply_rate_rules.sql:44:  END IF;
04-prc_apply_rate_rules.sql:47:    WHEN 'URBAN' THEN
04-prc_apply_rate_rules.sql:49:    WHEN 'RURAL' THEN
04-prc_apply_rate_rules.sql:51:    WHEN 'AIRPORT' THEN
04-prc_apply_rate_rules.sql:53:    ELSE
04-prc_apply_rate_rules.sql:57:  IF v_region IS NULL THEN
04-prc_apply_rate_rules.sql:59:  END IF;
04-prc_apply_rate_rules.sql:64:                               WHEN p_out_rate > 5 THEN 1.50
04-prc_apply_rate_rules.sql:65:                               WHEN p_out_rate > 2 THEN 0.75
04-prc_apply_rate_rules.sql:66:                               ELSE 0
04-prc_apply_rate_rules.sql:69:  IF p_out_rate < 0 THEN
04-prc_apply_rate_rules.sql:71:  END IF;
05-prc_settlement_sweep.sql:35:      IF v_rate > 0 THEN
05-prc_settlement_sweep.sql:38:      END IF;
05-prc_settlement_sweep.sql:45:EXCEPTION
05-prc_settlement_sweep.sql:46:  WHEN OTHERS THEN
07-fn_trip_surcharge.sql:11:           WHEN 'URBAN'   THEN v_miles * 0.10
07-fn_trip_surcharge.sql:12:           WHEN 'AIRPORT' THEN v_miles * 0.20
07-fn_trip_surcharge.sql:13:           ELSE 0
```

Stated branch-counting basis (restated here per Hard Constraint, and applied identically to every
routine): counted are `IF` (opening a conditional), `ELSIF`, and each `CASE`/`WHEN` arm; not
counted are `ELSE` arms, `EXCEPTION WHEN` handlers, `END IF`, loop-driving `WHILE`/`EXIT WHEN` that
the Cursor Loops column already counted. This system has no bare counter `WHILE` or `EXIT WHEN`
loop, so that double-count rule is not exercised here.

`prc_apply_rate_rules`: `IF` at `30, 31, 57, 69` (4) + `ELSIF` at `37, 40` (2) + `CASE WHEN` arms at
`47, 49, 51` (statement `CASE`, closed `END CASE` at line 55, not shown in the grep because it
matches neither `IF`/`ELSIF`/`WHEN`/`ELSE`/`EXCEPTION`/`WHILE`/`EXIT`) and `64, 65` (expression
`CASE`) (5) = **11**. The `ELSE` hits at `34, 42, 53, 66` and `END IF` hits at `36, 44, 59, 71` are
excluded per the stated basis.

`prc_settlement_sweep`: one `IF` at `35` = **1**. The `EXCEPTION`/`WHEN OTHERS` pair at `45-46` is
an error handler, excluded per the stated basis (see Dimension 4 for its treatment as an error
path).

`fn_trip_surcharge`: `CASE WHEN` arms at `11, 12` = **2**. The `ELSE` at `13` is excluded.

`prc_purge_stale_holds`, `pkg_fleet_billing.load_driver_batch`,
`pkg_fleet_billing.post_batch_totals`: no `IF`/`ELSIF`/`WHEN`/non-cursor-`WHILE`/non-cursor-`EXIT
WHEN` hit at all in their source = **0** each (written as `0`, not blank, not omitted).

```
$ awk -F'|' '{p+=$2; c+=$3; b+=$4} END {print "Params="p, "CursorLoops="c, "Branches="b}' metrics.tsv
Params=12 CursorLoops=3 Branches=14
```

**UDT Usage — detection command and raw output:**

```
$ grep -nE '%ROWTYPE|%TYPE|IS[[:space:]]+RECORD|VARRAY|IS[[:space:]]+TABLE[[:space:]]+OF|REF[[:space:]]+CURSOR|SYS_REFCURSOR' sql/*
04-prc_apply_rate_rules.sql:9:  v_status     drivers.status%TYPE;
04-prc_apply_rate_rules.sql:10:  v_hold_until drivers.hold_until%TYPE;
04-prc_apply_rate_rules.sql:11:  v_base_rate  rate_rules.base_rate%TYPE;
04-prc_apply_rate_rules.sql:12:  v_surcharge  rate_rules.surcharge_pct%TYPE;
03-pkg_fleet_billing.pkb:10:    p_driver       IN  drivers%ROWTYPE,
01-schema.sql:77:CREATE OR REPLACE TYPE t_charge_code_list IS VARRAY(20) OF VARCHAR2(12);
07-fn_trip_surcharge.sql:6:  v_miles trips.miles%TYPE;
02-pkg_fleet_billing.pks:4:  TYPE t_charge_cur IS REF CURSOR;
02-pkg_fleet_billing.pks:8:    p_driver       IN  drivers%ROWTYPE,
```

`04:9-12` and `07:6` are `%TYPE` anchors on **local variable declarations** inside the body — per
the signature-only rule, these never enter this column. `01:77` and `02:4` are the TYPE
*definitions* (VARRAY, REF CURSOR), not usages in a signature by themselves — resolving where
those two type names (`t_charge_code_list`, `t_charge_cur`) are actually used as parameter types
required a second, targeted search:

```
$ grep -nE 't_charge_code_list|t_charge_cur\b' sql/*
01-schema.sql:77:CREATE OR REPLACE TYPE t_charge_code_list IS VARRAY(20) OF VARCHAR2(12);
02-pkg_fleet_billing.pks:4:  TYPE t_charge_cur IS REF CURSOR;
02-pkg_fleet_billing.pks:9:    p_charge_codes IN  t_charge_code_list,
02-pkg_fleet_billing.pks:10:    p_charges      OUT t_charge_cur
03-pkg_fleet_billing.pkb:11:    p_charge_codes IN  t_charge_code_list,
03-pkg_fleet_billing.pkb:12:    p_charges      OUT t_charge_cur
```

`load_driver_batch`'s signature carries all three UDT forms: `%ROWTYPE` (`p_driver`, `02:8` /
`03:10`, anchored on `drivers`), VARRAY (`p_charge_codes`, `02:9` / `03:11`, type
`t_charge_code_list`), and `REF CURSOR` (`p_charges`, `02:10` / `03:12`, type `t_charge_cur`). No
other routine's signature contains any UDT construct — each gets the literal word `none`.

| Object | Params | Cursor Loops | Branches | UDT Usage | File | LOC |
|--------|--------|--------------|----------|-----------|------|-----|
| `prc_apply_rate_rules` | 4 | 0 | 11 | none | 04-prc_apply_rate_rules.sql | 73 |
| `prc_settlement_sweep` | 2 | 2 | 1 | none | 05-prc_settlement_sweep.sql | 49 |
| `prc_purge_stale_holds` | 0 | 0 | 0 | none | 06-prc_purge_stale_holds.sql | 15 |
| `fn_trip_surcharge` | 2 | 0 | 2 | none | 07-fn_trip_surcharge.sql | 16 |
| `pkg_fleet_billing.load_driver_batch` | 3 | 0 | 0 | `%ROWTYPE`, VARRAY (`t_charge_code_list`), `REF CURSOR` (`t_charge_cur`) | 02-pkg_fleet_billing.pks:7-11 / 03-pkg_fleet_billing.pkb:9-13 | 27 |
| `pkg_fleet_billing.post_batch_totals` | 1 | 1 | 0 | none | 02-pkg_fleet_billing.pks:14-16 / 03-pkg_fleet_billing.pkb:37-39 | 25 |
| **Totals** | **12** | **3** | **14** | — | — | — |

**Branch-counting basis restated:** each `IF` that opens a conditional, each `ELSIF`, each `WHEN`
arm of a `CASE` statement or expression, and any non-cursor `WHILE`/`EXIT WHEN` (none present in
this system) are counted. `ELSE` arms, `EXCEPTION WHEN` handlers, and loop heads/terminators
already counted in Cursor Loops are not counted. This is a keyword count on a stated basis — it is
not cyclomatic complexity, not a defect measure, and not an effort measure.

### Missing-Reference Table

No missing references were found. Every table, the global temporary table, the sequence, and both
user-defined types referenced anywhere in the routines are defined in `01-schema.sql` /
`02-pkg_fleet_billing.pks`, and the system's one static call (`prc_settlement_sweep` →
`prc_apply_rate_rules`) resolves to a definition in the analyzed source. The one non-user object
referenced is Oracle's built-in pseudo-table `DUAL` (`05-prc_settlement_sweep.sql:22`) — a system
object, not a project table, and excluded from this table on that basis rather than flagged
missing.

| Source File:Line | Reference Type | Target | Impact |
|-----------------|---------------|--------|--------|
| — | — | — | (table intentionally empty — no missing references found) |

### Coverage Honesty Check

Analysis covers 17 of 17 referenced objects (100% coverage; both figures copied from the Component
Manifest grand total and the Missing-Reference Table's row count above — `17 / (17 + 0)`). 0
objects are referenced but not defined.

### Dead / Orphan Code

Liveness was checked for every routine name by searching the full source for every occurrence of
that name outside its own declaration/`END` banner (see Dimension 2 for the full search output).
Result: **5 of the system's 6 routines have no caller found anywhere in the analyzed source.**

| Object | Caller found in source? | Classification |
|---|---|---|
| `prc_apply_rate_rules` | Yes — `prc_settlement_sweep` (`05:33`) | Live |
| `prc_settlement_sweep` | No | Possibly dead — no static caller in analyzed source; likely a scheduled-job entry point given the "nightly sweep" framing in its header comment (`05:5-6`), but this is unverifiable from source alone |
| `prc_purge_stale_holds` | No | Possibly dead — no static caller in analyzed source; likely a scheduled housekeeping job per its header comment (`06:2`), unverifiable from source alone |
| `fn_trip_surcharge` | No | Possibly dead — no static caller in analyzed source; may be invoked from application code not included in this dump |
| `pkg_fleet_billing.load_driver_batch` | No | Possibly dead — no static caller in analyzed source; may be invoked from application code not included in this dump |
| `pkg_fleet_billing.post_batch_totals` | No | Possibly dead — no static caller in analyzed source; may be invoked from application code not included in this dump. Note: this routine has a real, uncalled-graph DATA dependency on `prc_settlement_sweep`'s output via `tmp_settlement_stage` (Dimension 5) even though no call edge exists |

None of these 5 are classified "confirmed dead" — the source contains no evidence either way for
routines with plausible external (application or scheduler) callers; "confirmed dead" is reserved
for objects with demonstrable unreachability, which this analysis cannot establish from SQL source
alone.

---

## 2. Call & Dependency Graph

**Liveness search — every routine name searched across the full source, excluding its own
declaration/`END` banner:**

```
$ grep -nE '\bprc_apply_rate_rules\b' sql/*
04-prc_apply_rate_rules.sql:1:CREATE OR REPLACE PROCEDURE prc_apply_rate_rules (
04-prc_apply_rate_rules.sql:72:END prc_apply_rate_rules;
05-prc_settlement_sweep.sql:33:      prc_apply_rate_rules(v_driver, v.class_code, t.zone_code, v_rate);
```
(one real call site: `05:33`)

```
$ grep -nE '\bpost_batch_totals\b' sql/*
05-prc_settlement_sweep.sql:6:  -- prices the trip and stages the result for post_batch_totals to pick up.
02-pkg_fleet_billing.pks:14:  PROCEDURE post_batch_totals (
03-pkg_fleet_billing.pkb:37:  PROCEDURE post_batch_totals (
03-pkg_fleet_billing.pkb:61:  END post_batch_totals;
```
The `05:6` hit is a **comment**, not a call — "stages the result for `post_batch_totals` to pick
up" describes the data handoff (confirmed as the `tmp_settlement_stage` GTT in Dimension 5), not
an invocation. There is no `EXEC`/direct call to `post_batch_totals` anywhere in the source.

The remaining 4 routine names (`prc_settlement_sweep`, `prc_purge_stale_holds`,
`fn_trip_surcharge`, `load_driver_batch`) each returned only their own declaration and `END`
banner lines when searched — no call site.

**Dependency Graph (scratch file `calls.tsv` — 1 row, materialized before this section):**

```
prc_settlement_sweep|prc_apply_rate_rules|05-prc_settlement_sweep.sql:33
```

```
prc_settlement_sweep [ENTRY POINT — no caller found in analyzed source]
  -> prc_apply_rate_rules (05-prc_settlement_sweep.sql:33) [HIGH-CONF, static call]

prc_apply_rate_rules [no caller other than the edge above]

prc_purge_stale_holds [ENTRY POINT — no caller found in analyzed source]

fn_trip_surcharge [ENTRY POINT — no caller found in analyzed source]

pkg_fleet_billing.load_driver_batch [ENTRY POINT — no caller found in analyzed source]

pkg_fleet_billing.post_batch_totals [ENTRY POINT — no caller found in analyzed source]
  (non-call DATA dependency: reads tmp_settlement_stage written by prc_settlement_sweep,
   and shares package variable g_run_total with load_driver_batch — see Dimension 5;
   neither dependency appears as an edge on this graph)
```

**Dynamic SQL flagging.** No dynamic SQL was found in the analyzed source:

```
$ grep -nE 'EXECUTE IMMEDIATE|DBMS_SQL' sql/*
(no output)
```

This class is stated explicitly as empty per Hard Constraint 5's "unknowns/empties are valid, not
omitted" rule — no edges in this system are dynamic-SQL-derived, so no `[MEDIUM-CONF]`/`[LOW-CONF]`
tags apply anywhere in this graph. Every edge shown above is `[HIGH-CONF]`.

**External / Unresolvable Edges.** One reference to a non-project object was found:
`FROM dual` (`05-prc_settlement_sweep.sql:22`), Oracle's built-in one-row pseudo-table used to
evaluate `seq_settlement_batch.NEXTVAL`. This is a normal, universal Oracle construct (see the
"`FROM DUAL` is a syntax artifact, not a footgun" note in the dialect reference) — it disappears on
migration to a bare `SELECT` and is not flagged as a risk. No `sp_*`/`xp_*`/`master.`/linked-server
references exist in PL/SQL terms, and none were found.

**Liveness Claims Require Citations.** Every liveness claim above cites its search command and raw
output. The single positive liveness claim (`prc_apply_rate_rules` is called) cites `05:33`; every
"no caller found" claim is backed by the full-source grep for that name showing no call site
outside the routine's own banner.

**Hub Objects.** Over the 1 invocation edge in `calls.tsv`:

```
$ awk -F'|' '{print $1, $2}' calls.tsv | sort -u | awk '{c[$1]++} END {for (o in c) print o, c[o]}'
prc_settlement_sweep 1
$ awk -F'|' '{print $2, $1}' calls.tsv | sort -u | awk '{c[$1]++} END {for (o in c) print o, c[o]}'
prc_apply_rate_rules 1
```

No object reaches the 3+ invocation-edge threshold. **No hub objects in the call graph.**
Cross-reference Dimension 3: the CRUD matrix's Resource Touch Tally does find one table-level hub
(`trips`, 3 distinct touching objects) — that hub exists on table-DML coupling, never counted here
because invocation edges and table-DML coupling are different measures.

**Extraction Sequencing.**
1. `prc_apply_rate_rules` — leaf on the call graph: zero outgoing calls, one incoming call.
2. `prc_settlement_sweep` — depends only on the leaf above via its one static call (`05:33`).
3. `prc_purge_stale_holds`, `fn_trip_surcharge`, `pkg_fleet_billing.load_driver_batch`,
   `pkg_fleet_billing.post_batch_totals` — no static call dependency on any other routine in the
   analyzed source, so the call graph alone permits extracting them in any order.

The call graph is an incomplete extraction-ordering signal on its own: `post_batch_totals` has a
non-call data dependency on `prc_settlement_sweep`'s staged output (`tmp_settlement_stage`), and
`load_driver_batch` shares session state (`g_run_total`) with `post_batch_totals`. Neither
dependency produces an edge on this graph, but both must be honored when sequencing extraction
waves — see Dimension 5 and the shared-state clusters it identifies.

---

## 3. CRUD Matrix & Trigger Cascade Map

**Scratch file `crud.tsv` (16 rows, materialized before this section):**

```
prc_apply_rate_rules|drivers|Table|R|SELECT INTO|04-prc_apply_rate_rules.sql:19-22
prc_apply_rate_rules|rate_rules|Table|R|SELECT INTO|04-prc_apply_rate_rules.sql:24-28
prc_settlement_sweep|vehicles|Table|R|SELECT (cursor c_vehicles)|05-prc_settlement_sweep.sql:7-10
prc_settlement_sweep|vehicles|Table|R|SELECT INTO (driver lookup)|05-prc_settlement_sweep.sql:29
prc_settlement_sweep|trips|Table|R|SELECT (cursor c_trips)|05-prc_settlement_sweep.sql:12-16
prc_settlement_sweep|settlement_batches|Table|C|INSERT INTO|05-prc_settlement_sweep.sql:24-25
prc_settlement_sweep|tmp_settlement_stage|Table|C|INSERT INTO|05-prc_settlement_sweep.sql:36-37
prc_settlement_sweep|prc_apply_rate_rules|Sproc||CALL|05-prc_settlement_sweep.sql:33
pkg_fleet_billing.load_driver_batch|charges|Table|C|INSERT INTO|03-pkg_fleet_billing.pkb:22-27
pkg_fleet_billing.load_driver_batch|charges|Table|R|SELECT (OPEN...FOR ref cursor)|03-pkg_fleet_billing.pkb:30-34
pkg_fleet_billing.post_batch_totals|tmp_settlement_stage|Table|R|SELECT (cursor c_staged)|03-pkg_fleet_billing.pkb:40-43
pkg_fleet_billing.post_batch_totals|trips|Table|U|UPDATE|03-pkg_fleet_billing.pkb:51-53
pkg_fleet_billing.post_batch_totals|settlement_batches|Table|U|UPDATE|03-pkg_fleet_billing.pkb:56-58
prc_purge_stale_holds|driver_holds|Table|D|DELETE FROM|06-prc_purge_stale_holds.sql:5-6
prc_purge_stale_holds|drivers|Table|U|UPDATE|06-prc_purge_stale_holds.sql:8-11
fn_trip_surcharge|trips|Table|R|SELECT INTO|07-fn_trip_surcharge.sql:8
```

| Object | Resource | Type | C | R | U | D | Access Pattern | File:Line |
|--------|----------|------|---|---|---|---|----------------|-----------|
| `prc_apply_rate_rules` | `drivers` | Table | | X | | | SELECT INTO | 04:19-22 |
| `prc_apply_rate_rules` | `rate_rules` | Table | | X | | | SELECT INTO | 04:24-28 |
| `prc_settlement_sweep` | `vehicles` | Table | | X | | | SELECT (cursor `c_vehicles`) | 05:7-10 |
| `prc_settlement_sweep` | `vehicles` | Table | | X | | | SELECT INTO (driver lookup) | 05:29 |
| `prc_settlement_sweep` | `trips` | Table | | X | | | SELECT (cursor `c_trips`) | 05:12-16 |
| `prc_settlement_sweep` | `settlement_batches` | Table | X | | | | INSERT INTO | 05:24-25 |
| `prc_settlement_sweep` | `tmp_settlement_stage` | Table | X | | | | INSERT INTO | 05:36-37 |
| `prc_settlement_sweep` | `prc_apply_rate_rules` | Sproc | | | | | CALL | 05:33 |
| `pkg_fleet_billing.load_driver_batch` | `charges` | Table | X | | | | INSERT INTO | 03:22-27 |
| `pkg_fleet_billing.load_driver_batch` | `charges` | Table | | X | | | SELECT (`OPEN...FOR` ref cursor) | 03:30-34 |
| `pkg_fleet_billing.post_batch_totals` | `tmp_settlement_stage` | Table | | X | | | SELECT (cursor `c_staged`) | 03:40-43 |
| `pkg_fleet_billing.post_batch_totals` | `trips` | Table | | | X | | UPDATE | 03:51-53 |
| `pkg_fleet_billing.post_batch_totals` | `settlement_batches` | Table | | | X | | UPDATE | 03:56-58 |
| `prc_purge_stale_holds` | `driver_holds` | Table | | | | X | DELETE FROM | 06:5-6 |
| `prc_purge_stale_holds` | `drivers` | Table | | | X | | UPDATE | 06:8-11 |
| `fn_trip_surcharge` | `trips` | Table | | X | | | SELECT INTO | 07:8 |

No view rows and no trigger rows appear because the Component Manifest confirms zero views and
zero triggers exist in this system (Dimension 1) — the matrix is complete over the object classes
actually present.

**Resource Touch Tally (computed against `crud.tsv`):**

```
$ awk -F'|' '{print $2, $1}' crud.tsv | sort -u | awk '{c[$1]++} END {for (r in c) print r, c[r]}'
charges 1
driver_holds 1
drivers 2
prc_apply_rate_rules 1
rate_rules 1
settlement_batches 2
tmp_settlement_stage 2
trips 3
vehicles 1
```

| Resource | Distinct objects touching | Hub? (3+) |
|----------|---------------------------|-----------|
| `charges` | 1 | no |
| `driver_holds` | 1 | no |
| `drivers` | 2 | no |
| `prc_apply_rate_rules` | 1 | no |
| `rate_rules` | 1 | no |
| `settlement_batches` | 2 | no |
| `tmp_settlement_stage` | 2 | no |
| `trips` | 3 | yes |
| `vehicles` | 1 | no |

**Hub resource:** `trips` — `prc_settlement_sweep` (05:12-16), `pkg_fleet_billing.post_batch_totals`
(03:51-53), `fn_trip_surcharge` (07:8) — 3 objects (= length of this list). No other resource
reaches the 3+ threshold.

### Trigger Cascade Map

**None.** The Component Manifest confirms 0 triggers exist in this source (`grep -nE '^CREATE
(OR REPLACE )?TRIGGER' sql/*.sql` → no output). This is a trigger-less, routine-only Oracle corpus
— the trigger cascade map legitimately comes back empty, per the Oracle-orientation guidance for
prefix-less, package/schema-qualified PL/SQL systems without a trigger layer.

---

## 4. Transaction & Error-Handling Semantics

**Transaction Boundaries — explicit `COMMIT`/`ROLLBACK`/`SAVEPOINT` search:**

```
$ grep -nE '\bCOMMIT\b|\bROLLBACK\b|\bSAVEPOINT\b|AUTONOMOUS_TRANSACTION' sql/*
01-schema.sql:73:) ON COMMIT PRESERVE ROWS;
06-prc_purge_stale_holds.sql:13:  COMMIT;
03-pkg_fleet_billing.pkb:60:    COMMIT;
```

`01:73` is DDL syntax on the GTT definition, not a transaction-control statement — excluded from
the count of explicit commits. Two routines issue an explicit `COMMIT`:
`prc_purge_stale_holds` (`06:13`, after its `DELETE`/`UPDATE` pair — atomic group:
`06:5-11` committed together at `06:13`) and `pkg_fleet_billing.post_batch_totals` (`03:60`, after
its cursor-driven `UPDATE trips` loop and `UPDATE settlement_batches` — atomic group: `03:44-58`
committed together at `03:60`).

**No `COMMIT` appears in `prc_settlement_sweep` or `pkg_fleet_billing.load_driver_batch`.** Per
Oracle's non-autocommit default (see dialect reference, "Transaction Control and the Commit
Model"), the `INSERT`s these two routines perform (`settlement_batches` and
`tmp_settlement_stage` in `prc_settlement_sweep`; `charges` in `load_driver_batch`) accumulate in
the caller's transaction and are not durable until the caller commits — this is an implicit
contract with whatever calls these routines, invisible from either routine's own source. No
`SAVEPOINT` and no `PRAGMA AUTONOMOUS_TRANSACTION` were found anywhere in the source (both are
absent from the grep output above) — this class is stated explicitly as empty, not omitted.

**Error Swallowing (CRITICAL).**

```
$ grep -nE 'EXCEPTION|WHEN OTHERS|RAISE' sql/*
05-prc_settlement_sweep.sql:45:EXCEPTION
05-prc_settlement_sweep.sql:46:  WHEN OTHERS THEN
```

`prc_settlement_sweep` is the only routine in the system with an `EXCEPTION` block, and it is a
pure swallow: `EXCEPTION WHEN OTHERS THEN NULL;` (`05:45-47`) — no `RAISE`, no logging, no
re-throw. This is a **CRITICAL** finding per the Severity Definitions ("will cause ... silent
behavior change if extraction proceeds without addressing this finding"): any exception raised
inside the nested sweep loop (`05:27-42`) — including a `NO_DATA_FOUND` propagated up from
`prc_apply_rate_rules`'s own `SELECT ... INTO` (`04:19-22`) if `prc_apply_rate_rules` is called
with a `driver_id` absent from `drivers` — returns to the caller as an ordinary successful
completion. `prc_apply_rate_rules` and `load_driver_batch` and `fn_trip_surcharge` each have a
`SELECT ... INTO` (`04:19-22`, `04:24-28`; none in `load_driver_batch`'s own body — its only reads
are via cursor/ref-cursor; `07:8`) with **no local exception handler** — for `prc_apply_rate_rules`,
any `NO_DATA_FOUND`/`TOO_MANY_ROWS` propagates to its one known caller, `prc_settlement_sweep`,
where it is swallowed as described above. For `fn_trip_surcharge` and `load_driver_batch`, no
static caller exists in this source (Dimension 2), so where their unhandled `SELECT INTO`
exceptions propagate to is unknown from source alone.

**Compounding risk: `OUT` parameter copy-out is lost on the swallowed path.** None of the `OUT`/`IN
OUT` parameters in this source declare `NOCOPY`:

```
$ grep -nE 'OUT[[:space:]]+[A-Za-z]|NOCOPY' sql/*
05-prc_settlement_sweep.sql:3:  p_out_batch_id OUT NUMBER
02-pkg_fleet_billing.pks:10:    p_charges      OUT t_charge_cur
04-prc_apply_rate_rules.sql:5:  p_out_rate   OUT NUMBER
03-pkg_fleet_billing.pkb:12:    p_charges      OUT t_charge_cur
```

Per Oracle's copy-out-by-value semantics for `OUT` parameters without `NOCOPY` (see dialect
reference), the caller's variable is only updated on normal return. `prc_settlement_sweep` assigns
its `p_out_batch_id` at `05:44` — after the loop the `EXCEPTION` block wraps, and immediately
before that block begins at `05:45`. Any exception raised inside the loop skips line 44 and jumps
to the swallow at `45-47`; the routine then returns normally with `p_out_batch_id` never assigned.
The caller cannot distinguish "batch fully staged" from "nothing staged" without independently
querying `settlement_batches`/`tmp_settlement_stage`.

**Autonomous Transactions.** None found (`AUTONOMOUS_TRANSACTION` absent from the grep output
above) — stated explicitly as empty.

**Uncatchable Errors (T-SQL-specific).** Not applicable — this source is PL/SQL only; no T-SQL
`TRY/CATCH` or severity-20+ construct exists to evaluate.

---

## 5. Dialect Footguns & Hidden Risks

**Scratch file `findings.tsv` (32 rows, materialized before this section) — category breakdown:**

```
$ awk -F'|' '{print $1}' findings.tsv | sort | uniq -c
      5 CONSTRAINT_LOGIC
     12 GLOBAL_STATE
     11 HARDCODED_VALUE
      4 OTHER
```

### SECURITY_CONTEXT

```
$ grep -nE 'AUTHID' sql/*
(no output)
```

No `AUTHID` clause appears anywhere in the source. Every routine in this system therefore runs
under Oracle's implicit default, `AUTHID DEFINER` — no explicit security-context boundary is
declared to preserve, but the implicit default itself is still a fact extraction must replicate
(the routines run with the privileges of their schema owner, not the caller). Stated explicitly as
empty per Hard Constraint 5.

### NULL_SEMANTICS

```
$ grep -nE "NVL|COALESCE|ISNULL|''" sql/*
(no output)
```

No `NVL`/`COALESCE`/`ISNULL` call and no `''` literal appears anywhere in the source. Stated
explicitly as empty.

### HARDCODED_VALUE

```
$ grep -nE ':=[[:space:]]*[0-9]+\.[0-9]+|:=[[:space:]]*[0-9]+;|>[[:space:]]*[0-9]+[[:space:]]*THEN|SYSDATE[[:space:]]*-[[:space:]]*[0-9]+|\*[[:space:]]*0\.[0-9]+' 04-prc_apply_rate_rules.sql 06-prc_purge_stale_holds.sql 07-fn_trip_surcharge.sql
06-prc_purge_stale_holds.sql:6:   WHERE created_ts < SYSDATE - 90;
04-prc_apply_rate_rules.sql:14:  v_zone_mult  NUMBER := 1;
04-prc_apply_rate_rules.sql:15:  v_tier_adj   NUMBER := 0;
04-prc_apply_rate_rules.sql:32:      p_out_rate := 0;
04-prc_apply_rate_rules.sql:35:      v_tier_adj := 0.5;
04-prc_apply_rate_rules.sql:38:    p_out_rate := 0;
04-prc_apply_rate_rules.sql:41:    v_tier_adj := 0.25;
04-prc_apply_rate_rules.sql:43:    v_tier_adj := 0;
04-prc_apply_rate_rules.sql:48:      v_zone_mult := 1.35;
04-prc_apply_rate_rules.sql:50:      v_zone_mult := 0.90;
04-prc_apply_rate_rules.sql:52:      v_zone_mult := 1.75;
04-prc_apply_rate_rules.sql:54:      v_zone_mult := 1.00;
04-prc_apply_rate_rules.sql:64:                               WHEN p_out_rate > 5 THEN 1.50
04-prc_apply_rate_rules.sql:65:                               WHEN p_out_rate > 2 THEN 0.75
04-prc_apply_rate_rules.sql:70:    p_out_rate := 0;
07-fn_trip_surcharge.sql:11:           WHEN 'URBAN'   THEN v_miles * 0.10
07-fn_trip_surcharge.sql:12:           WHEN 'AIRPORT' THEN v_miles * 0.20
```

Neutral initializers (`14, 15, 32, 38, 43, 70` — variables set to `0`/`1` as starting state, not a
business rate) are excluded from the findings below. The remaining hits are business constants —
pricing policy — embedded directly as procedural literals rather than externalized to `rate_rules`
or configuration, matching the dialect reference's "business constants (rates, thresholds,
limits)" class:

| Category | Object | File:Line | Evidence | Severity |
|---|---|---|---|---|
| HARDCODED_VALUE | `prc_purge_stale_holds` | 06:6 | `WHERE created_ts < SYSDATE - 90;` | MEDIUM |
| HARDCODED_VALUE | `prc_apply_rate_rules` | 04:35 | `v_tier_adj := 0.5;` (HOLD-past-due tier adjustment) | MEDIUM |
| HARDCODED_VALUE | `prc_apply_rate_rules` | 04:41 | `v_tier_adj := 0.25;` (PENDING tier adjustment) | MEDIUM |
| HARDCODED_VALUE | `prc_apply_rate_rules` | 04:48 | `v_zone_mult := 1.35;` (URBAN multiplier) | HIGH |
| HARDCODED_VALUE | `prc_apply_rate_rules` | 04:50 | `v_zone_mult := 0.90;` (RURAL multiplier) | HIGH |
| HARDCODED_VALUE | `prc_apply_rate_rules` | 04:52 | `v_zone_mult := 1.75;` (AIRPORT multiplier) | HIGH |
| HARDCODED_VALUE | `prc_apply_rate_rules` | 04:54 | `v_zone_mult := 1.00;` (default multiplier) | HIGH |
| HARDCODED_VALUE | `prc_apply_rate_rules` | 04:64 | `WHEN p_out_rate > 5 THEN 1.50` (surcharge threshold + amount) | MEDIUM |
| HARDCODED_VALUE | `prc_apply_rate_rules` | 04:65 | `WHEN p_out_rate > 2 THEN 0.75` (surcharge threshold + amount) | MEDIUM |
| HARDCODED_VALUE | `fn_trip_surcharge` | 07:11 | `WHEN 'URBAN'   THEN v_miles * 0.10` (URBAN surcharge rate) | MEDIUM |
| HARDCODED_VALUE | `fn_trip_surcharge` | 07:12 | `WHEN 'AIRPORT' THEN v_miles * 0.20` (AIRPORT surcharge rate) | MEDIUM |

Note: `rate_rules` (a table, `01:35-41`) already externalizes `base_rate`/`surcharge_pct` by
`class_code`/`zone_code` — the zone multipliers and tier adjustments above are a *second*,
un-externalized pricing layer applied on top of that table's values, entirely inside
`prc_apply_rate_rules`'s procedural logic. Each parameter/reference here is a literal embedded in
the source, not a caller-supplied value — none of these are excluded under the
parameterized-value rule.

### CONSTRAINT_LOGIC

```
$ grep -nE 'DEFAULT |CHECK[[:space:]]*\(' sql/*.sql
01-schema.sql:10:  status        VARCHAR2(12) DEFAULT 'ACTIVE' NOT NULL,
01-schema.sql:28:  miles         NUMBER(9,2)  DEFAULT 0 NOT NULL,
01-schema.sql:29:  trip_date     DATE         DEFAULT SYSDATE NOT NULL,
01-schema.sql:30:  settled_flag  VARCHAR2(1)  DEFAULT 'N' NOT NULL,
01-schema.sql:39:  surcharge_pct NUMBER(5,2)  DEFAULT 0 NOT NULL,
01-schema.sql:47:  amount        NUMBER(11,2) DEFAULT 0 NOT NULL,
01-schema.sql:55:  run_ts        DATE         DEFAULT SYSDATE NOT NULL,
01-schema.sql:56:  total_amount  NUMBER(13,2) DEFAULT 0 NOT NULL,
01-schema.sql:63:  created_ts    DATE         DEFAULT SYSDATE NOT NULL,
```

No `CHECK` constraint exists anywhere in the DDL. Numeric zero-value defaults (`28, 39, 47, 56`)
are neutral and excluded below. The remaining `DEFAULT` clauses carry business/audit logic in the
DDL layer — DB-side rules that must move to application validation/initialization:

| Category | Object | File:Line | Evidence | Severity |
|---|---|---|---|---|
| CONSTRAINT_LOGIC | `drivers` | 01:10 | `status VARCHAR2(12) DEFAULT 'ACTIVE' NOT NULL,` (new drivers default to ACTIVE) | LOW |
| CONSTRAINT_LOGIC | `trips` | 01:29 | `trip_date DATE DEFAULT SYSDATE NOT NULL,` (audit timestamp defaulted in DDL) | MEDIUM |
| CONSTRAINT_LOGIC | `trips` | 01:30 | `settled_flag VARCHAR2(1) DEFAULT 'N' NOT NULL,` (new trips default to unsettled) | LOW |
| CONSTRAINT_LOGIC | `settlement_batches` | 01:55 | `run_ts DATE DEFAULT SYSDATE NOT NULL,` (audit timestamp defaulted in DDL) | MEDIUM |
| CONSTRAINT_LOGIC | `driver_holds` | 01:63 | `created_ts DATE DEFAULT SYSDATE NOT NULL,` (audit timestamp defaulted in DDL) | MEDIUM |

The three `DEFAULT SYSDATE` columns are a migration-relevant footgun in their own right (see the
dialect reference's `SYSDATE`-re-evaluates-per-call note): a naive port to a target where `now()`
freezes per transaction (PostgreSQL) will silently collapse per-row timestamp values that Oracle
would have varied row to row in a multi-row insert.

### GLOBAL_STATE

Package-level state was located by REGION, not by naming convention, per the dialect reference's
STEP 1/STEP 2 procedure:

```
$ awk 'toupper($0) ~ /^[[:space:]]*CREATE[[:space:]]+(OR[[:space:]]+REPLACE[[:space:]]+)?PACKAGE/ {inpkg=1}
       inpkg && toupper($0) ~ /^[[:space:]]*(PROCEDURE|FUNCTION)[[:space:]]/ {inpkg=0}
       inpkg {print FILENAME":"FNR": "$0}' sql/*.pks sql/*.pkb
02-pkg_fleet_billing.pks:1: CREATE OR REPLACE PACKAGE pkg_fleet_billing AS
02-pkg_fleet_billing.pks:4:  TYPE t_charge_cur IS REF CURSOR;
03-pkg_fleet_billing.pkb:1: CREATE OR REPLACE PACKAGE BODY pkg_fleet_billing AS
03-pkg_fleet_billing.pkb:5:  g_run_total      NUMBER := 0;
03-pkg_fleet_billing.pkb:6:  g_batch_id       NUMBER := 0;
03-pkg_fleet_billing.pkb:7:  g_last_driver_id NUMBER;
```

Three package-level variables declared in the body's declaration region: `g_run_total`,
`g_batch_id`, `g_last_driver_id`. Every read/write site for each was then found by name:

```
$ grep -nE '\b(g_run_total|g_batch_id|g_last_driver_id)\b' sql/*.pks sql/*.pkb
03-pkg_fleet_billing.pkb:5:  g_run_total      NUMBER := 0;
03-pkg_fleet_billing.pkb:6:  g_batch_id       NUMBER := 0;
03-pkg_fleet_billing.pkb:7:  g_last_driver_id NUMBER;
03-pkg_fleet_billing.pkb:18:    g_last_driver_id := p_driver.driver_id;
03-pkg_fleet_billing.pkb:19:    g_run_total      := 0;
03-pkg_fleet_billing.pkb:45:    g_batch_id  := p_batch_id;
03-pkg_fleet_billing.pkb:46:    g_run_total := 0;
03-pkg_fleet_billing.pkb:49:      g_run_total := g_run_total + r.amount;
03-pkg_fleet_billing.pkb:57:       SET total_amount = g_run_total
```

```
$ grep -niE 'CREATE[[:space:]]+GLOBAL[[:space:]]+TEMPORARY[[:space:]]+TABLE|ON[[:space:]]+COMMIT[[:space:]]+(DELETE|PRESERVE)[[:space:]]+ROWS|\b(TEMP|TMP)_[A-Za-z0-9_]+' sql/*
01-schema.sql:68:CREATE GLOBAL TEMPORARY TABLE tmp_settlement_stage (
01-schema.sql:73:) ON COMMIT PRESERVE ROWS;
05-prc_settlement_sweep.sql:36:        INSERT INTO tmp_settlement_stage (batch_id, vehicle_id, trip_id, amount)
05-prc_settlement_sweep.sql:29 (already cited above; no additional TEMP_/TMP_ hit beyond the GTT itself)
03-pkg_fleet_billing.pkb:42:        FROM tmp_settlement_stage
```

```
$ grep -nE 'SYS_CONTEXT|DBMS_SESSION|USERENV' sql/*
04-prc_apply_rate_rules.sql:17:  v_region := SYS_CONTEXT('fleet_ctx', 'region_code');
04-prc_apply_rate_rules.sql:58:    v_region := SYS_CONTEXT('userenv', 'client_identifier');
03-pkg_fleet_billing.pkb:16:    v_region := SYS_CONTEXT('fleet_ctx', 'region_code');
```

```
$ grep -niE '\.NEXTVAL|\.CURRVAL|CREATE[[:space:]]+SEQUENCE' sql/*
01-schema.sql:75:CREATE SEQUENCE seq_settlement_batch START WITH 1000 INCREMENT BY 1 NOCACHE;
05-prc_settlement_sweep.sql:22:  SELECT seq_settlement_batch.NEXTVAL INTO v_batch_id FROM dual;
```

**`findings.tsv` GLOBAL_STATE rows (one row per object per resource, per the required granularity
— never one merged row per resource):**

```
GLOBAL_STATE|production|pkg_fleet_billing.load_driver_batch|03-pkg_fleet_billing.pkb:19|g_run_total      := 0;|HIGH
GLOBAL_STATE|production|pkg_fleet_billing.post_batch_totals|03-pkg_fleet_billing.pkb:46|g_run_total := 0;|HIGH
GLOBAL_STATE|production|pkg_fleet_billing.post_batch_totals|03-pkg_fleet_billing.pkb:49|g_run_total := g_run_total + r.amount;|HIGH
GLOBAL_STATE|production|pkg_fleet_billing.post_batch_totals|03-pkg_fleet_billing.pkb:57|SET total_amount = g_run_total|HIGH
GLOBAL_STATE|production|pkg_fleet_billing.post_batch_totals|03-pkg_fleet_billing.pkb:45|g_batch_id  := p_batch_id;|MEDIUM
GLOBAL_STATE|production|pkg_fleet_billing.load_driver_batch|03-pkg_fleet_billing.pkb:18|g_last_driver_id := p_driver.driver_id;|MEDIUM
GLOBAL_STATE|production|prc_settlement_sweep|05-prc_settlement_sweep.sql:36|INSERT INTO tmp_settlement_stage (...)|HIGH
GLOBAL_STATE|production|pkg_fleet_billing.post_batch_totals|03-pkg_fleet_billing.pkb:42|FROM tmp_settlement_stage|HIGH
GLOBAL_STATE|production|prc_apply_rate_rules|04-prc_apply_rate_rules.sql:17|SYS_CONTEXT('fleet_ctx', 'region_code')|MEDIUM
GLOBAL_STATE|production|prc_apply_rate_rules|04-prc_apply_rate_rules.sql:58|SYS_CONTEXT('userenv', 'client_identifier')|MEDIUM
GLOBAL_STATE|production|pkg_fleet_billing.load_driver_batch|03-pkg_fleet_billing.pkb:16|SYS_CONTEXT('fleet_ctx', 'region_code')|MEDIUM
GLOBAL_STATE|production|prc_settlement_sweep|05-prc_settlement_sweep.sql:22|SELECT seq_settlement_batch.NEXTVAL INTO v_batch_id FROM dual;|LOW
```

**GLOBAL_STATE findings, summarized as shared-state facts (each derived by joining the rows above
on their shared resource):**

| # | Resource | Kind | Written by | Read by | Citations |
|---|---|---|---|---|---|
| G1 | `g_run_total` | Package variable | **both** `load_driver_batch` (03:19) and `post_batch_totals` (03:46, 03:49) | `post_batch_totals` (03:49, 03:57) | declared 03:5; as cited |
| G2 | `g_batch_id` | Package variable | `post_batch_totals` only (03:45) | — (no read site found) | declared 03:6; written 03:45 |
| G2 | `g_last_driver_id` | Package variable | `load_driver_batch` only (03:18) | — (no read site found) | declared 03:7; written 03:18 |
| G3 | `tmp_settlement_stage` | Global temporary table | `prc_settlement_sweep` (INSERT, 05:36) | `pkg_fleet_billing.post_batch_totals` (SELECT via `c_staged`, 03:42) | defined 01:68, `ON COMMIT PRESERVE ROWS` |
| G4 | `SYS_CONTEXT` | Ambient session state | — (read-only construct) | `prc_apply_rate_rules` ×2 (04:17, 04:58), `load_driver_batch` ×1 (03:16) | as cited — 3 occurrences across 2 distinct objects |
| G5 | `seq_settlement_batch` | Sequence | — (`NEXTVAL` is a read-and-advance, not a write in the CRUD sense) | `prc_settlement_sweep` only (05:22, `NEXTVAL`) | defined 01:75 |

**Cluster implication (the fact a migration planner needs):** `g_run_total` (G1) directly couples
`load_driver_batch` and `post_batch_totals`. `tmp_settlement_stage` (G3) directly couples
`prc_settlement_sweep` and `post_batch_totals`. Because `post_batch_totals` appears in both
couplings, **all three routines — `load_driver_batch`, `post_batch_totals`, `prc_settlement_sweep`
— form one transitively-connected shared-state cluster**, even though the only static call edge in
the entire system (`prc_settlement_sweep` → `prc_apply_rate_rules`) touches none of them as a pair.
`g_batch_id` and `g_last_driver_id` (G2) each have exactly one writer and no found reader — weaker
findings, recorded with their single writer named. `SYS_CONTEXT` (G4) is read-only ambient state
set by something outside these files, touching 2 objects. `seq_settlement_batch` (G5) has exactly
one consumer.

### OTHER

| Category | Object | File:Line | Evidence | Severity |
|---|---|---|---|---|
| OTHER | `prc_settlement_sweep` | 05:45-47 | `EXCEPTION WHEN OTHERS THEN NULL;` | CRITICAL |
| OTHER | `prc_settlement_sweep` | 05:1-4, 44 | `p_out_batch_id OUT NUMBER` assigned at line 44, after the loop the swallow wraps and before the swallow itself — no `NOCOPY`, so copy-out is lost on any exception raised before line 44 | CRITICAL |
| OTHER | `prc_apply_rate_rules` | 04:19-22 | `SELECT status, hold_until INTO v_status, v_hold_until FROM drivers WHERE driver_id = p_driver_id;` — raises `NO_DATA_FOUND` if `p_driver_id` has no matching row; not locally caught, propagates to caller | HIGH |
| OTHER | `pkg_fleet_billing` (package body) | 03:3-7 | Package-level state declared once in the session-scoped declaration region; survives for the life of the DB connection, not the logical request — connection-pool leak hazard per the dialect reference | HIGH |

Every footgun claim in this section is a `findings.tsv` row transcribed above; every production row
appears here (the file has 32 rows total: 12 `GLOBAL_STATE`, 5 `CONSTRAINT_LOGIC`, 11
`HARDCODED_VALUE`, 4 `OTHER` — matching the category breakdown at the top of this dimension). No
`SECURITY_CONTEXT` or `NULL_SEMANTICS` row exists because both search classes returned empty
output, shown above.

---

## Confidence & Coverage Declaration

- **Files analyzed:** 7 of 7 provided (`find ... | wc -l` → 7; all `.sql`/`.pks`/`.pkb` files
  present in `tests/sproc-metrics/xraytest1/sql/`)
- **Artifact types covered:** Stored procedures (5: 3 standalone + 2 packaged), scalar functions
  (1), DDL/table schemas (8: 7 permanent tables + 1 global temporary table), packages (1, spec +
  body) — from the Context Intake table. Table-valued functions, triggers, views, jobs/scheduled
  tasks, and test scripts were searched for and confirmed absent (0 each).
- **Missing artifacts affecting analysis:** No full DDL export with `CHECK` constraints, indexes,
  or grants — only `CREATE TABLE` bodies. No trigger, view, or job-scheduler definitions exist in
  the source (confirmed absent, not merely undocumented). No runtime execution-statistics export
  was supplied.
- **Encoding/format issues encountered:** None. All 7 files are `ASCII text` (via `file`), zero CR
  bytes in any file (LF-only line endings), no non-English comments encountered.
- **Path mismatches:** None. The README's `Layout` section names all 7 `sql/` files with an
  accurate one-line description of each; all 7 were independently verified present with matching
  content (see Documentation Check in Dimension 1).

---

## Recommended Next Steps

- **Downstream planner:** the `sproc-migration-plan` skill consumes this report — specifically the
  `### Extraction Metrics` table in Dimension 1 and the `GLOBAL_STATE` rows in Dimension 5 — to
  sequence and size the extraction. Hand it the path to this file.
- **Optional runtime evidence pack:** static source cannot show call frequency, row volumes, or
  which routines are actually invoked in production. No execution-statistics export (Oracle AWR /
  `v$sql`) was provided alongside this analysis — its absence is stated here explicitly, not
  implied. If one becomes available, it would materially sharpen the Dead/Orphan Code findings in
  Dimension 1: 5 of this system's 6 routines currently have no caller found in the analyzed
  source, and a runtime pack is the only way to distinguish an externally-invoked entry point from
  genuinely dead code without access to the application/scheduler source.
