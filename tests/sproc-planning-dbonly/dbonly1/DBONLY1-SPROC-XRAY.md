# Database Stored Procedure X-Ray — DBONLY1

## Executive Summary — Critical Red Flags

- **[HIGH]** Trigger cascade chain not in application code: UPDATE orders → trg_order_status_audit → prc_finalize_order → fn_calculate_tax (trg_order_status_audit.sql:5, :12, prc_finalize_order.sql:14)
- **[MEDIUM]** GLOBAL_STATE coupling forces migration-wave cluster: prc_finalize_order and prc_reset_batch_totals share pkg_order_state.g_batch_total — must migrate together (prc_finalize_order.sql:18, prc_reset_batch_totals.sql:8,14)
- **[MEDIUM]** Hardcoded business constants: discount tiers (20%, 10%, 5%) in fn_calculate_discount (fn_calculate_discount.sql:10,12,14) and tax rate (8%) in trg_order_status_audit (trg_order_status_audit.sql:8) — must externalize to config before extraction
- **[LOW]** Defective unreferenced function: fn_check_inventory_status returns uninitialized variable — confirmed dead, safe to exclude from migration (fn_check_inventory_status.sql:13)

---

## Coverage Declaration

- **Objects provided:** 9 objects across 9 files (1 package, 5 functions, 2 procedures, 1 trigger)
- **Objects referenced but missing:** 1 (orders table — referenced by trg_order_status_audit.sql:5 but no CREATE TABLE in source)
- **Estimated coverage:** 90% of referenced objects analyzed (computed: 9 / (9 + 1))
- **Reduced-confidence dimensions:** None — no dynamic SQL detected in the analyzed source; Dimension 2's dynamic-SQL confidence flagging is unexercised in this analysis
- **Key gaps:** Table schemas incomplete — trigger references `orders` table but no DDL provided; only stored logic analyzed

---

## 1. Inventory & Completeness

### Context Intake

**Encoding and line-ending detection:**
All source files are ASCII text with LF line endings (verified via `file` command).

**Artifact types found and missing:**

| Artifact Type | Extensions | Found? | Count |
|---------------|-----------|--------|-------|
| Stored procedures | `.sql`, CREATE PROCEDURE | Yes | 2 |
| Scalar functions | `.sql`, CREATE FUNCTION | Yes | 5 |
| Table-valued functions | `.sql`, CREATE FUNCTION RETURNS TABLE | No | 0 |
| Triggers | `.sql`, CREATE TRIGGER | Yes | 1 |
| Views (with logic) | `.sql`, CREATE VIEW | No | 0 |
| DDL / table schemas | `.sql`, CREATE TABLE, `.ddl` | No | 0 |
| Jobs / scheduled tasks | `.sql`, CREATE JOB, SQL Agent | No | 0 |
| Packages (Oracle) | `.pks`, `.pkb`, CREATE PACKAGE | Yes | 1 |
| Test scripts | `*Test*.sql`, `*_test.sql` | Yes | 3 |

**Total files analyzed:** 12 SQL files found
- **Production files:** 9
- **Test files:** 3 (excluded from production analysis, listed below)

**Test scripts identified and excluded from production counts:**
1. fn_calculate_discount-Test.sql
2. fn_format_order_number-Test.sql
3. fn_validate_postal_code-Test.sql

### Component Manifest

Production objects only (test scripts excluded):

| Type | Object Name | File | LOC | Notable Flags |
|------|------------|------|-----|---------------|
| Package | pkg_order_state | pkg_order_state.sql | 8 | Shared-state resource (2 writers) |
| Function | fn_calculate_discount | fn_calculate_discount.sql | 21 | Possibly dead — test caller only |
| Function | fn_calculate_tax | fn_calculate_tax.sql | 13 | Confirmed live — called by prc_finalize_order |
| Function | fn_check_inventory_status | fn_check_inventory_status.sql | 16 | Confirmed dead — defective, no callers |
| Function | fn_format_order_number | fn_format_order_number.sql | 12 | Possibly dead — test caller only |
| Function | fn_validate_postal_code | fn_validate_postal_code.sql | 17 | Possibly dead — test caller only |
| Procedure | prc_finalize_order | prc_finalize_order.sql | 23 | Confirmed live — trigger entry point |
| Procedure | prc_reset_batch_totals | prc_reset_batch_totals.sql | 17 | Possibly dead — no caller found |
| Trigger | trg_order_status_audit | trg_order_status_audit.sql | 15 | Entry point — fires on UPDATE orders |

