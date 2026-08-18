## Executive Summary — Critical Red Flags

Ranked, cited, severity-tagged concrete hazards. NOT a score, NOT a verdict.

- **[CRITICAL]** The entire analyzed source tree is a single binary SQL Server data file (`sample_db.mdf`) with no accompanying text SQL export. Three DB-routine names are visible in the raw binary bytes — `sp_calculate_driver_payout`, `fn_apply_late_fee`, `trg_audit_vehicle_status` (`sample_db.mdf`, binary-safe grep hits, names only — bodies unrecovered; see Context Intake and Dimension 1). This is direct evidence of business logic resident in the database (a payout calculation, a fee-application rule, and an audit trigger), but none of it can be reverse-engineered, counted, or cited by line from the current source set. **This is not an empty extraction scope — it is an unknown one.** Extraction planning cannot begin until this file is exported to text DDL.
- **[HIGH]** Zero text SQL source files (`.sql`, `.ddl`, `.prc`, `.fnc`, `.trg`, `.pks`, `.pkb`) exist anywhere under the analyzed path. Every dimension of this report (call graph, CRUD matrix, trigger cascades, transaction/error semantics, dialect footguns) is consequently empty by construction, not by finding — the analysis has no material to search. Do not read "0 findings" in any section below as "no risk"; read it as "no visibility."
- **[HIGH]** Coverage is 0 of 0 provided objects (0/0, undefined — see Coverage Declaration) because no object was ever DEFINED in a parseable source. The three names surfaced from the binary are excluded from this count by the skill's binary-DB handling rules (names-only, bodies unrecovered) — they are neither "provided" nor "missing," they are simply unanalyzable in their current form.

---

## Coverage Declaration

- **Objects provided:** 0 objects across 0 files (no per-type subtotals — the manifest is empty; see `### Extraction Metrics` and Component Manifest below) — provided means DEFINED in a parseable text source; the binary DB file's surfaced names are never part of this count.
- **Objects referenced but missing:** 0 (no text source exists to contain a reference to any object, so no missing-reference row could be produced)
- **Estimated coverage:** undefined (0/0) — there are zero provided objects and zero missing-reference rows to divide, computed by command (see Dimension 1 proof block); this is a data-absence result, not a 100%-or-0% coverage claim.
- **Reduced-confidence dimensions:** All five dimensions are reduced-confidence for the same single reason — zero parseable text source. Additionally, dialect detection itself is `[LOW-CONF]`: it is inferred solely from the `.mdf` file extension (a SQL Server primary-data-file extension), never from any of the skill's content-based T-SQL/PL-SQL indicators, because the file's content is binary and unparseable as SQL text.
- **Key gaps:** No text SQL export exists at all. The single file present (`sample_db.mdf`) is a binary SQL Server data file. Full DDL export (stored procedures, functions, triggers, table schemas) is required before any dimension of this report can be populated with cited evidence. See `mssql.md` "Export Appendix: Getting Source to Disk" and the Recommended Next Steps section below.

---

## 1. Inventory & Completeness

### Context Intake

**Documentation check:** No README or docs files exist anywhere under `binonly1` (`find` for `README*`, `*.md`, and a `docs/` directory returned no results). There is no documentation to verify path claims or count claims against, so no documentation-verification table is produced — this absence is itself stated rather than silently skipped.

**Encoding and line-ending detection:**

```
$ file binonly1/sample_db.mdf
binonly1/sample_db.mdf: data
```

`file` reports the sole source artifact as binary `data`, not text. Per the skill's binary-DB-file rule, `sample_db.mdf` is classified as a **binary DB file — unparsed**, not a text SQL source. No encoding or line-ending claim (UTF-8/ISO-8859-1/CRLF/LF) applies to it, because it is not text.

**Best-effort name surfacing** (binary-safe grep, names only — bodies unrecovered):

```
$ grep -a -noE 'CREATE (PROCEDURE|FUNCTION|TRIGGER|PACKAGE|VIEW)[^\x00-\x1f]*' sample_db.mdf
1:CREATE PROCEDURE sp_calculate_driver_payout
1:CREATE FUNCTION fn_apply_late_fee
1:CREATE TRIGGER trg_audit_vehicle_status
```

(Binary grep reports match offset as line "1" for all three hits — the file is not line-structured text, so this is not a meaningful line citation; it is the verbatim matched text only.) Names found: `sp_calculate_driver_payout` (procedure), `fn_apply_late_fee` (function), `trg_audit_vehicle_status` (trigger). Per the skill's rule, these names appear ONLY here and in the Coverage Declaration lines above — they are never rendered as rows in the Component Manifest, the Extraction Metrics table, the Dimension-5 `GLOBAL_STATE` rows, `metrics.tsv`, or `findings.tsv`, and are excluded from every count derived from those artifacts.

