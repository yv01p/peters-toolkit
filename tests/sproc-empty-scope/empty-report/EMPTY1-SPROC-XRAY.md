## Executive Summary — Critical Red Flags

Ranked, cited, severity-tagged concrete hazards. NOT a score, NOT a verdict.

- **[LOW-CONF is not applicable — HIGH-CONF, directly observed]** Zero DB-resident business logic exists in the analyzed source. Parsing every `CREATE` statement in the only SQL source file yields 4 `CREATE TABLE` statements and nothing else — 0 stored procedures, 0 functions, 0 triggers, 0 views, 0 packages (`app/db/schema.sql:15,25,31,38`). See Dimension 1 (Component Manifest) and Dimension 5 (`findings.tsv`, 0 rows across all six footgun categories).
- **[LOW]** No `CHECK` constraints and no logic-bearing `DEFAULT` clauses exist on any of the 4 tables (`app/db/schema.sql:15-44`, confirmed by `grep -noiE 'CHECK\(' ` and `grep -noiE 'DEFAULT'` — the only `DEFAULT` string matches (`app/db/schema.sql:5,6`) fall inside the file's header comment block, not inside a column definition). There is no `CONSTRAINT_LOGIC` finding to migrate.
- **[LOW — documentation claim, unverified by this report]** `app/db/schema.sql:10-13` (a source comment, not a README/docs file) asserts that "Business rules for this system (reorder thresholds, discount rates, order status transitions) live entirely in the C# application layer — see `app/src/*.cs`." This skill's scope is SQL source only; the content of `app/src/*.cs` was not analyzed for correctness of that claim. A targeted grep across `app/src/*.cs` for embedded `CREATE PROCEDURE/FUNCTION/TRIGGER/VIEW` text or stored-procedure `EXEC` calls found none (0 hits), which is consistent with the claim but does not constitute analysis of the C# logic itself.

There is no trigger cascade, no error-swallowing, no security-context switch, and no hardcoded business rule to report — every dimension below returned an empty result set, and each is shown with its own zero-row proof.

---

## Coverage Declaration

This section is positioned FIRST in the report but is WRITTEN LAST: leave it for the end, after the Component Manifest and Missing-Reference Table exist, then fill it by copying their values.

- **Objects provided:** 4 objects across 1 files (Table: 4; Stored Procedure: 0; Scalar Function: 0; Table-Valued Function: 0; Trigger: 0; View: 0; Package: 0; Database: 0)
- **Objects referenced but missing:** 0 (none — the Missing-Reference Table has 0 rows)
- **Estimated coverage:** 100% of referenced objects analyzed (4 of 4; see Dimension 1 Coverage Honesty Check)
- **Reduced-confidence dimensions:** None — no dynamic SQL (`sp_executesql`, `EXEC(...)`) detected in the analyzed source (0 hits); Dimension 2's dynamic-SQL confidence flagging is unexercised in this analysis.
- **Key gaps:** No README or `docs/` files exist in the source tree to verify against. `app/src/*.cs` (4 C# files, 287 total lines: `InventoryReorderService.cs` 53, `OrderRepository.cs` 87, `ProductRepository.cs` 120, `Program.cs` 27) exist alongside the SQL source and are claimed (in a schema.sql comment) to hold all business logic, but they are application code, not SQL source, and were not analyzed under this skill's SQL-only scope. No execution-statistics / runtime evidence pack was supplied.

---

## 1. Inventory & Completeness

**Documentation check.** No `README*` file and no `docs/` directory exist anywhere under the source tree (`find <SRC> -iname "README*" -o -iname "*.md" -o -type d -iname docs` → no output). There are 0 documented path or count claims to verify. Documentation-verification table: N/A — 0 documented claims found, so no `| Claim | Documented N | Parsed M | N = M? | Verdict |` rows exist to render.

**Encoding and line-ending detection.** `file app/db/schema.sql` → `Unicode text, UTF-8 text`. `grep -c $'\r' app/db/schema.sql` → `0` (no CRLF found; LF-only line endings). No non-English comments observed. No binary DB files present (no `.mdf/.ndf/.ldf/.bak/.dbf/.dmp` extensions in the source tree).

**Context-intake table:**

| Artifact Type | Extensions | Found? | Count |
|---|---|---|---|
| Stored procedures | `.sql`, CREATE PROCEDURE | No | 0 |
| Scalar functions | `.sql`, CREATE FUNCTION RETURNS scalar | No | 0 |
| Table-valued functions | `.sql`, CREATE FUNCTION RETURNS TABLE | No | 0 |
| Triggers | `.sql`, CREATE TRIGGER, `.trg` | No | 0 |
| Views (with logic) | `.sql`, CREATE VIEW | No | 0 |
| DDL / table schemas | `.sql`, CREATE TABLE, `.ddl` | Yes | 4 |
| Jobs / scheduled tasks | `.sql`, CREATE JOB, SQL Agent | No | 0 |
| Packages (Oracle) | `.pks`, `.pkb`, CREATE PACKAGE | No | 0 (N/A — T-SQL dialect) |
| Test scripts | `*Test*.sql`, `*_test.sql` | No | 0 |
| Binary DB files (unparsed) | .mdf/.ndf/.ldf/.bak/.dbf/.dmp | No | 0 |

No test scripts were found to flag separately (`find <SRC> -iname "*test*"` → no output).

**Dialect detection:** T-SQL. Indicators found in `app/db/schema.sql`: `dbo.` schema prefixes (lines 15, 25, 31, 38), T-SQL types `NVARCHAR`, `DECIMAL`, `DATETIME2`, `INT IDENTITY(1,1)` (lines 16-22, 27-28, 33-35, 40-43), and an explicit source comment "SQL Server / T-SQL" (line 1). Loaded `references/dialects/mssql.md`.

**Glob result — SQL source files:**

```
$ find <SRC> -type f \( -iname "*.sql" -o -iname "*.ddl" -o -iname "*.prc" -o -iname "*.fnc" -o -iname "*.trg" -o -iname "*.pks" -o -iname "*.pkb" \)
app/db/schema.sql
```
1 file matched (`wc -l` on the file list → 1).

**Component Manifest.** Object counts come from parsing `CREATE` statements, not from counting files:

```
$ grep -noiE 'CREATE[[:space:]]+(OR[[:space:]]+ALTER[[:space:]]+|OR[[:space:]]+REPLACE[[:space:]]+)?(TABLE|PROCEDURE|FUNCTION|TRIGGER|VIEW|PACKAGE|DATABASE)' app/db/schema.sql
15:CREATE TABLE
25:CREATE TABLE
31:CREATE TABLE
38:CREATE TABLE
```

Per-object LOC is the object's own line span (`CREATE TABLE` header line → its closing `);` line):

```
$ grep -n '^CREATE TABLE' app/db/schema.sql
15:CREATE TABLE dbo.Products (
25:CREATE TABLE dbo.Customers (
31:CREATE TABLE dbo.Orders (
38:CREATE TABLE dbo.OrderLines (
$ grep -n '^);' app/db/schema.sql
23:);
29:);
36:);
44:);
```

| Type | Object Name | File | LOC | Notable Flags |
|------|------------|------|-----|---------------|
| Table | dbo.Products | schema.sql | 9 | No CHECK, no logic-bearing DEFAULT (lines 15-23) |
| Table | dbo.Customers | schema.sql | 5 | No CHECK, no logic-bearing DEFAULT (lines 25-29) |
| Table | dbo.Orders | schema.sql | 6 | FK → dbo.Customers (line 33); no CHECK/DEFAULT (lines 31-36) |
| Table | dbo.OrderLines | schema.sql | 7 | FK → dbo.Orders (line 40), FK → dbo.Products (line 41); no CHECK/DEFAULT (lines 38-44) |

Table subtotal: 4 objects, 27 LOC (= 9 + 5 + 6 + 7)
Stored Procedure subtotal: 0 objects, 0 LOC
Scalar Function subtotal: 0 objects, 0 LOC
Table-Valued Function subtotal: 0 objects, 0 LOC
Trigger subtotal: 0 objects, 0 LOC
View subtotal: 0 objects, 0 LOC
Package subtotal: 0 objects, 0 LOC
Database subtotal: 0 objects, 0 LOC

**Grand total: 4 objects (= 4 + 0 + 0 + 0 + 0 + 0 + 0 + 0), 27 LOC (= 27 + 0 + 0 + 0 + 0 + 0 + 0 + 0)**

(Separately, and not conflated with the grand total above per the itemized-object-LOC basis: `app/db/schema.sql` is 44 raw lines total, `wc -l` confirmed. The 17-line difference (44 − 27) is the file's header comment block (lines 1-13), one blank separator line after the header (line 14), and three blank separator lines between table definitions (lines 24, 30, 37) — none of it is object code.)

### Extraction Metrics

`metrics.tsv` was materialized first and has 0 rows (`wc -l metrics.tsv` → `0`) — there are no routines or triggers defined in the analyzed source to measure. The Extraction Metrics table therefore has no data rows:

| Object | Params | Cursor Loops | Branches | UDT Usage | File | LOC |
|--------|--------|--------------|----------|-----------|------|-----|
| *(no rows — 0 stored procedures, functions, or triggers defined in source)* | | | | | | |

Branch-counting basis (stated per the fixed output contract even though unexercised here): branches count each `IF`, `ELSIF`/`ELSEIF`, each `WHEN` arm of a `CASE`, each non-cursor `WHILE` head, and each non-cursor `EXIT WHEN`/conditional `BREAK`; `ELSE` arms, exception/`CATCH` handlers, and cursor-loop termination tests are excluded. This is a keyword count, not cyclomatic complexity — moot here since no routine bodies exist.

**Missing-Reference Table:** 0 rows. All foreign-key references resolve within the same file:

| Source File:Line | Reference Type | Target | Impact |
|---|---|---|---|
| *(none — all 3 FK references resolve to CREATE TABLE statements in schema.sql)* | | | |

Verification: `dbo.Orders.CustomerId` (`app/db/schema.sql:33`) REFERENCES `dbo.Customers(CustomerId)`, defined at `app/db/schema.sql:25`. `dbo.OrderLines.OrderId` (`app/db/schema.sql:40`) REFERENCES `dbo.Orders(OrderId)`, defined at `app/db/schema.sql:31`. `dbo.OrderLines.ProductId` (`app/db/schema.sql:41`) REFERENCES `dbo.Products(ProductId)`, defined at `app/db/schema.sql:15`. No `EXEC`, `EXECUTE`, or dynamic-SQL reference to any other object exists (`grep -noiE '\bEXEC\b|\bEXECUTE\b' app/db/schema.sql` → no hits).

**Coverage Honesty Check:** Analysis covers 4 of 4 referenced objects (100% coverage). 0 objects referenced but not defined.

**Dead / Orphan Code:** N/A. No stored procedures, functions, triggers, or views exist in source — there are no invocable database objects to evaluate for dead/orphan status. The 4 tables are passive storage; whether or how they are accessed is a property of the application code that queries them (`app/src/*.cs`), which is outside this skill's SQL-source scope.

---

## 2. Call & Dependency Graph

`calls.tsv` was materialized first and has 0 rows (`wc -l calls.tsv` → `0`) — there are 0 stored procedures, functions, or triggers in the analyzed source, so there are 0 possible invocation edges between them.

**Dependency Graph:** Empty. No `EXEC`, no function-call invocation, no trigger firing exists in the analyzed source (confirmed: `grep -noiE '\bEXEC\b|\bEXECUTE\b' app/db/schema.sql` → no hits; `grep -noiE 'CREATE[[:space:]]+TRIGGER' app/db/schema.sql` → no hits).

**Dynamic SQL flagging:** None found. `grep -rnoiE 'sp_executesql|EXECUTE IMMEDIATE|xp_cmdshell' <SRC>` (run across the whole source tree, including `app/src/*.cs`) → no hits.

**External / Unresolvable Edges:** None. No `EXEC`/`EXECUTE` targets exist in the source to enumerate.

**Hub Objects:** No hub objects in the call graph — `calls.tsv` has 0 rows, so no candidate object reaches the 3+ invocation-edge threshold. Cross-referencing Dimension 3: the CRUD-matrix hub-resource section is also empty (see below), so no object is a hub by either measure.

**Extraction Sequencing:** N/A — there are no routines or triggers to sequence. The 4 tables (`dbo.Products`, `dbo.Customers`, `dbo.Orders`, `dbo.OrderLines`) carry no DB-resident logic; nothing needs to be reimplemented in application code before the database becomes dumb storage, because the database is already dumb storage as defined.

---

## 3. CRUD Matrix & Trigger Cascade Map

`crud.tsv` was materialized first and has 0 rows (`wc -l crud.tsv` → `0`) — the matrix records one row per (object, resource) pair for stored procedures, functions, triggers, and views, and 0 objects of any of those classes exist in the analyzed source, so there are 0 possible pairs.

**CRUD Matrix:**

| Object | Resource | Type | C | R | U | D | Access Pattern | File:Line |
|--------|----------|------|---|---|---|---|----------------|-----------|
| *(no rows — 0 stored procedures, functions, views, or triggers exist in source to touch any table)* | | | | | | | | |

All table access in this system originates in application code (`app/src/*.cs`, per the `schema.sql` header comment and confirmed absent of any embedded `CREATE`/`EXEC` SQL-object text), which is outside this skill's SQL-source scope and therefore outside this matrix.

**Resource Touch Tally (computed from `crud.tsv`):**

```
$ awk -F'|' '{print $2, $1}' crud.tsv | sort -u | awk '{c[$1]++} END {for (r in c) print r, c[r]}'
(no output — crud.tsv is empty)
```

| Resource | Distinct objects touching | Hub? (3+) |
|----------|---------------------------|-----------|
| *(no rows — no Resource value appears in crud.tsv)* | | |

**Hub Resources:** None. The tally has 0 rows and therefore 0 `yes` rows, so there are 0 hub-resource lines.

**Trigger Cascade Map:** None. 0 `CREATE TRIGGER` statements exist in the analyzed source (Context Intake, Component Manifest). There is no trigger cascade for the application to reimplement.

---

## 4. Transaction & Error-Handling Semantics

```
$ grep -noiE 'BEGIN TRAN|BEGIN TRANSACTION|COMMIT|ROLLBACK|SAVE TRANSACTION|TRY|CATCH|THROW|RAISERROR' app/db/schema.sql
(no output)
```

**Transaction Boundaries:** None. `app/db/schema.sql` contains only `CREATE TABLE` DDL — no `BEGIN TRANSACTION`, `COMMIT`, `ROLLBACK`, or `SAVE TRANSACTION` statements exist anywhere in the analyzed source.

**Error Swallowing:** N/A. No `BEGIN TRY`/`BEGIN CATCH` blocks exist in the analyzed source (0 hits above) — there is no error-handling code to evaluate for a missing re-throw.

**Autonomous Transactions:** N/A (Oracle-specific construct; dialect is T-SQL). Not applicable regardless of dialect, since no procedural code exists in source.

**Uncatchable Errors:** N/A. No `TRY`/`CATCH` code exists that could rely on catching severity-20+ errors.

---

## 5. Dialect Footguns & Hidden Risks

`findings.tsv` was materialized first and has 0 rows (`wc -l findings.tsv` → `0`). Every search below is run over the sole production SQL file, `app/db/schema.sql` (no test scripts exist to search separately):

```
$ grep -noiE 'EXECUTE[[:space:]]+AS' app/db/schema.sql
(no output)
$ grep -noiE "ISNULL|COALESCE|''" app/db/schema.sql
(no output)
$ grep -noE '[A-Za-z]:\\' app/db/schema.sql
(no output)
$ grep -noE '([0-9]{1,3}\.){3}[0-9]{1,3}' app/db/schema.sql
(no output)
$ grep -noiE 'Server=|Data Source=|Initial Catalog=' app/db/schema.sql
(no output)
$ grep -noiE 'CHECK[[:space:]]*\(' app/db/schema.sql
(no output)
$ grep -noiE 'DEFAULT[[:space:]]+(GETDATE|NEWID|SUSER|USER_ID|CURRENT_)' app/db/schema.sql
(no output)
$ grep -nE '#{1,2}[A-Za-z_][A-Za-z0-9_]*' app/db/schema.sql
(no output)
$ grep -niE 'tempdb\.\.|tempdb\.dbo\.' app/db/schema.sql
(no output)
$ grep -niE 'CONTEXT_INFO|SESSION_CONTEXT|sp_set_session_context' app/db/schema.sql
(no output)
$ grep -niE 'NEXT[[:space:]]+VALUE[[:space:]]+FOR|CREATE[[:space:]]+SEQUENCE|@@IDENTITY' app/db/schema.sql
(no output)
$ grep -niE 'SET[[:space:]]+(ROWCOUNT|ANSI_NULLS|QUOTED_IDENTIFIER|ANSI_WARNINGS|DATEFIRST|LANGUAGE)' app/db/schema.sql
(no output)
$ grep -noiE '\bMERGE\b' app/db/schema.sql
(no output)
```

- **SECURITY_CONTEXT:** No hits. No `EXECUTE AS` in source.
- **NULL_SEMANTICS:** No hits. No `ISNULL`, `COALESCE`, or `''` literal in source.
- **HARDCODED_VALUE:** No hits. No file paths, IP addresses, connection strings, or business-constant literals in source (only DDL type/length/precision literals such as `NVARCHAR(40)`, `DECIMAL(10,2)`, which are column-definition sizing, not business rules).
- **CONSTRAINT_LOGIC:** No hits. No `CHECK` constraints; the only `DEFAULT` string matches are inside the file's header comment (lines 5-6), not inside a column definition — no logic-bearing `DEFAULT` clause exists.
- **GLOBAL_STATE:** No hits across all five sub-searches (temp tables, `tempdb` refs, ambient session state, sequences/`@@IDENTITY`, session `SET` options). There is no shared or ambient state for the application to reconcile.
- **OTHER:** No hits for `MERGE`. No other dialect-specific footguns detected.

Every production row that could exist is a `findings.tsv` row; `findings.tsv` has 0 rows, so there are 0 Dimension-5 findings to report.

---

## Confidence & Coverage Declaration

- **Files analyzed:** 1 of 1 provided (`app/db/schema.sql` — the only file matching the SQL-source glob; 4 additional `.cs` files exist in `app/src/` but are C# application code, outside this skill's SQL-source scope)
- **Artifact types covered:** DDL / table schemas (found, 4). Stored procedures, scalar functions, table-valued functions, triggers, views, jobs/scheduled tasks, packages, test scripts, binary DB files — all searched, all Not Found (0)
- **Missing artifacts affecting analysis:** None. No missing references (Missing-Reference Table: 0 rows); no README/docs/ to check path claims against (not a gap in the risk sense — there was nothing documented to contradict the source)
- **Encoding/format issues encountered:** None. `app/db/schema.sql` is UTF-8 text with LF line endings (0 CR characters found); no non-English comments observed
- **Binary DB files (unparsed):** None
- **Path mismatches:** N/A — no README or `docs/` files exist in the source tree to compare against actual layout

---

## Recommended Next Steps

This section names the downstream consumer of this report, and the optional evidence that would sharpen what that consumer can do — and nothing else. It is a RECOMMENDATION the reader may take or ignore.

- **Downstream planner:** the `sproc-migration-plan` skill consumes this report — specifically the `### Extraction Metrics` table (0 rows) and the Dimension-5 `GLOBAL_STATE` rows (0 rows) — to sequence and size the extraction. Given both are empty, the planner's SQL-side extraction backlog for this system is empty; hand it this file's path if a plan is still wanted for completeness.
- **Binary DB export path:** N/A — no binary DB file was found in Context Intake.
- **Optional runtime evidence pack:** static source cannot show call frequency, row volumes, or which routines are actually invoked in production — but this system defines 0 routines, so there is nothing for an execution-statistics export to disambiguate on the DB side. No such pack was provided or requested for this report.
- **Out-of-scope but relevant to the stated extraction goal:** the actual business logic this system runs (reorder thresholds, discount rates, order-status transitions, per `app/db/schema.sql:10-13`) is claimed to live in `app/src/*.cs`. That is application code, not DB-resident logic, and therefore outside this skill's SQL-source-only scope — nothing here needs to be *extracted from the database*, because the database is already dumb storage. If the extraction-scoping goal also needs an inventory of the *application-side* logic (for consistency review, not migration), that is a separate analysis this report does not perform.