**Subtotal — Packages:** 1 object, 8 LOC
**Subtotal — Functions:** 5 objects, 79 LOC
**Subtotal — Procedures:** 2 objects, 40 LOC
**Subtotal — Triggers:** 1 object, 15 LOC

**Grand total:** 9 objects (= 1 + 5 + 2 + 1), 142 LOC (= 8 + 79 + 40 + 15)

**Test scripts (excluded from production analysis):** 3 files, 39 LOC

### Missing-Reference Table

| Source File:Line | Reference Type | Target | Impact |
|-----------------|---------------|--------|--------|
| trg_order_status_audit.sql:5 | UPDATE trigger base table | orders | Table definition not in source — trigger firing condition unknowable without schema |

### Coverage Honesty Check

Analysis covers 9 of 10 referenced objects (90% coverage). 1 object referenced but not defined: `orders` (table — trigger base table, no CREATE TABLE in source).

### Dead / Orphan Code

**Confirmed dead — no caller found anywhere (1 object):**

| Object | Type | File | Evidence |
|--------|------|------|----------|
| fn_check_inventory_status | Function | fn_check_inventory_status.sql | No caller in analyzed source; defective (returns uninitialized variable `v_status` at :13); no test script |

**Possibly dead — insufficient evidence (3 objects):**

These objects have test scripts but no production callers found in the analyzed source. They may be called from application code not provided.

| Object | Type | File | Test Script Present? | Reason for uncertainty |
|--------|------|------|---------------------|----------------------|
| fn_calculate_discount | Function | fn_calculate_discount.sql | Yes (fn_calculate_discount-Test.sql) | No caller in production SQL; may be app-called |
| fn_format_order_number | Function | fn_format_order_number.sql | Yes (fn_format_order_number-Test.sql) | No caller in production SQL; may be app-called |
| fn_validate_postal_code | Function | fn_validate_postal_code.sql | Yes (fn_validate_postal_code-Test.sql) | No caller in production SQL; may be app-called |

**Additional possibly-dead object:**

| Object | Type | File | Evidence |
|--------|------|------|----------|
| prc_reset_batch_totals | Procedure | prc_reset_batch_totals.sql | No caller found in analyzed source; shares global state with prc_finalize_order (Dimension 5); may be app-called or scheduled job |

**Confirmed live objects:** 4 of 9 (fn_calculate_tax, prc_finalize_order, trg_order_status_audit, pkg_order_state)

### Extraction Metrics

One row per routine and trigger DEFINED in the source: the 5 functions, 2 procedures, and 1 trigger. `pkg_order_state` is a package SPEC that declares only state (no nested procedure or function), so it contributes no packaged routine and no row here. Every number below is computed by command; the raw output sits in the proof blocks and the count is the length of the hit list after the named exclusions.

**Scratch file (`metrics.tsv`) materialized first** (`Object|Params|CursorLoops|Branches|UDTFlags|File|LOC`):

```
fn_calculate_discount|1|0|3|none|fn_calculate_discount.sql|19
fn_calculate_tax|2|0|0|none|fn_calculate_tax.sql|11
fn_check_inventory_status|1|0|0|none|fn_check_inventory_status.sql|13
fn_format_order_number|1|0|0|none|fn_format_order_number.sql|10
fn_validate_postal_code|1|0|1|none|fn_validate_postal_code.sql|15
prc_finalize_order|3|0|0|none|prc_finalize_order.sql|19
prc_reset_batch_totals|0|0|0|none|prc_reset_batch_totals.sql|14
trg_order_status_audit|0|0|1|none|trg_order_status_audit.sql|11
```

**Params — detection command and raw output:**