**Context-intake table:**

| Artifact Type | Extensions | Found? | Count |
|---------------|-----------|--------|-------|
| Stored procedures | `.sql`, CREATE PROCEDURE | No | 0 |
| Scalar functions | `.sql`, CREATE FUNCTION RETURNS scalar | No | 0 |
| Table-valued functions | `.sql`, CREATE FUNCTION RETURNS TABLE | No | 0 |
| Triggers | `.sql`, CREATE TRIGGER, `.trg` | No | 0 |
| Views (with logic) | `.sql`, CREATE VIEW | No | 0 |
| DDL / table schemas | `.sql`, CREATE TABLE, `.ddl` | No | 0 |
| Jobs / scheduled tasks | `.sql`, CREATE JOB, SQL Agent | No | 0 |
| Packages (Oracle) | `.pks`, `.pkb`, CREATE PACKAGE | No | 0 |
| Test scripts | `*Test*.sql`, `*_test.sql` | No | 0 |
| Binary DB files (unparsed) | .mdf/.ndf/.ldf/.bak/.dbf/.dmp | Yes | 1 |

No test scripts were found, so none are excluded from the production logic inventory.

**Source-file glob proof:**

```
$ find "$SRC" -type f \( -iname "*.sql" -o -iname "*.ddl" -o -iname "*.prc" -o -iname "*.fnc" -o -iname "*.trg" -o -iname "*.pks" -o -iname "*.pkb" \) | wc -l
0
$ find "$SRC" -type f | wc -l
1
```

0 text SQL source files matched the Step-1 glob; 1 total file exists in the source tree (the binary `sample_db.mdf`).

**Dialect detection:** No text content exists to test against any T-SQL or PL/SQL content indicator (`GO`, `dbo.`, `CREATE OR ALTER`, `%TYPE`, `DECLARE...BEGIN...END`, etc.) — the file is binary. The `.mdf` extension is itself a Microsoft SQL Server primary-data-file extension, so the dialect is inferred as **T-SQL (MSSQL)** on that basis alone `[LOW-CONF]`, and the `references/dialects/mssql.md` reference file was loaded accordingly. This inference is extension-based, not content-based, and is flagged as such throughout this report.

### Component Manifest

No objects were parsed from any text SQL source, because none exists (see glob proof above). The manifest is empty.

| Type | Object Name | File | LOC | Notable Flags |
|------|------------|------|-----|---------------|
| — | — | — | — | No parseable text SQL source in the analyzed tree |

**Grand total: 0 objects (= 0), 0 LOC (= 0).** There are no per-type subtotals because every type count is 0 — no type has any member to sum. This total explicitly does NOT include the three names surfaced from `sample_db.mdf` in Context Intake; per the skill's binary-DB rule, binary-derived names are never counted as provided/manifested objects.

**Binary-DB verdict note (mandatory):** A zero parsed-routine count here, alongside the *present* binary DB file `sample_db.mdf`, must NOT be read as "no DB logic" or "empty extraction scope." It is read as: **logic likely resides in an unparsed binary — DDL export required to analyze.** The three surfaced names (`sp_calculate_driver_payout`, `fn_apply_late_fee`, `trg_audit_vehicle_status`) are concrete evidence that DB-resident logic exists; this report simply cannot see inside it yet.

### Extraction Metrics

```
$ wc -l metrics.tsv
0 metrics.tsv
```

`metrics.tsv` has 0 rows because 0 routines or triggers were parsed from text source (0 text SQL files exist to parse). The table below has no rows for the same reason — this is not a "found nothing interesting" result, it is a "nothing to search" result.

| Object | Params | Cursor Loops | Branches | UDT Usage | File | LOC |
|--------|--------|--------------|----------|-----------|------|-----|
| — | — | — | — | — | — | — |

**Branch-counting basis (stated for completeness, unexercised here):** Would count each `IF`, `ELSIF`/`ELSEIF`, each `WHEN` arm of `CASE`, each non-cursor-driving `WHILE` head, and each non-cursor-loop `EXIT WHEN`/conditional `BREAK`; would exclude `ELSE` arms, exception/CATCH handlers, `FOR`/bare `LOOP` heads, and `END IF`/`END CASE` terminators. Not exercised in this report — 0 routines were parsed.

### Missing-Reference Table

| Source File:Line | Reference Type | Target | Impact |
|-----------------|---------------|--------|--------|
| — | — | — | No text source exists to contain any `EXEC`/`INSERT`/`SELECT FROM`/etc. reference |

0 rows. This table is empty because no text source exists to search for external references — not because all references resolved.

### Coverage Honesty Check

Analysis covers 0 of 0 referenced objects (0/0, undefined — see Coverage Declaration for the computed-by-command derivation). No object was referenced anywhere, because no parseable text source contains any reference-bearing statement. This is distinct from "100% coverage" — it is an absence of material to be covered.

### Dead / Orphan Code

Not assessable. 0 objects were parsed, so there are 0 candidates to classify as "confirmed dead" or "possibly dead." The three names surfaced from the binary DB file are excluded from this section for the same reason they are excluded from the manifest — they are unparsed, not orphaned.

---

## 2. Call & Dependency Graph

```
$ wc -l calls.tsv
0 calls.tsv
```

`calls.tsv` has 0 rows. No `EXEC`, function-call, or trigger-firing edge could be extracted from any text source, because none exists.

**Dependency Graph:** None. 0 objects were parsed, so there is nothing to place in a tree or diagram. This is stated explicitly rather than omitted, per the skill's explicit-empty-case rule.

**Dynamic SQL flagging:** No dynamic SQL (`sp_executesql`, `EXEC('...')`, `EXECUTE IMMEDIATE`) could be searched for — there is no text to search.

**External / Unresolvable Edges:** None found — 0 `EXEC`/`EXECUTE` targets exist in any parsed text, because no text was parsed.

**Hub Objects:**

```
$ sort -u calls.tsv
(no output — calls.tsv has 0 rows)
```

No hub objects in the call graph — `calls.tsv` is empty, so no candidate object has any distinct-callee or distinct-caller count to evaluate against the 3+ threshold. Cross-referencing Dimension 3: the CRUD-matrix hub-resource tally (below) is likewise empty for the identical reason (0 text source).

**Extraction Sequencing:** Not determinable. A leaves-first extraction order requires a populated dependency graph; none exists. The only actionable sequencing statement this report can make is: **export `sample_db.mdf` to text DDL before any extraction sequencing is attempted.**

---

## 3. CRUD Matrix & Trigger Cascade Map

```
$ wc -l crud.tsv
0 crud.tsv
```

`crud.tsv` has 0 rows — no `INSERT`/`SELECT`/`UPDATE`/`DELETE` statement against any table could be found, because no text source exists.

| Object | Resource | Type | C | R | U | D | Access Pattern | File:Line |
|--------|----------|------|---|---|---|---|----------------|-----------|
| — | — | — | | | | | No parseable text SQL source in the analyzed tree | — |

No object class (procedures, functions, triggers, views) is represented, because no object of any class was parsed.

**Resource Touch Tally:**

```
$ awk -F'|' '{print $2, $1}' crud.tsv | sort -u | awk '{c[$1]++} END {for (r in c) print r, c[r]}'
(no output — crud.tsv has 0 rows)
```

| Resource | Distinct objects touching | Hub? (3+) |
|----------|--------------------------|-----------|
| — | — | — |