```
$ grep -nE '^[[:space:]]*(CREATE[[:space:]]+(OR[[:space:]]+REPLACE[[:space:]]+)?)?(PROCEDURE|FUNCTION|TRIGGER)[[:space:]]+[A-Za-z_][A-Za-z0-9_$#]*' sql/*.sql | grep -v Test.sql
sql/fn_calculate_discount.sql:3:CREATE OR REPLACE FUNCTION fn_calculate_discount(
sql/fn_calculate_tax.sql:3:CREATE OR REPLACE FUNCTION fn_calculate_tax(
sql/trg_order_status_audit.sql:4:CREATE OR REPLACE TRIGGER trg_order_status_audit
sql/fn_check_inventory_status.sql:4:CREATE OR REPLACE FUNCTION fn_check_inventory_status(
sql/fn_format_order_number.sql:3:CREATE OR REPLACE FUNCTION fn_format_order_number(
sql/fn_validate_postal_code.sql:3:CREATE OR REPLACE FUNCTION fn_validate_postal_code(
sql/prc_finalize_order.sql:5:CREATE OR REPLACE PROCEDURE prc_finalize_order(
sql/prc_reset_batch_totals.sql:4:CREATE OR REPLACE PROCEDURE prc_reset_batch_totals IS
```

Each banner's parameter list was read through its closing `)`: `fn_calculate_discount(:3-5)` = `p_tier_level` = 1; `fn_calculate_tax(:3-6)` = `p_amount, p_tax_rate` = 2 (its `RETURN NUMBER` at :6 is the return type, not a parameter); `fn_check_inventory_status(:4-6)` = `p_product_id` = 1; `fn_format_order_number(:3-5)` = `p_order_id` = 1; `fn_validate_postal_code(:3-5)` = `p_postal_code` = 1; `prc_finalize_order(:5-9)` = `p_order_id, p_amount, p_tax_rate` = 3; `prc_reset_batch_totals(:4)` has no parenthesized list at all = 0 (written as `0`, not blank). `trg_order_status_audit` is a trigger — no formal parameter list and no signature → `Params 0` (its `:NEW`/`:OLD` pseudo-record fields are not parameters).

**Cursor Loops — detection command and raw output:**

```
$ grep -nE 'CURSOR[[:space:]]+[A-Za-z_]|FOR[[:space:]]+[A-Za-z_][A-Za-z0-9_$#]*[[:space:]]+IN[[:space:]]|OPEN[[:space:]]+|FETCH[[:space:]]+' sql/*.sql | grep -v Test.sql
(no output)
```

Zero cursor-search hits across all 8 objects — Cursor Loops is `0` for every row.

**Branches — detection command and raw output:**

```
$ grep -nEw 'IF|ELSIF|WHEN|WHILE|ELSE|EXCEPTION|EXIT' sql/*.sql | grep -v Test.sql
sql/fn_calculate_discount.sql:9:  IF p_tier_level >= 5 THEN
sql/fn_calculate_discount.sql:11:  ELSIF p_tier_level >= 3 THEN
sql/fn_calculate_discount.sql:13:  ELSIF p_tier_level >= 1 THEN
sql/fn_calculate_discount.sql:15:  ELSE
sql/fn_calculate_discount.sql:17:  END IF;
sql/fn_validate_postal_code.sql:9:  IF REGEXP_LIKE(p_postal_code, '^\d{5}(-\d{4})?$') THEN
sql/fn_validate_postal_code.sql:11:  ELSE
sql/fn_validate_postal_code.sql:13:  END IF;
sql/trg_order_status_audit.sql:10:  IF :NEW.status = 'APPROVED' AND :OLD.status != 'APPROVED' THEN
sql/trg_order_status_audit.sql:13:  END IF;
```

Counted per the fixed basis (below): `fn_calculate_discount` = `IF`(:9) + `ELSIF`(:11) + `ELSIF`(:13) = **3**; dropped `ELSE`(:15) (no condition) and the `IF` substring inside `END IF;`(:17). `fn_validate_postal_code` = `IF`(:9) = **1**; dropped `ELSE`(:11) and `END IF;`(:13). `trg_order_status_audit` = `IF`(:10) = **1**; dropped `END IF;`(:13). All other objects returned no branch hits = **0**.

**UDT Usage — detection command and raw output:**

```
$ grep -nE '%ROWTYPE|%TYPE|IS[[:space:]]+RECORD|VARRAY|IS[[:space:]]+TABLE[[:space:]]+OF|REF[[:space:]]+CURSOR|SYS_REFCURSOR' sql/*.sql | grep -v Test.sql
(no output)
```