0 rows in the tally (the command's raw output is empty, reproduced above). No resource reaches the hub threshold because no resource was ever recorded. **This is not evidence that no table is a hub in the real system** — it is evidence that the CRUD matrix has no material to evaluate.

**Trigger Cascade Map:** No cascade can be traced. One trigger name — `trg_audit_vehicle_status` — was surfaced from the binary DB file (see Context Intake), but its body, its firing table, and its DML statements are all unrecovered; it cannot be placed in a cascade chain from the current source set. No cascade narrative is forced here, consistent with the skill's explicit-empty-case guidance for a corpus where no trigger body exists in source. **The application must reimplement any real cascade chain the export eventually reveals — this is unknown, not absent.**

---

## 4. Transaction & Error-Handling Semantics

**Transaction Boundaries:** None found. `BEGIN TRANSACTION`/`COMMIT`/`ROLLBACK`/`SAVE TRANSACTION` (T-SQL) or `COMMIT`/`ROLLBACK`/`SAVEPOINT`/`PRAGMA AUTONOMOUS_TRANSACTION` (PL/SQL) could not be searched for — there is no text source to search.

**Error Swallowing:** Not assessable. `TRY/CATCH` and `EXCEPTION WHEN OTHERS` blocks could not be searched for — there is no text source to search. Given that `sp_calculate_driver_payout` and `fn_apply_late_fee` names were surfaced from the binary (Context Intake), and payout/fee-calculation logic is a common site for silently-swallowed error handling in production systems, this is flagged as an **unknown, not a clean bill of health** — the export is required to check it.

**Autonomous Transactions:** Not assessable — no text source.

**Uncatchable Errors:** Not assessable — no text source. (Dialect was inferred as T-SQL from the `.mdf` extension only, `[LOW-CONF]`; if confirmed, SQL Server severity-20+ uncatchable-error risk would need to be re-checked once source is available.)

---

## 5. Dialect Footguns & Hidden Risks

```
$ wc -l findings.tsv
0 findings.tsv
```

`findings.tsv` has 0 rows. Search commands were run per category against the production text-file set; that set is empty (0 files matched the Step-1 glob), so every command below returned no output. The binary DB file `sample_db.mdf` was **not** searched for footguns in this dimension — per the skill's binary-DB rule, its surfaced names (and any other content) are excluded from `findings.tsv` and from every category below; only text sources are eligible for Dimension-5 search.

```
$ grep -nE 'EXECUTE AS|AUTHID' <production text files>
no production text files to search
$ grep -nE 'ISNULL|COALESCE|NVL' <production text files>
no production text files to search
$ grep -nE '[A-Za-z]:\\|[0-9]{1,3}(\.[0-9]{1,3}){3}|Server=|Password=' <production text files>
no production text files to search
$ grep -nE 'DEFAULT |CHECK \(' <production text files>
no production text files to search
$ grep -nE '#temp|##temp|tempdb\.\.|CONTEXT_INFO|SESSION_CONTEXT|NEXT VALUE FOR' <production text files>
no production text files to search
```

- **Security context changes:** None found — 0 hits (no production text to search).
- **NULL vs empty-string semantics:** None found — 0 hits (no production text to search).
- **Hardcoded values & environment names:** None found — 0 hits (no production text to search).
- **Business rules in constraints:** None found — 0 hits (no production text to search).
- **Global & shared state (`GLOBAL_STATE`):** None found — 0 hits (no production text to search). No `findings.tsv` `GLOBAL_STATE` rows exist as a result; the downstream migration planner will have nothing to size sharing/coupling risk from until this system is exported.
- **Other dialect-specific footguns (T-SQL `MERGE`, Oracle `FORALL`, implicit cursors, etc.):** None found — 0 hits (no production text to search).

Every category above returned an explicitly empty result rather than being dropped, per the skill's requirement. **None of these zero counts should be read as "this system has no footguns"** — three named routines (`sp_calculate_driver_payout`, `fn_apply_late_fee`, `trg_audit_vehicle_status`) are known to exist inside the unexamined binary; the footgun catalog simply has not been run against them yet.

---

## Confidence & Coverage Declaration

- **Files analyzed:** 0 of 1 provided (the 1 provided file, `sample_db.mdf`, is a binary DB file and was not text-parsed; see Component Manifest and Context Intake)
- **Artifact types covered:** None of the ten Context-Intake artifact types were found as parseable text; 1 binary DB file was found and name-surfaced only (see Context Intake table)
- **Missing artifacts affecting analysis:** Every dimension of this report — inventory, dependency graph, CRUD matrix, transaction/error semantics, dialect footguns — is affected, because the sole provided artifact is unparsed binary. A full DDL export (stored procedures, functions, triggers, and table schemas) is required before any dimension can be populated with cited evidence.
- **Encoding/format issues encountered:** `sample_db.mdf` is reported by `file` as binary `data`, not text; no encoding (UTF-8/ISO-8859-1/Windows-1252) or line-ending (CRLF/LF) claim applies to it.
- **Binary DB files (unparsed):** `sample_db.mdf` — contents not parsed; script out definitions (DDL export) and re-run for authoritative analysis. Names surfaced via binary-safe grep, bodies unrecovered: `sp_calculate_driver_payout` (procedure), `fn_apply_late_fee` (function), `trg_audit_vehicle_status` (trigger).
- **Path mismatches:** None to report — no README or documentation exists in the analyzed tree to make a path or count claim in the first place (see Context Intake documentation check).

---

## Recommended Next Steps

- **Downstream planner:** the `sproc-migration-plan` skill consumes this report — specifically the `### Extraction Metrics` table and the Dimension-5 `GLOBAL_STATE` rows — to sequence and size the extraction. Both are currently empty in this report; handing this report to the planner as-is will yield an empty or near-empty plan that does **not** reflect the true extraction scope. Re-run `sproc-xray` after the export below and hand the planner the regenerated report.
- **Binary DB export path:** `sample_db.mdf` must be scripted to text DDL before this system can be meaningfully analyzed. See `mssql.md` "Export Appendix: Getting Source to Disk" — SSMS **Generate Scripts** wizard (schema-only, one file per object), `mssql-scripter --include-objects --object-type StoredProcedure --object-type Function --object-type Trigger --file-per-object --output-dir ./sql-export`, or a `sys.sql_modules`/`OBJECT_DEFINITION()` query via `sqlcmd`. Any of these three methods will recover the full bodies of `sp_calculate_driver_payout`, `fn_apply_late_fee`, `trg_audit_vehicle_status`, and any other objects the current binary-only view cannot show.
- **Optional runtime evidence pack:** No execution-statistics export (SQL Server Query Store / `sys.dm_exec_procedure_stats`) was provided alongside this analysis — its absence is stated explicitly. Once text DDL is available, such a pack would let the downstream planner separate hot paths from dead weight among the recovered routines.