No UDT constructs anywhere. Every function's signature returns a scalar (`NUMBER` or `VARCHAR2`) with scalar parameters; both procedures have scalar or empty parameter lists; the trigger has no signature. `UDT Usage` is the literal word `none` for every row.

**Per-routine LOC — detection command and raw output:**

Standalone routines span `CREATE [OR REPLACE]` header line → terminating `/` line (whichever of `END`/`/` is last); the trigger spans `CREATE TRIGGER` header → terminating `END` line (trailing name optional). CREATE header lines are the Params proof block above; the terminators:

```
$ grep -nE '^/[[:space:]]*$' sql/*.sql | grep -v Test.sql
sql/fn_check_inventory_status.sql:16:/
sql/fn_format_order_number.sql:12:/
sql/fn_validate_postal_code.sql:17:/
sql/pkg_order_state.sql:8:/
sql/fn_calculate_discount.sql:21:/
sql/trg_order_status_audit.sql:15:/
sql/prc_finalize_order.sql:23:/
sql/fn_calculate_tax.sql:13:/
sql/prc_reset_batch_totals.sql:17:/
$ grep -nE '^[[:space:]]*END' sql/trg_order_status_audit.sql   # trigger uses terminating END, not the '/'
13:  END IF;
14:END trg_order_status_audit;
```

Spans (`echo $((end - start + 1))`): `fn_calculate_discount` :3→:21 = 19; `fn_calculate_tax` :3→:13 = 11; `fn_check_inventory_status` :4→:16 = 13; `fn_format_order_number` :3→:12 = 10; `fn_validate_postal_code` :3→:17 = 15; `prc_finalize_order` :5→:23 = 19; `prc_reset_batch_totals` :4→:17 = 14; `trg_order_status_audit` :4→:14 (terminating `END`) = 11. `pkg_order_state.sql:8:/` is the package terminator, not a routine, and takes no row. These per-routine spans are a distinct measure from the Component Manifest's per-file LOC (which counts each file whole, leading comment header included); the two are never summed or reconciled — the leading `--` comment headers account for the difference.

**Rendered Extraction Metrics table** (transcribed from `metrics.tsv`):

| Object | Params | Cursor Loops | Branches | UDT Usage | File | LOC |
|--------|--------|--------------|----------|-----------|------|-----|
| fn_calculate_discount | 1 | 0 | 3 | none | fn_calculate_discount.sql | 19 |
| fn_calculate_tax | 2 | 0 | 0 | none | fn_calculate_tax.sql | 11 |
| fn_check_inventory_status | 1 | 0 | 0 | none | fn_check_inventory_status.sql | 13 |
| fn_format_order_number | 1 | 0 | 0 | none | fn_format_order_number.sql | 10 |
| fn_validate_postal_code | 1 | 0 | 1 | none | fn_validate_postal_code.sql | 15 |
| prc_finalize_order | 3 | 0 | 0 | none | prc_finalize_order.sql | 19 |
| prc_reset_batch_totals | 0 | 0 | 0 | none | prc_reset_batch_totals.sql | 14 |
| trg_order_status_audit | 0 | 0 | 1 | none | trg_order_status_audit.sql | 11 |

**Branch-counting basis (a stated-method keyword count — NOT cyclomatic complexity):** counted are each `IF`, each `ELSIF`, each `CASE`-`WHEN` arm, each non-cursor `WHILE` head, and each non-cursor `EXIT WHEN`; NOT counted are `ELSE` arms, `EXCEPTION WHEN`/`CATCH` handlers, `FOR`/bare `LOOP` heads, `END IF`/`END CASE` terminators, a trigger's firing `WHEN` clause, and any loop test the Cursor Loops column already owns. These are raw counts with citations, not complexity bands, risk ratings, or effort estimates.

---

## 2. Call & Dependency Graph

### Dependency Graph

Entry points (triggers and top-level procedures with no in-database callers):

```
trg_order_status_audit (trigger on UPDATE orders)
  └─> prc_finalize_order (:12)
       └─> fn_calculate_tax (:14)

[Orphaned — no callers found in analyzed source:]
prc_reset_batch_totals (possible external/application caller)
fn_calculate_discount (test script only)
fn_format_order_number (test script only)
fn_validate_postal_code (test script only)
fn_check_inventory_status (defective, confirmed dead)
```

**Call edges (materialized in calls.tsv):**
```
trg_order_status_audit|prc_finalize_order|trg_order_status_audit.sql:12
prc_finalize_order|fn_calculate_tax|prc_finalize_order.sql:14
```

### Liveness Claims with Citations

- **trg_order_status_audit** — confirmed live (trigger entry point, fires on external DML)
- **prc_finalize_order** — confirmed live (called by trg_order_status_audit at trg_order_status_audit.sql:12)
- **fn_calculate_tax** — confirmed live (called by prc_finalize_order at prc_finalize_order.sql:14)
- **pkg_order_state** — confirmed live (written by prc_finalize_order at prc_finalize_order.sql:18; read/written by prc_reset_batch_totals at prc_reset_batch_totals.sql:8,14,15)
- **prc_reset_batch_totals** — no caller found in analyzed source (possible external/application caller — unknowable from source alone)
- **fn_calculate_discount** — no caller found in production source (test caller only: fn_calculate_discount-Test.sql)
- **fn_format_order_number** — no caller found in production source (test caller only: fn_format_order_number-Test.sql)
- **fn_validate_postal_code** — no caller found in production source (test caller only: fn_validate_postal_code-Test.sql)
- **fn_check_inventory_status** — no caller found anywhere (confirmed dead)

### Hub Objects

Hub threshold: 3+ invocation edges (calls, not table DML).

Computed from calls.tsv:
```bash
awk -F'|' '{print $2}' calls.tsv | sort | uniq -c
```
Output:
```
1 fn_calculate_tax
1 prc_finalize_order
```

**Result:** No hub objects in the call graph — no object reaches 3+ callers or 3+ callees on invocation edges.

### External / Unresolvable Edges

No external system procedures (`sp_*`, `xp_*`, `DBMS_*` beyond standard Oracle built-ins) found in analyzed source.

### Extraction Sequencing

Based on the dependency graph, extract in this order:

1. **Leaf functions** with no dependencies (fn_calculate_discount, fn_format_order_number, fn_validate_postal_code, fn_check_inventory_status) — but note: first 3 are possibly-dead and need caller confirmation; last is confirmed dead and can be excluded
2. **Helper function** fn_calculate_tax (called only by prc_finalize_order, no dependencies of its own)
3. **Mid-tier procedure** prc_finalize_order and **shared-state procedure** prc_reset_batch_totals — these MUST migrate together as a cluster (see Dimension 5)
4. **Trigger** trg_order_status_audit (always last — reimplemented in application code at the DML site)

---

## 3. CRUD Matrix & Trigger Cascade Map

### CRUD Matrix (scratch file: crud.tsv, 4 rows)

| Object | Resource | Type | C | R | U | D | Access Pattern | File:Line |
|--------|----------|------|---|---|---|---|----------------|-----------|
| trg_order_status_audit | orders | Table | | X | | | UPDATE trigger base table | trg_order_status_audit.sql:5 |
| prc_finalize_order | pkg_order_state.g_batch_total | Package Variable | | X | X | | read and write | prc_finalize_order.sql:18 |
| prc_reset_batch_totals | pkg_order_state.g_batch_total | Package Variable | | X | X | | read and write | prc_reset_batch_totals.sql:8,14 |
| prc_reset_batch_totals | pkg_order_state.g_current_batch_id | Package Variable | | X | X | | read and write | prc_reset_batch_totals.sql:15 |

### Resource Touch Tally

Computed from crud.tsv:
```bash
awk -F'|' '{print $2, $1}' crud.tsv | sort -u | awk '{c[$1" "$2]++; r[$1]++} END {for (res in r) print res, r[res], (r[res] >= 3 ? "yes" : "no")}'
```
Output:
```
orders 1 no
pkg_order_state.g_batch_total 2 no
pkg_order_state.g_current_batch_id 1 no
```

| Resource | Distinct objects touching | Hub? (3+) |
|----------|--------------------------|-----------|
| orders | 1 | no |
| pkg_order_state.g_batch_total | 2 | no |
| pkg_order_state.g_current_batch_id | 1 | no |

**Hub resources (3+ objects touching):** None. No resource reaches the 3+ threshold.

### Trigger Cascade Map

**Cascade chain (end-to-end):**

```
UPDATE orders (external DML — not in analyzed source)
  → TRIGGER trg_order_status_audit (:5)
     → EXEC prc_finalize_order (:12)
        → CALL fn_calculate_tax (:14)
           → [terminates — fn_calculate_tax has no further calls]
```

**Critical finding:** The application must reimplement this entire cascade chain explicitly. When the application updates an `orders` row with `status = 'APPROVED'`, it must:

1. Invoke the equivalent of `prc_finalize_order` (with the order's amount and the 8% tax rate)
2. Which calls `fn_calculate_tax` to compute the tax
3. Which writes to `pkg_order_state.g_batch_total`

The trigger will not exist post-extraction, so this behavior must be moved to the application's UPDATE call site.

**Missing table schema:** The `orders` table is referenced at trg_order_status_audit.sql:5 but no CREATE TABLE definition exists in the analyzed source. The trigger firing condition (`UPDATE OF status`) and the `:NEW.order_id`, `:NEW.amount`, `:NEW.status` column references cannot be fully validated without the schema.

---

## 4. Transaction & Error-Handling Semantics

### Transaction Boundaries

**No explicit transaction control found in analyzed source.** No `COMMIT`, `ROLLBACK`, `SAVEPOINT`, or `PRAGMA AUTONOMOUS_TRANSACTION` statements detected in any of the 9 production objects.

All operations run in the caller's transaction context (trigger inherits the UPDATE transaction; procedures inherit the caller's transaction if invoked from application code).

### Error Swallowing

**No error swallowing detected.** No `EXCEPTION WHEN OTHERS THEN NULL` or `EXCEPTION WHEN OTHERS THEN RETURN` blocks without `RAISE` found in the analyzed source.

### Autonomous Transactions

**None detected.** No `PRAGMA AUTONOMOUS_TRANSACTION` found in analyzed source.

### Atomic Groups

Because no explicit transaction boundaries exist, atomicity is caller-controlled:

- If the application updates `orders` in a transaction, the trigger cascade (trg_order_status_audit → prc_finalize_order → fn_calculate_tax) executes atomically with that UPDATE
- If prc_reset_batch_totals is called from application code, it runs in the caller's transaction

Post-extraction, the application must decide the transaction scope for the reimplemented logic.

---

## 5. Dialect Footguns & Hidden Risks

### Findings Scratch File (findings.tsv, 4 production rows)

Search command and output:
```bash
grep -n "0\.20\|0\.10\|0\.05\|0\.08" /home/yv01p/peters-toolkit/tests/sproc-planning-dbonly/dbonly1/sql/*.sql | grep -v Test.sql
```
Output:
```
/home/yv01p/peters-toolkit/tests/sproc-planning-dbonly/dbonly1/sql/fn_calculate_discount.sql:10:    v_discount := 0.20;
/home/yv01p/peters-toolkit/tests/sproc-planning-dbonly/dbonly1/sql/fn_calculate_discount.sql:12:    v_discount := 0.10;
/home/yv01p/peters-toolkit/tests/sproc-planning-dbonly/dbonly1/sql/fn_calculate_discount.sql:14:    v_discount := 0.05;
/home/yv01p/peters-toolkit/tests/sproc-planning-dbonly/dbonly1/sql/trg_order_status_audit.sql:8:  v_tax_rate CONSTANT NUMBER := 0.08;
```

### Hardcoded Business Constants

**[MEDIUM]** fn_calculate_discount — discount tier rates hardcoded:
- 20% for tier 5+ (fn_calculate_discount.sql:10: `v_discount := 0.20;`)
- 10% for tier 3-4 (fn_calculate_discount.sql:12: `v_discount := 0.10;`)
- 5% for tier 1-2 (fn_calculate_discount.sql:14: `v_discount := 0.05;`)

**Extraction implication:** These business rules must be externalized to application configuration before extraction. If discount tiers change, the application should not require a code deployment — move to a config table or external config service.

**[MEDIUM]** trg_order_status_audit — tax rate hardcoded:
- 8% tax rate (trg_order_status_audit.sql:8: `v_tax_rate CONSTANT NUMBER := 0.08;`)

**Extraction implication:** Tax rate should be externalized to configuration. If tax rates vary by jurisdiction or change over time, hardcoding this value in the reimplemented trigger logic will require code changes.

### Shared-State Coupling (GLOBAL_STATE)

**[MEDIUM]** prc_finalize_order and prc_reset_batch_totals share package variable `pkg_order_state.g_batch_total`:

- **Written by prc_finalize_order:** prc_finalize_order.sql:18 — `pkg_order_state.g_batch_total := pkg_order_state.g_batch_total + v_total_amount;`
- **Read by prc_reset_batch_totals:** prc_reset_batch_totals.sql:8 — `v_old_total := pkg_order_state.g_batch_total;`
- **Written by prc_reset_batch_totals:** prc_reset_batch_totals.sql:14 — `pkg_order_state.g_batch_total := 0;`

**Extraction implication:** These two procedures form a **must-migrate-together cluster**. They share package-scoped state that must be replaced with application-layer state (e.g., a database-backed batch_totals record, or in-memory state if the batch lifecycle is request-scoped). Splitting them across migration waves will break the shared-state coupling.

**Additional shared variable:** `pkg_order_state.g_current_batch_id` is read and written by prc_reset_batch_totals (prc_reset_batch_totals.sql:15) but not referenced by any other object — this is single-writer state and does not force a cluster beyond prc_reset_batch_totals itself.

### Security Context Changes

**None detected.** No `AUTHID DEFINER` / `AUTHID CURRENT_USER` modifiers found in analyzed source (all routines default to `AUTHID DEFINER` in Oracle, meaning they execute with the owner's privileges).

### NULL Semantics

**No NULL-sensitive predicates or coalescing found in analyzed source.** Oracle's `'' = NULL` (empty string is NULL) semantics are not exercised in this corpus.

### Other Dialect-Specific Footguns

**Defective function — confirmed dead:** fn_check_inventory_status (fn_check_inventory_status.sql) returns an uninitialized variable:
- Line 13: `RETURN v_status;` where `v_status` is declared (line 8: `v_status VARCHAR2(20);`) but never assigned a value

This function would return NULL for all inputs, rendering it useless. No caller exists in the analyzed source, confirming it is dead code. Safe to exclude from migration.

---

## Confidence & Coverage Declaration

- **Files analyzed:** 12 of 12 provided (9 production, 3 test)
- **Artifact types covered:** Stored procedures, scalar functions, triggers, packages (Oracle), test scripts
- **Missing artifacts affecting analysis:** Table DDL (trigger base table `orders` referenced but not defined); application call sites (cannot distinguish "possibly dead" from "dead" without application source); runtime evidence pack (no execution statistics provided — cannot prioritize by usage)
- **Encoding/format issues encountered:** None — all files are ASCII text with LF line endings
- **Path mismatches:** No README or documentation provided to verify against

---

## Recommended Next Steps

1. **Obtain table DDL** — export the full schema for the `orders` table (and any other tables referenced in the reimplemented logic) to validate trigger firing conditions and column references
2. **Obtain application call-site inventory** — scan application source for calls to fn_calculate_discount, fn_format_order_number, fn_validate_postal_code, and prc_reset_batch_totals to confirm liveness (currently flagged "possibly dead — insufficient evidence")
3. **Obtain runtime evidence pack** — export execution statistics (call frequency, row volumes) to prioritize extraction by actual usage rather than static complexity
4. **Externalize hardcoded constants** — move discount tiers and tax rates to configuration before extraction
5. **Design shared-state replacement** — decide how to replace `pkg_order_state.g_batch_total` in the application layer (database-backed, in-memory, request-scoped?) before migrating the {prc_finalize_order, prc_reset_batch_totals} cluster
6. **Reimplement trigger cascade explicitly** — the UPDATE orders → trg_order_status_audit → prc_finalize_order chain must be coded into the application's order-update path

---

**Report generated:** 2026-08-18
**Dialect:** Oracle PL/SQL
**Scope:** Database-only source analysis (no application code, no runtime pack)
**System:** DBONLY1
