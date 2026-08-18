---
name: sproc-xray
version: 0.5.0
description: Use when analyzing, auditing, or reverse-engineering database-resident business logic (stored procedures, functions, triggers) for extraction migration off Oracle or SQL Server. Trigger when user provides SQL source (T-SQL, PL/SQL), asks for DB logic discovery, wants the database reduced to dumb storage, or prepares a database-to-application-code migration. Accepts a local directory path or GitHub repo URL as input.
---

# Database Stored Procedure X-Ray

## Overview

Reverse-engineer the evidence trail of database-resident business logic — stored procedures, functions, triggers, and their dependencies — to prepare for extraction migration from Oracle or SQL Server to application code. Every finding answers: **what behavior must the application absorb before the database can become dumb storage?** Every claim must cite specific file and line evidence.

## When to Use

- User provides SQL source files (T-SQL or PL/SQL) for migration analysis
- Extraction migration assessment: moving DB logic to application code
- Discovery audit of business logic hiding in stored procedures, functions, or triggers
- Risk assessment before migrating off Oracle or SQL Server
- Preparing a database to become dumb storage (tables-only, logic extracted)

**When NOT to use:**
- Target-architecture design (downstream session's job)
- Sproc-to-sproc translation guidance (logic leaves the DB, doesn't move engines)
- Active database development or SQL debugging
- PostgreSQL source analysis (PostgreSQL is the typical destination, not source)

## Input

The user provides ONE of:
- **Local directory path** containing SQL source files
- **GitHub repo URL** to clone and analyze

**CRITICAL: Disk-only rule.** This skill analyzes SQL source files on disk. If the user has only a live database with no exported source files, point them to the **"How to Export Your Database to Disk"** appendix in the appropriate dialect reference file (`references/dialects/mssql.md` or `references/dialects/oracle.md`) and STOP. Never invent catalog contents or fabricate object definitions. The skill requires actual source files.

## Execution Steps

### Step 1: Acquire the Codebase

- **Resolve the source location, then create a private per-run scratch directory and
  work inside it.** The agent runs this skill across separate shell calls: the working
  directory persists between them but shell variables do NOT. A **relative** local path
  must be resolved to an absolute path BEFORE entering the scratch dir — once the working
  directory is the scratch dir, a relative path resolves against it and the source is
  lost. So, in a SINGLE shell command, capture the original invocation dir, resolve the
  source (for a local path, into an absolute path — this both verifies it exists and
  keeps it usable after the `cd`), create the scratch dir, print the literal paths, and
  enter the scratch dir. Record the printed literal paths and reuse those literal strings
  (not the variables, which are unset in later calls) in the glob, report, and cleanup
  steps:

    - **Local path input** — resolve it to an absolute `SRC` before the `cd`:

        ```bash
        ORIG="$(pwd)"; SRC="$(cd "<local path>" && pwd)"; WORK="$(mktemp -d)"; printf 'ORIG=%s\nSRC=%s\nWORK=%s\n' "$ORIG" "$SRC" "$WORK"; cd "$WORK"
        ```

    - **GitHub URL input** — clone into the scratch dir after entering it:

        ```bash
        ORIG="$(pwd)"; WORK="$(mktemp -d)"; printf 'ORIG=%s\nWORK=%s\n' "$ORIG" "$WORK"; cd "$WORK"
        git clone <url> ./<repo-name>
        ```

  The report is written under the recorded `ORIG` path; the scratch dir is the recorded
  `WORK` path. From here the working directory IS the scratch dir; every scratch file
  below (`metrics.tsv`, `calls.tsv`, `crud.tsv`, `findings.tsv`) is materialized here and
  every bare-filename proof-block command resolves here.
- Glob for all SQL source files at the source location — the recorded `$SRC` path for a
  local input, or `./<repo-name>` for a cloned GitHub repo: `*.sql`, `*.ddl`, `*.prc`,
  `*.fnc`, `*.trg`, `*.pks`, `*.pkb` (package spec/body)

### Step 2: Dialect Detection & Reference Loading

Detect the SQL dialect from source file content or accept the user's statement:

**T-SQL (Microsoft SQL Server) indicators:**
- Batch separator `GO`
- Schema prefixes `dbo.`, `[dbo]`, `SCHEMA.`
- `CREATE OR ALTER PROCEDURE`, `CREATE OR ALTER FUNCTION`
- `NVARCHAR`, `VARBINARY`, `UNIQUEIDENTIFIER` types
- `SET NOCOUNT ON`, `SET ANSI_NULLS`, `SET QUOTED_IDENTIFIER`
- `EXEC`, `sp_executesql`, `RAISERROR`

**PL/SQL (Oracle) indicators:**
- `CREATE OR REPLACE PROCEDURE`, `CREATE OR REPLACE FUNCTION`
- Package constructs: `CREATE PACKAGE`, `CREATE PACKAGE BODY`
- `%TYPE`, `%ROWTYPE`, `PRAGMA`, `AUTHID`
- `EXECUTE IMMEDIATE`, `RAISE_APPLICATION_ERROR`
- `DECLARE ... BEGIN ... END;` block structure
- `VARCHAR2`, `NUMBER`, `CLOB`, `BLOB` types

Once detected, load the corresponding dialect reference file:
- **T-SQL:** `references/dialects/mssql.md`
- **PL/SQL:** `references/dialects/oracle.md`

If detection is ambiguous or files appear mixed, ask the user to confirm the dialect.

### Step 3: Context Intake & Robustness

Before analysis, confirm what was received and establish intake robustness.

**Documentation check (MANDATORY):** Read the repo's README and any docs/ files during intake, then perform BOTH verifications below. They are co-equal — neither subsumes the other:

1. **Path claims:** Verify every documented path, folder name, and file-location claim against the actual directory layout (e.g., README says `sql/`, actual folder is `SqlScripts/`).
2. **Count and structural claims:** Verify every documented count, numeric, or structural claim against your own parsed counts (e.g., README says 12 tables, source defines 11).

Documented claims are CHECKED — never adopted, and never "confirmed" by anything other than an actual look at the disk or an actual parsed count. When documentation disagrees with parsed reality, that disagreement IS the finding — report it as such; do not adjust your count to match the docs. Flag every mismatch in the report — documentation-vs-reality mismatches are evidence of drift and mislead extraction teams. Blanket statements like "all other documentation claims verified" are forbidden — each verified claim is listed individually with its verdict, or it is not claimed as verified. A documented count is checked against the parsed count of the SAME category only — never bridge a mismatch by borrowing objects from another category so the documented number works out (docs say "12 tables" and you parsed 11 tables plus 1 database: that is a MISMATCH, not a match). Each claim receives exactly ONE verdict, stated identically everywhere the claim is discussed — a claim marked VERIFIED in one section and called a mismatch in another is a self-consistency failure. The verdict is COMPUTED, not judged: every count claim is verified as a row in a table with these exact columns — `| Claim | Documented N | Parsed M (same category) | N = M? | Verdict |` — where the `N = M?` cell is `yes` or `no` by literal numeric equality and the Verdict cell is `VERIFIED` exactly when `N = M?` is `yes`, otherwise `MISMATCH`. A row whose Verdict disagrees with its own `N = M?` cell is a self-consistency failure on its face. No note, reinterpretation, or alternative reading may turn unequal numbers into VERIFIED — conditional or hedged verdicts ("VERIFIED if the docs meant X") are forbidden; same-category N vs M, one word. Verdicts are adjudicated in the documentation-verification section ONLY: any later section that mentions a documented claim copies the already-stated verdict word and never re-argues it. The analysis proceeds from what exists on disk, not what documentation promised.

**Encoding and line-ending detection (MANDATORY):** Run `file` (or equivalent) on the source files and report the DETECTED encoding and line-ending facts. Never assume UTF-8 or LF — an unverified encoding claim is a fabrication like any other. Common findings:
- **Non-UTF-8 sources:** SSMS-exported files are often ISO-8859-1 or Windows-1252, not UTF-8. Use encoding-tolerant reading (e.g., `grep -a` for binary-safe search, `iconv` if conversion needed).
- **Mixed line endings:** CRLF (Windows) and LF (Unix) may be mixed in the same export. Report what `file` actually shows.
- **Non-English comments:** Expect comments in languages other than English. Don't fail on non-ASCII characters.
- **Binary DB files:** When `file` reports a source as binary `data` (not text) and its extension is a DB file (`.mdf`, `.ndf`, `.ldf`, `.bak`, `.dbf`, `.dmp`), classify it as a **binary DB file** — unparsed, not a text SQL source.
- **Best-effort name surfacing:** For each binary DB file, binary-safe grep it for `CREATE (PROCEDURE|FUNCTION|TRIGGER|PACKAGE|VIEW)` headers (e.g., `grep -a -oE 'CREATE (PROCEDURE|FUNCTION|TRIGGER|PACKAGE|VIEW)[^\r\n]*' <file>`) and list any names found, marked "names only, bodies unrecovered." These names are **never rendered as rows** in the Component Manifest routine table, the `### Extraction Metrics` table, or the Dimension-5 `GLOBAL_STATE` rows, and are **never written to `metrics.tsv` or `findings.tsv`** — therefore they are excluded from every count derived from them. The names appear ONLY in the intake-table row below and the Coverage Declaration line (see Report Format's `## Confidence & Coverage Declaration`).

**Context-intake table** — list artifact types found and missing:

| Artifact Type | Extensions | Found? | Count |
|---------------|-----------|--------|-------|
| Stored procedures | `.sql`, CREATE PROCEDURE | | |
| Scalar functions | `.sql`, CREATE FUNCTION RETURNS scalar | | |
| Table-valued functions | `.sql`, CREATE FUNCTION RETURNS TABLE | | |
| Triggers | `.sql`, CREATE TRIGGER, `.trg` | | |
| Views (with logic) | `.sql`, CREATE VIEW | | |
| DDL / table schemas | `.sql`, CREATE TABLE, `.ddl` | | |
| Jobs / scheduled tasks | `.sql`, CREATE JOB, SQL Agent | | |
| Packages (Oracle) | `.pks`, `.pkb`, CREATE PACKAGE | | |
| Test scripts | `*Test*.sql`, `*_test.sql` | | |
| Binary DB files (unparsed) | .mdf/.ndf/.ldf/.bak/.dbf/.dmp | | |

Flag test scripts separately — they are part of the source tree but not part of the production logic inventory.

### Step 4: Run the Analysis

Analyze ALL five dimensions below **in order** — each builds on the prior. Use subagents to parallelize where dimensions are independent (e.g., Dimensions 3-5 can run in parallel after 1-2 complete).

## Analysis Dimensions

### Dimension 1: Inventory & Completeness

**Purpose:** Establish what we have before reasoning over it. Cross-reference every object *called* against every object *defined*.

- **Object counts come from parsing `CREATE` statements, never from counting files.** A single file may contain zero, one, or many `CREATE TABLE / VIEW / FUNCTION / PROCEDURE / TRIGGER / DATABASE` statements. A file's name is not evidence of its contents. `CREATE DATABASE` is its own inventory category, not a table. Excluded files (test scripts, seed data) must be counted exactly and listed by name. `CREATE [OR REPLACE]` and the object keyword (`FUNCTION`/`PROCEDURE`) may be split across lines, so a single-line `grep 'CREATE OR REPLACE FUNCTION'` under-counts — count with a multi-line-aware pattern or by object banner.

- **Binary-DB verdict prohibitions.** When a binary DB file (per Context Intake) is present, the report must not assert that routines "live only in" any single text source — the binary is an unexamined source too. A zero parsed-routine count alongside a present binary DB file must never be read as "no DB logic" or "empty extraction scope," and the analysis must not be declined as empty on that basis — state instead: "logic likely resides in an unparsed binary — DDL export required to analyze."

- **Empty-scope short-circuit (fires only when NO binary DB file is present).** When ALL FOUR hold — 0 stored procedures + 0 functions + 0 triggers + 0 packaged routines, AND 0 logic-bearing views (the Context Intake "Views (with logic)" row), AND 0 business-rule constraints (the Dimension-5 `CONSTRAINT_LOGIC` category — CHECK constraints and logic-bearing DEFAULT clauses, defined under "Business rules in constraints" below), AND no binary DB file is present (per Context Intake) — this is a legitimate in-scope analytic result: "analyzed successfully, found zero DB-resident routines." It is not the wrong-dialect decline ("When NOT to use," above) and it is not the full five-dimension report either. Emit the **Empty-Scope Compact Report** (defined under Report Format) in place of the full five-dimension report below.

  **Mutual exclusivity with the binary-DB verdict prohibition immediately above.** The fourth conjunct of this gate requires no binary DB file — so this short-circuit and the binary-DB verdict prohibition above are written to never both fire on the same report. When a binary DB file IS present, this short-circuit does NOT fire regardless of the parsed routine count, and the prohibition above governs: state "logic likely resides in an unparsed binary — DDL export required," never the empty-scope conclusion.

  **Over-fire guard.** If routines are absent but logic-bearing views OR `CONSTRAINT_LOGIC` findings ARE present, this gate does NOT fire — produce the full five-dimension report below, covering whatever logic those views or constraints carry, even though the routine count is 0.

- **Component Manifest:** List all objects grouped by type with counts, LOC per file, total LOC. Close the manifest with a per-type subtotal line for each type and a grand-total line showing the inline addition for BOTH of its values — the object count as the sum of the per-type counts AND the LOC total as the sum of the per-type LOC subtotals (e.g., `Grand total: 217 objects (= 1 + 96 + 44 + 39 + 25 + 12), 48,112 LOC (= 21,204 + 11,733 + 7,402 + 4,371 + 2,180 + 1,222)`), each computed by command from the column just written. A grand object count without its own displayed type-count addition is not written. (The example's numbers are deliberately from a much larger fictional system — if any number from this skill's examples appears in your report, it was copied, not computed.)

  | Type | Object Name | File | LOC | Notable Flags |
  |------|------------|------|-----|---------------|
  | Stored Procedure | dbo.SP_Create_Post_Notifications | 004-03-SP-Create_Post_Notifications.sql | 85 | Calls missing table |
  | Table-Valued Function | dbo.FN_Get_User_Posts | 003-02-FN-Get_User_Posts.sql | 42 | Used by 3 sprocs |
  | Trigger | dbo.TR_Notify_Subscribers_On_New_Post | 005-TR-Notify_Subscribers.sql | 68 | Calls sproc |

- **Extraction Metrics (per routine and trigger; scratch file FIRST — MANDATORY):** A migration planner consumes this subsection as a fixed output contract, so its heading, its column set, and its counting bases do not vary between reports: the heading is exactly `### Extraction Metrics`, nested under `## 1. Inventory & Completeness` (see Report Format), and the columns are exactly those below. Materialize the metrics into a scratch file in your working directory BEFORE any part of this subsection is written — `metrics.tsv`, one line per routine and trigger: `Object|Params|CursorLoops|Branches|UDTFlags|File|LOC`. One row per routine and trigger DEFINED in the source, including packaged routines (one row per packaged routine, never one per package) and including routines every one of whose metrics is zero — a routine dropped because "there was nothing to report" is a silent omission, and a blank cell is never a substitute for a `0`. Then render the scratch rows as the report table:

  | Object | Params | Cursor Loops | Branches | UDT Usage | File | LOC |
  |--------|--------|--------------|----------|-----------|------|-----|
  | dbo.SP_Create_Post_Notifications | 5 | 2 | 17 | `dbo.PostIdList` (TVP) | 004-03-SP-Create_Post_Notifications.sql | 85 |
  | dbo.SP_Rebuild_Post_Index | 0 | 1 | 3 | none | 007-01-SP-Rebuild_Post_Index.sql | 53 |

  (Like every other example in this file, these rows are from the fictional blog system — a different, larger system than anything you are analyzing. Per Hard Constraint 8, an example number surfacing as one of your cells means it was copied, not computed. The second row shows the two things that are never omitted: a `0` written as `0`, and `none` written as a word.)

  Every number in this table is COMPUTED BY COMMAND, never read off the source by eye. For each metric family, run the searches the loaded dialect reference file specifies under **"Extraction-Metrics Detection Patterns"** (`references/dialects/oracle.md` or `references/dialects/mssql.md`), and immediately above the rendered table include a fenced code block with the exact commands and their raw `grep -n` (or equivalent) output verbatim. The number in a cell is the LENGTH OF THAT HIT LIST after the dialect file's stated exclusions are removed, and each removal is named with its line — the enumeration in the proof block IS the count (Hard Constraint 7). Every hit is a `FILE:LINE` transcription taken at search time. A cell whose number the pasted output does not reproduce is a self-consistency failure.

  **`UDT Usage` and the definition of SIGNATURE.** A routine's SIGNATURE is its parameter list PLUS, for a function, its return type (`RETURN <type>` in PL/SQL, `RETURNS <type>` in T-SQL). `UDT Usage` lists the user-defined-type constructs appearing anywhere in that signature, copied verbatim, or the literal word `none` — so a function returning `SYS_REFCURSOR`, `emp%ROWTYPE`, or `RETURNS @t TABLE (…)` records that construct even though its parameter list is UDT-free. Type anchors on LOCAL declarations inside the body are not signature UDTs. **The return type counts for `UDT Usage` and never for `Params`** — the two columns read the same clause for different purposes, which is why they are stated separately: `Params` counts formal parameters only, and a `RETURN`/`RETURNS` clause never increments it. **A trigger has no signature at all — no parameter list and no return type — so its `Params` is `0` and its `UDT Usage` is `none`, always, in both dialects; a trigger's Cursor Loops and Branches are still counted from its body on the same basis as any routine.**

  **Per-routine LOC (Lines of Code).** The `LOC` column records each routine and trigger's own source-code line span, computed by command from the source file, with a pasted proof block showing the exact command and its raw `wc -l` or line-range output for each object. The span basis is defined in the dialect reference files (`references/dialects/oracle.md` for PL/SQL, `references/dialects/mssql.md` for T-SQL) and depends on routine packaging:
  - **Standalone routine** (PL/SQL or T-SQL): `CREATE` header → terminating `END[;]` / `/` or batch terminator (`GO`). For a one-routine file this equals the file's code span.
  - **Packaged routine** (PL/SQL only): the routine's declaration line → the line before the next routine declaration within the same package body (→ the package body's `END` / `BEGIN`-initializer line for the last routine in the package). Routine-end names are optional in PL/SQL (bare `END;`), so the span is bounded by the next declaration, not by a literal `END <name>;`.
  - **Trigger**: body span (`CREATE TRIGGER` → terminating `END`; trailing trigger name optional).
  - **Basis**: raw line span (not comment/blank-stripped) — the total source lines the routine occupies — which feeds the three-band LOC bucket the downstream migration planner uses.

  **Distinct-measure rule (LOC is itemized-only, never summed).** Extraction Metrics per-routine `LOC` is a distinct measure from the Component Manifest's per-file and grand-total LOC; it is itemized-only and never summed. Routine spans do not sum to file LOC (headers, package wrappers, and inter-routine spacing account for the difference), and per-routine LOC is never reconciled against the manifest's file-level totals. The Extraction Metrics table does NOT include a Totals row — if a rendering adds one, the `LOC` cell in that row shows `—` (as it already does for `UDT Usage` and `File`), preserving Hard Constraint 8. This keeps Hard Constraint 5/8 self-consistency checks from false-alarming on the two LOC measures, which count different things.

  **These are raw counts with citations, never classifications.** The cells carry numbers and cited constructs only. No cell, and no prose in this subsection, assigns a routine a complexity band, a risk rating, an effort or story-point estimate, a `simple`/`moderate`/`complex` label, or a migration-difficulty ranking — those are judgments the downstream planner makes FROM these numbers, and the report's non-goals (see Report Format) forbid them here. A metric that could not be computed is stated as unknown with the reason, never estimated.

  **Branch-counting basis (a stated-method heuristic — NOT cyclomatic complexity).** The Branches column is a reproducible keyword count on ONE declared basis, and the report restates that basis inline immediately below the table so any consumer can reproduce the number. The basis is fixed and is not renegotiated per report:
  - **Counted:** each `IF` that opens a conditional; each `ELSIF` / `ELSEIF`; each `WHEN` arm of a `CASE` statement or a `CASE` expression; each `WHILE` head that is NOT driving a cursor fetch loop; each `EXIT WHEN` / conditional `BREAK` that is NOT a cursor loop's own termination test.
  - **NOT counted:** `ELSE` arms (no condition is tested at an `ELSE` — the decision was already made at the `IF` or `WHEN` above it); `EXCEPTION WHEN` / `CATCH` handlers (error paths, reported in Dimension 4); `FOR` and bare `LOOP` iteration heads; `END IF` / `END CASE` terminators; and any of these keywords occurring inside a comment or a string literal.
  - **The double-count rule that decides the two loop cases above.** No construct is counted in both the Cursor Loops column and the Branches column. A loop that the Cursor Loops column already counts contributes its own termination test to Branches as `0` — this covers T-SQL's `WHILE @@FETCH_STATUS = 0` (in T-SQL EVERY cursor loop is a `WHILE`, so without this rule every T-SQL cursor is double-counted) and PL/SQL's `LOOP … FETCH … EXIT WHEN c%NOTFOUND` fetch loop. Conversely, a loop the Cursor Loops column does NOT count is not thereby invisible: a counter `WHILE @i <= @n`, and a bare `LOOP … EXIT WHEN <cond> … END LOOP;`, each contribute their one real decision point to Branches, so they land in exactly one column rather than neither. State which reading you applied for any loop where it is not obvious.

  Label the number for what it is: a keyword count on the basis above. It is not cyclomatic complexity, not a defect measure, and not an effort measure, and it is never presented as any of the three. The count needs lexical care — a naive `grep -c 'IF'` also matches `ELSIF` and `END IF` — so use word-boundary-aware patterns and let the pasted output show the separation.

- **Missing-Reference Table:** Every external reference pointing to an absent object. These are **not** fabricated — they are references found in the source code to objects whose definitions are not present in the provided files.

  | Source File:Line | Reference Type | Target | Impact |
  |-----------------|---------------|--------|--------|
  | 004-03-SP-Create_Post_Notifications.sql:64 | INSERT INTO | dbo.Notifications | Table definition not in source — CRUD matrix incomplete |
  | 002-01-FN-Calculate_Fee.sql:22 | EXEC | dbo.SP_Audit_Log | Dependency graph incomplete |
  | 005-TR-Update_Modified_Date.sql:15 | SELECT FROM | sys.server_principals | System catalog reference (external) |

- **Coverage Honesty Check:** State upfront what fraction of referenced objects the report actually saw. Example: "Analysis covers 42 of 45 referenced objects (93% coverage). 3 objects referenced but not defined: dbo.Notifications (table), dbo.SP_Audit_Log (sproc), dbo.FN_Legacy_Calc (function)."

- **Dead / Orphan Code:** Unreachable objects. Distinguish "confirmed dead — no caller found in provided files" vs "possibly dead — insufficient evidence" (may be called dynamically or from application code not in this dump).

### Dimension 2: Call & Dependency Graph

**Purpose:** Understand invocation chains so extraction can be sequenced (leaves first, hubs last).

- **Dependency Graph:** Hierarchical invocation map showing object→object calls:
  - Static calls: `EXEC dbo.ProcedureName`, `SELECT FROM dbo.FunctionName(...)`, trigger→sproc
  - Dynamic SQL edges: `sp_executesql`, `EXEC(@variable)`, `EXECUTE IMMEDIATE` — these are **reduced-confidence edges**
  - Format as indented tree or Mermaid diagram
  - Mark entry points: triggers (always entry points), top-level sprocs with no callers

- **Dynamic SQL flagging (CRITICAL):** Dynamic SQL calls (`sp_executesql`, `EXEC('...')` in T-SQL; `EXECUTE IMMEDIATE` in PL/SQL) evade catalog dependency views and static analysis. The dependency graph for any object using dynamic SQL must be flagged:
  - `[MEDIUM-CONF]` or `[LOW-CONF]` on the edge
  - Explicit note: "This object uses dynamic SQL — the graph shows at least these edges, possibly more. See `FILE:LINE` for the dynamic call."
  - The dialect reference file documents why these are blind spots.

- **External / Unresolvable Edges:** Every `EXEC` / `EXECUTE` target must be enumerated with a `FILE:LINE` citation. Calls to objects outside the analyzed source — system procedures (`sp_*`), extended procedures (`xp_*`), `master.` references, linked-server four-part names — are **external/unresolvable edges**. List each one with its citation. These represent server-surface coupling: behavior the application must absorb or replace at extraction time because it will not exist outside SQL Server.

- **Liveness Claims Require Citations:** Any claim that an object HAS callers must cite at least one caller `FILE:LINE`. If no caller is found in the analyzed source, report the object as "no caller found in analyzed source (possible external/application callers — unknowable from source alone)". Liveness claims without citations are fabrications like any other. This rule applies report-wide, not just in this dimension — see Hard Constraint 6.

- **Hub Objects:** Stored procedures or functions called by 3+ other objects, or calling 3+ other objects — counted over INVOCATION edges only (EXEC, function calls, trigger firing). Table-DML coupling (SELECT/INSERT/UPDATE/DELETE against tables) is Dimension 3's measure and is never counted as a "call" here. If no object reaches the 3+ threshold on invocation edges, state "No hub objects in the call graph" and cross-reference Dimension 3's hub resources — an empty hub list over the right edges beats a full one over the wrong edges. These are extraction bottlenecks. Like the CRUD matrix, the dependency graph is materialized as a scratch file FIRST (e.g., `calls.tsv`: one line per caller|callee|File:Line edge, written as you analyze) so hub counts can be computed by command before any hub prose exists. Compute each candidate's distinct-callee and distinct-caller counts by command over `calls.tsv` (e.g., `awk`/`sort -u`), and show your work: a fenced block with the exact command and its raw output immediately above the hub-object lines; each hub line's count transcribes that output. Procedure, per candidate object: (1) copy out that object's edges from the scratch file; (2) collapse the copied edges to DISTINCT named objects — the same object cited at two lines is ONE object, and "N objects" always means N distinct names, never an edge or citation count (if the edge count is also useful, state both explicitly: "5 objects across 9 edges"); (3) write the parenthesized enumeration of those distinct, cited objects first, then write its length as the count — the enumeration IS the count. A hub line whose number differs from its own enumeration, whose enumeration contains a duplicate or an uncited or unnamed member ("plus others", "via joins"), or whose members differ from that object's edges in the graph above, is a self-consistency failure. List members are named database objects only — tables, views, procedures, functions, triggers; cursors, `INSERTED`/`DELETED` pseudo-tables, operations, and clauses are never counted as objects. Close the list before writing any number: after the enumeration is on the page, recount the members actually written and use that recount — a count decided before its list existed is a fabrication even when it happens to be close.

- **Extraction Sequencing:** Based on the dependency graph, identify the leaves-first order for extraction. Example: "Extract in this order: (1) leaf functions with no dependencies; (2) mid-tier sprocs calling only functions; (3) hub sprocs; (4) triggers (always last — they invoke the chain)."

### Dimension 3: CRUD Matrix & Trigger Cascade Map

**Purpose:** Map which objects read/write which tables, and trace trigger→DML→trigger chains end-to-end. This determines which application-layer service owns which table after extraction.

- **CRUD Matrix (built as a scratch file FIRST — MANDATORY):** As you analyze, materialize the matrix rows into a scratch file in your working directory (e.g., `crud.tsv`: one line per Object|Resource|Type|CRUD|Pattern|File:Line). The matrix must exist ON DISK before any part of the report that cites it is written, because the tally below is computed by running commands against this file — numbers are produced first, prose copies them afterward. Then render the scratch rows as the report table:

  **PL/SQL read-side false positives (exclude before recording a Resource):** a bare `FROM <ident>` / `INTO <ident>` scan over PL/SQL captures non-tables — (1) `SELECT … INTO v_local` targets a local variable, not a table; (2) cursor variables and `%TYPE`/`%ROWTYPE` locals; (3) example `SELECT`/`UPDATE` statements embedded in `/* … */` header comments (common in ADempiere/Compiere headers). None of these is a table; recording one fabricates a resource.

  | Object | Resource | Type | C | R | U | D | Access Pattern | File:Line |
  |--------|----------|------|---|---|---|---|----------------|-----------|
  | dbo.SP_Create_Post | dbo.Posts | Table | X | | | | INSERT INTO | 004-01:45 |
  | dbo.SP_Create_Post | dbo.SP_Create_Post_Notifications | Sproc | | | | | EXEC | 004-01:67 |
  | dbo.FN_Get_User_Posts | dbo.Posts | Table | | X | | | SELECT FROM | 003-02:18 |
  | dbo.TR_Notify_Subscribers | dbo.Notifications | Table | X | | | | INSERT INTO (from trigger) | 005-TR:49 |
  | dbo.VW_Recent_Posts | dbo.Posts | Table | | X | | | SELECT (join) | 002-04:22 |

  Every object class appears in the matrix — stored procedures, functions, triggers, AND views alike, one row per (object, resource) pair. A matrix omitting an entire object class (e.g., no view rows) is incomplete and every count derived from it is wrong. `INSERTED`/`DELETED` pseudo-tables are never Resource values — record a trigger's pseudo-table read as a row against the trigger's base table (or omit it, stating which basis you chose); pseudo-table rows in the scratch file would force hand-editing of the tally output, which is forbidden.

  Highlight **hub resources** touched by 3+ objects. The hub-resource section is DERIVED from the CRUD matrix just written — it is a re-reading of the matrix rows, not a recollection of the analysis. Procedure, per resource: (1) scan the matrix's Resource column and copy out every row for that resource; (2) collapse the copied rows to DISTINCT Object values — one object appearing in several rows or citations is ONE object; (3) if the distinct-object list has 3+ members, the resource is a hub and MUST appear in this section — omitting a resource that qualifies by the matrix is a self-consistency failure; (4) write the hub line as the enumerated distinct objects, each with one File:Line copied from its matrix row, followed by the count as the length of that enumeration. Example shape: `dbo.Posts — SP_Create_Post (004-01:45), FN_Get_User_Posts (003-02:18), TR_Notify_Subscribers (005-TR:49), VW_Recent_Posts (002-04:22) — 4 objects (= length of this list)`. Before moving on, verify each hub line against the matrix: exactly the distinct objects of that resource's rows — same objects, no more, no fewer, no duplicates. Each hub gets ONE complete list, written once — never a partial list followed by an "additional objects" continuation, and never a running total that exceeds what is enumerated.

  **Resource Touch Tally (MANDATORY, placed immediately after the CRUD matrix, before any hub-resource line):** Compute the tally by running a command against the scratch file BEFORE writing this section — e.g., `awk -F'|' '{print $2, $1}' crud.tsv | sort -u | awk '{c[$1]++} END {for (r in c) print r, c[r]}'` — and paste the command's output as the table. Show your work: immediately above the rendered tally table, include a fenced code block containing the exact command you ran and its raw output, verbatim. The rendered table is a transcription of that raw output — a table value differing from the raw output above it, or raw output that re-running the shown command against the scratch file would not reproduce, is a self-consistency failure. The tally is the command's output, never a recalled number: one row for EVERY distinct Resource value in the scratch file, hub or not, with its distinct-object count and a Hub? column that is `yes` exactly when the count is 3+:

  | Resource | Distinct objects touching | Hub? (3+) |
  |----------|--------------------------|-----------|
  | dbo.Posts | 4 | yes |
  | dbo.Notifications | 2 | no |

  The hub-resource lines are then exactly the tally's `yes` rows: every `yes` row gets a hub line, no hub line without a `yes` row, and each hub line's header count and closing count both copy its tally count. The hub threshold counts ALL touching objects in the matrix — views, functions, procedures, and triggers alike; inventing an exclusion basis (e.g., "views don't count") is a fabrication. Because the tally is computed before any hub prose is written, there is nothing to "correct" afterward — if a written line disagrees with the tally, the line is wrong and is rewritten before the report is finalized; a correction note left standing next to an uncorrected number is a self-consistency failure. A matrix resource missing from the tally, or a `yes` row without a hub line, is a self-consistency failure.

- **Trigger Cascade Map:** Triggers are the single most invisible behavior in a database. Trace trigger→DML→trigger chains end-to-end, statically derived from the source.

  Example cascade:
  ```
  INSERT INTO dbo.Posts
    -> TRIGGER dbo.TR_Notify_Subscribers_On_New_Post (:15)
       -> EXEC dbo.SP_Create_Post_Notifications (:49)
          -> INSERT INTO dbo.Notifications (:64)
             -> [TRIGGER dbo.TR_Audit_Notifications (:22) — if defined]
  ```

  Each arrow cites `FILE:LINE`. If a trigger or sproc references a table that has no trigger definition in the source, note it: "Table `dbo.Notifications` referenced at :64 — no trigger definition found in source (may not exist, or may be missing from dump)."

  **The application must reimplement the entire cascade chain explicitly.** This is a CRITICAL finding if chains exist.

### Dimension 4: Transaction & Error-Handling Semantics

**Purpose:** Identify where commits/rollbacks happen, what is atomic together, and where errors are *swallowed*. Implicit boundaries must be deliberately reproduced or deliberately fixed in the application — either way, first seen here.

- **Transaction Boundaries:** Map explicit transaction control:
  - T-SQL: `BEGIN TRANSACTION`, `COMMIT`, `ROLLBACK`, savepoints (`SAVE TRANSACTION`)
  - PL/SQL: `COMMIT`, `ROLLBACK`, `SAVEPOINT`, autonomous transactions (`PRAGMA AUTONOMOUS_TRANSACTION`)
  - Cite `FILE:LINE` for each transaction boundary
  - Identify **atomic groups**: which operations are wrapped in a single transaction scope

- **Error Swallowing (CRITICAL):** Where errors are caught but not re-raised:
  - T-SQL: `BEGIN TRY ... END TRY BEGIN CATCH ... END CATCH` with no `THROW` or `RAISERROR` in the CATCH block
  - PL/SQL: `EXCEPTION WHEN OTHERS THEN NULL` or `WHEN OTHERS THEN RETURN;` with no `RAISE`
  - These are silent failure points. The application must decide: reproduce the swallow (likely wrong) or fix it (surface the error). Either way, this is a **HIGH or CRITICAL** finding.

- **Autonomous Transactions (Oracle-specific):** `PRAGMA AUTONOMOUS_TRANSACTION` writes survive rollback of the outer transaction. Typically used for audit logging. The application must replicate this "write regardless of outcome" behavior explicitly — it's not automatic outside Oracle.

- **Uncatchable Errors (T-SQL-specific):** SQL Server severity 20+ errors are not catchable by `TRY/CATCH`. If the source relies on catching these, flag it as a **CRITICAL** risk — the behavior will change in extraction.

### Dimension 5: Dialect Footguns & Hidden Risks

**Purpose:** Surface anything where naive reimplementation silently changes behavior. Use the loaded dialect reference file as the lens.

**Findings scratch file FIRST (`findings.tsv` — MANDATORY, same discipline as the CRUD matrix).** Dimension-5 claims fabricate more readily than any other section: invented `ISNULL`/`COALESCE` expressions, invented `CHECK` constraints with invented column names, invented hardcoded paths with invented variable names — each carrying a plausible-but-false `FILE:LINE` — are the characteristic failure mode. Prose instructions do not prevent it; a required output artifact does. So EVERY footgun is bound to disk before any Dimension-5 prose exists. Materialize findings into a scratch file `findings.tsv` in your working directory FIRST — one line per footgun: `Category|Scope|Object|File:Line|Evidence|Severity`. The section that follows is a transcription of this file, not a recollection of the analysis.

- **Categories:** `SECURITY_CONTEXT`, `NULL_SEMANTICS`, `HARDCODED_VALUE`, `CONSTRAINT_LOGIC`, `GLOBAL_STATE`, `OTHER`.
- **Scope** is `production` or `test`. Test scripts (identified in Context Intake) are searched separately; a footgun literal that appears ONLY in a test file is recorded with `Scope=test` and is **NEVER** attributed to a production object. A production finding MUST cite a production file. (A footgun-looking literal in an excluded test file bleeding into a production claim is a known, gating fabrication.)
- **Evidence** is the matched text copied verbatim from the search output — a paraphrase presented as a quote is fabrication.
- **A parameterized value is not a hardcoded value.** A path/server/name passed in as a procedure PARAMETER (e.g. `@ExportPath`) is caller-controlled — it is NOT a `HARDCODED_VALUE` and must not be flagged as one. Only a literal embedded in the source is hardcoded.

Every row is produced by an actual search command whose output is pasted. Consult the dialect file (`references/dialects/mssql.md` or `references/dialects/oracle.md`) for the footgun catalog, then run at least one search command per class over the PRODUCTION files — a class covering several distinct constructs runs one command per construct, and every one of them gets its output pasted — and immediately above the `findings.tsv` rows they produced, include a fenced code block with the exact command and its raw `grep -n` output verbatim. Every `File:Line` in `findings.tsv` is a real hit from that output; a citation is a transcription of a `grep -n` hit taken at search time, never a recalled or interpolated line number. Search classes:

- **Security context changes:** T-SQL `EXECUTE AS` (user/owner/caller) changes context mid-execution; PL/SQL `AUTHID DEFINER` vs `AUTHID CURRENT_USER`. The application must replicate the permission model explicitly.
- **NULL vs empty-string semantics:** search `ISNULL`, `COALESCE`, `NVL`, `''` literals in predicates. T-SQL `'' ≠ NULL` (and `ISNULL(col,'default')` behavior); PL/SQL `'' = NULL`.
- **Hardcoded values & environment names:** server names, database names, file paths (`[A-Za-z]:\`), IP addresses, connection strings embedded in SQL; business constants (rates, thresholds, limits). Externalize to config before extraction. (Remember the parameterized-value exclusion above.)
- **Business rules in constraints:** DDL `DEFAULT` clauses with logic (`DEFAULT GETDATE()`, `DEFAULT USER_ID()`) and `CHECK` constraints — DB-layer rules that must move to application validation.
- **Global & shared state (`GLOBAL_STATE`):** state that outlives a single call, or that is shared between routines — the first thing to break when logic moves into stateless application code. The class captures: package-level / module-level variable declarations and every read and write of them; temporary-table usage (Oracle global temporary tables and `TEMP_`/`TMP_` staging tables; T-SQL `#temp`, `##temp`, `tempdb..`); ambient session state (`SYS_CONTEXT`, `DBMS_SESSION`, `USERENV`; `CONTEXT_INFO`, `SESSION_CONTEXT`); and sequence consumption (`.NEXTVAL`/`.CURRVAL`, `NEXT VALUE FOR`). Run the dialect file's queries for this class — see **"Extraction-Metrics Detection Patterns"** in `references/dialects/oracle.md` / `references/dialects/mssql.md` — and paste the raw `grep -n` output as for every other class. **Record one `findings.tsv` row PER OBJECT per state resource, never one merged row per resource.** The row's `Object` is the routine that touches the resource and its `File:Line` is that routine's own touch site, because the fact the extraction team needs is which objects SHARE a resource, and that is derived by joining two rows on the same resource — a single row naming several objects destroys the join and cannot be counted. A write site and a read site of the same resource are separate rows, each with its own verbatim `Evidence`. Where a resource has exactly one toucher, say so and name it: a one-writer package variable is a materially weaker finding than a two-writer one, and the difference is only visible if both are recorded the same way. If the class returns no hits, state that explicitly with the empty output rather than dropping the class.
- **Other dialect-specific footguns:** consult the dialect file (T-SQL `MERGE` concurrency, Oracle `FORALL`, implicit cursors, etc.).

**The Dimension-5 report section is a transcription of `findings.tsv`'s production rows** — every footgun claim in the report is a `findings.tsv` row, and every production row appears in the report. A report claim with no backing row, or a row whose `File:Line` the pasted search output does not contain, is a fabrication. If in-context memory disagrees with `findings.tsv`, the file wins — re-read it. (The file wins only after the source-consistency precondition in Hard Constraint 9 confirms its citations resolve to the analyzed source set.) Report each finding with its `FILE:LINE`, its verbatim evidence, and its extraction implication.

## Hard Constraints

1. **Evidence-only.** Every claim MUST cite `FILE:LINE`. No citation = no claim. Quoted code must be verbatim from the cited line — re-read the line before quoting; paraphrase presented as quotation is fabrication — and line numbers must be re-verified at citation time.
2. **No hallucination.** Objects not in the provided files are **missing references**, never fabricated. This includes: catalog contents, column lists, trigger bodies, table schemas. If a table is referenced but not defined, it goes in the missing-reference table — do NOT invent its structure.
3. **Unknowns are valid.** State "Unknown — insufficient evidence" and note what artifact would resolve it (usually: "Export the full schema including table definitions — see dialect file appendix").
4. **Confidence tagging.** Tag major findings and every dynamic-SQL-derived edge:
   - `[HIGH-CONF]` — directly observed in source code
   - `[MEDIUM-CONF]` — inferred from patterns or partial evidence
   - `[LOW-CONF]` — speculative based on incomplete information (e.g., dynamic SQL edge with variable target)
5. **Self-consistency (MANDATORY).** Before the report is written, re-derive every summary count from the report's own itemized lists. If a summary number disagrees with the itemized list, the list wins and the number is corrected. The excluded-files list length must equal the excluded-files count. Placeholders like "(N additional files...)" are forbidden — every file in a count is named, or the count is wrong. This applies to ALL summary statistics, not just object counts: every total (LOC, counts, any aggregate) must equal the sum or length of the report's own itemized data — recompute totals from the table, never carry a separately-remembered number. Every subtotal and total presented in the report must be computed by actually summing the itemized column at the moment of writing; where a total appears alongside its breakdown, the breakdown's sum IS the total — write the sum of the parts, and if a remembered number differs from the freshly-computed sum, the sum wins. Counted relationship claims ("N views touch table X") are aggregates too: N must equal the number of listed or citable instances.
6. **Usage claims are liveness claims — everywhere.** ANY claim anywhere in the report that an object is used by, called by, or referenced by another object requires a caller `FILE:LINE` citation — including manifest flag columns (e.g., "Used by 3 sprocs"), hub tables, and summary prose, not only the Dimension 2 liveness section. Before the report is written, cross-check usage claims in every section against the dependency/liveness findings — a manifest flag that contradicts the liveness table is a self-consistency failure.
7. **Counts are list lengths; totals are column sums.** Every number in this report that counts or totals anything — objects, files, callers, touches, LOC — is produced by first writing the itemized list, table, or enumeration, and then writing its length or sum as the number. Where a total appears alongside a breakdown, show the addition inline with the actual subtotals (e.g., `Grand total: 2,940 LOC (= 1,212 + 733 + 402 + 371 + 180 + 42)`). A count that cannot be paired with its own enumeration in the report is not written. Units are never conflated: a count of "objects" counts distinct named objects after collapsing duplicate rows, edges, or citations; a count of touches, rows, edges, or citations is a different number and must be labeled as what it is. Sections that appear before the Component Manifest (e.g., documentation verification) may not state LOC or object totals from memory — compute the manifest totals first and reuse those exact numbers everywhere else in the report.
8. **Aggregates are computed by command, once, then copied.** Every aggregate number in the report — LOC totals, object counts, coverage fractions, percentages — is computed exactly ONCE, mechanically (`wc -l`, `awk`, `bc`, or equivalent: run the command and use its printed result, never head-arithmetic), in the section that owns it: the Component Manifest owns object counts and all LOC totals; the CRUD matrix owns touch counts. Every other place that states such a number — executive summary, documentation verification, coverage declarations, manifest flag columns, closing prose — COPIES the owning section's number verbatim; it is never re-derived, re-counted, or recalled. If a section that needs the number would otherwise be written first, write the owning section first. Object counts, file counts, and coverage fractions are aggregates too: file counts come from `find ... | wc -l` output pasted once; a coverage fraction is written as (manifest object count) of (manifest object count + missing-reference table row count), both operands copied from their owning sections and the division done by command — never freshly recalled or re-counted in prose. Two different values for the same quantity anywhere in the report is a self-consistency failure. The numbers appearing in this skill's examples and templates (counts, LOC figures, percentages) are illustrations from a fictional blog system — none of them ever appears in a real report unless your own commands independently produce the same value; an example number surfacing as your object count or coverage figure means the number was copied, not computed. Head arithmetic is banned at EVERY scale, including sums that look too small to get wrong: a two-term total (production LOC + test LOC), a type-breakdown object count (1 + 10 + 5 + 4 + 3 + 2), an N-of-M coverage fraction — run the command (`echo $((a+b))`, `bc`) and use its output. Wherever a breakdown is displayed next to its total, the parts as printed must sum to the total as printed — verify that equality by command before finalizing; a breakdown whose displayed parts do not sum to its displayed total is a self-consistency failure no matter how small the numbers are.
9. **Scratch files are the source of truth; proof blocks must reproduce (scale rule).** Every scratch file (`metrics.tsv`, `crud.tsv`, `calls.tsv`, `findings.tsv`) is the SINGLE source of truth for the numbers, rows, and citations derived from it. As a corpus grows, an in-context working set drifts from the on-disk file; when they disagree, the FILE wins — re-read it, and never assemble a table, tally, or findings section from recollection. State each scratch file's row count from its own `wc -l` output, and make the report's claimed matrix / graph / findings row count equal that number — a claimed row count that differs from `wc -l` of the file it summarizes is a self-consistency failure. As the LAST step before finalizing, re-run each proof-block command verbatim against its on-disk scratch file and confirm the rendered numbers equal the fresh output; a proof block whose command, re-run against the file, does not reproduce the numbers shown is corrected (or the report is not finalized). Every `FILE:LINE` citation is a transcription of a `grep -n` (or equivalent) hit taken at citation time — never recalled or interpolated. In files where SQL is a small fraction of the content — e.g. SSMS View-Designer metadata blocks (`Begin PaneConfigurations`, `Begin CriteriaPane =`, `Width = <n>`, bare `End`) — a citation that lands on a metadata line instead of the cited SQL statement is a fabrication; re-verify the line by re-reading it before quoting. **Source-consistency precondition (guards the file-wins rule).** The file wins only once it is confirmed to describe THIS analysis: before trusting scratch content over memory, and again as the last step before finalizing, verify that every `File`/`File:Line` cited in the scratch files resolves to a file in the **analyzed source set** (the Step-1 glob) — compare each scratch File basename against the source-file basenames. A scratch row citing a file OUTSIDE that set is contamination (e.g., another system's objects from a clobbered scratch): HALT, discard the scratch directory, and rebuild in a fresh scratch dir rather than transcribing it into the report.

## Severity Definitions

Severity is reworded for extraction migration (not porting between database engines):

| Severity | Definition |
|----------|-----------|
| **CRITICAL** | Will cause data loss or silent behavior change if extraction proceeds without addressing this finding. Examples: trigger cascades not reimplemented, error swallowing, autonomous transaction semantics lost. |
| **HIGH** | Significant risk or behavior-change surface. Must be addressed in extraction planning. Examples: security context changes, missing dependencies, hardcoded business rules. |
| **MEDIUM** | Notable complexity or hidden coupling. Should be addressed but won't cause silent failure. Examples: hub objects with many dependents, dynamic SQL reducing graph confidence. |
| **LOW** | Minor issue or complexity note. Address opportunistically. Examples: orphaned objects, encoding quirks. |

## Output File

**MANDATORY:** Write the final report to a `reports/` directory inside the **original invocation directory** captured in Step 1 — use the literal `$ORIG` path recorded in Step 1 (`$ORIG/reports/{SYSTEM-NAME}-SPROC-XRAY.md`), NOT the current working directory (after Step 1 that is the scratch dir, which cleanup deletes). Create the directory if it does not exist. Derive the system name by uppercasing the repository or directory name **verbatim** — do not abbreviate, strip suffixes, or reword (e.g., repo `BlogPlatformDB` becomes `BLOGPLATFORMDB`, not `BLOGPLATFORM`; repo `ADempiere` becomes `ADEMPIERE`). Example: `$ORIG/reports/BLOGPLATFORMDB-SPROC-XRAY.md`. Do NOT only print the report to the console — it MUST be persisted as a file. Do NOT write the report to `~/.claude/` or any other user-config directory.

## Report Format

Structure the report exactly as follows:

```
## Executive Summary — Critical Red Flags

Ranked, cited, severity-tagged concrete hazards. NOT a score, NOT a verdict.

- **[CRITICAL]** Trigger cascade chain not in application code: INSERT dbo.Posts -> TR_Notify_Subscribers -> SP_Create_Post_Notifications -> INSERT dbo.Notifications (005-TR:15, 004-03:49, :64)
- **[HIGH]** Error swallowing in CATCH block with no rethrow: dbo.SP_Process_Payment (004-05:78-82)
- **[HIGH]** Missing table reference: dbo.Notifications inserted but no CREATE TABLE in source (004-03:64)

---

## Coverage Declaration

This section is positioned FIRST in the report but is WRITTEN LAST: leave it for the end, after the Component Manifest and Missing-Reference Table exist, then fill it by copying their values. Every number on these lines is a copy of an artifact value, never freshly produced here: the object count copies the Component Manifest's grand count; the file count copies the pasted `find ... | wc -l` output from Context Intake; the missing count is the Missing-Reference Table's distinct-target count, and the referencing objects named here are copied from that table's Source column — no referencer is named here that lacks a row there; the coverage fraction's operands are those same two numbers. One count per quantity — never a second, differently-based object or file count on these lines unless explicitly labeled with its basis and its own shown arithmetic. The placeholders below are tokens, not example values — there is no number in this template to reuse:
- **Objects provided:** `<manifest grand count>` objects across `<find|wc file count>` files (`<per-type counts from manifest subtotals>`) — provided means DEFINED in the source; a referenced-but-missing object is never part of this count or its breakdown, it belongs only on the missing line below
- **Objects referenced but missing:** `<missing-reference table distinct-target count>` (`<targets copied from that table>`)
- **Estimated coverage:** `<computed by command from the two counts above>`% of referenced objects analyzed
- **Reduced-confidence dimensions:** Dimension 2 dependency graph — 2 sprocs use dynamic SQL (`sp_executesql`), edges flagged `[MEDIUM-CONF]`
- **Key gaps:** Table schemas incomplete — only CREATE scripts provided, no full DDL export with constraints/defaults. See mssql.md appendix for export instructions.

---

## 1. Inventory & Completeness
[Component manifest table, missing-reference table, coverage honesty check, dead/orphan code findings]

### Extraction Metrics
[Per-routine table with exactly these columns — Object | Params | Cursor Loops | Branches | UDT Usage | File | LOC — transcribed from `metrics.tsv`; the proof block of computing commands and their raw output sits immediately above the table, and the stated branch-counting basis immediately below it. One row per defined routine and trigger, all-zero rows included, `0` written not blank. Raw counts and cited constructs only — no complexity band, risk rating, or effort estimate]

## 2. Call & Dependency Graph
[Dependency graph with dynamic-SQL flagging, hub objects, extraction sequencing]

## 3. CRUD Matrix & Trigger Cascade Map
[CRUD matrix, hub resources, trigger cascade chains end-to-end with FILE:LINE citations]

## 4. Transaction & Error-Handling Semantics
[Transaction boundaries, atomic groups, error swallowing findings with FILE:LINE, autonomous transactions, uncatchable errors]

## 5. Dialect Footguns & Hidden Risks
[Security context, NULL semantics, hardcoded values, business rules in constraints, other dialect-specific findings — all cited FILE:LINE]

---

## Confidence & Coverage Declaration

Every number and verdict on these closing lines is COPIED from the section that owns it (manifest,
context intake, missing-reference table, documentation-verification table) — nothing here is
recomputed, re-derived, or newly totaled; a closing line stating a number or verdict that appears
nowhere earlier in the report is a self-consistency failure.

- **Files analyzed:** [count] of [count] provided
- **Artifact types covered:** [list from context-intake table]
- **Missing artifacts affecting analysis:** [what's absent and what dimension it impacts]
- **Encoding/format issues encountered:** [if any — e.g., ISO-8859 files, mixed CRLF/LF, non-English comments]
- **Binary DB files (unparsed):** [names, or "None"] — contents not parsed; script out definitions (DDL export) and re-run for authoritative analysis.
- **Path mismatches:** [if README vs reality differs, note it honestly]

---

## Recommended Next Steps

This section names the downstream consumer of this report, and the optional evidence that
would sharpen what that consumer can do — and nothing else. It is a
RECOMMENDATION the reader may take or ignore — this report does not invoke anything, and
no step below runs automatically. It states no migration pattern, no target architecture,
no effort estimate, and no priority ranking; those remain non-goals of this report.

- **Downstream planner:** the `sproc-migration-plan` skill consumes this report — specifically
  the `### Extraction Metrics` table and the Dimension-5 `GLOBAL_STATE` rows — to sequence and
  size the extraction. Hand it the path to this file.
- **Binary DB export path:** If a binary DB file was found (Context Intake), script out its
  definitions before re-running this skill — SSMS *Generate Scripts* or `mssql-scripter`
  (SQL Server), `DBMS_METADATA.GET_DDL` (Oracle).
- **Optional runtime evidence pack:** static source cannot show call frequency, row volumes, or
  which routines are actually invoked in production. If an execution-statistics export is
  available (Oracle AWR / `v$sql`; SQL Server Query Store / `sys.dm_exec_procedure_stats`),
  supplying it alongside this report lets the planner separate hot paths from dead weight.
  State here whether such a pack was provided — absence is stated explicitly, never implied.
```

Both coverage sections in the template are REQUIRED in full — every line item shown appears in every report. A line item whose answer is empty is stated explicitly rather than omitted (e.g., `**Reduced-confidence dimensions:** None — no dynamic SQL detected in the analyzed source; Dimension 2's dynamic-SQL confidence flagging is unexercised in this analysis`). Omitting a coverage line item is a report-format violation.

Use `sql` or `tsql` or `plsql` fenced code blocks for illustrative snippets. Use evidence-based language throughout ("In `004-03-SP-Create_Post_Notifications.sql` line 64...").

**Deliberately absent from this report (non-goals):**
- No overall readiness score or migration score
- No target-architecture recommendation (downstream session decides)
- No migration-pattern recommendation (rehost/replatform/rewrite)
- No effort estimates or story-point sizing
- No sproc-to-sproc translation guidance

The report ends where the evidence ends.

**Oracle orientation (when the dialect is PL/SQL):** Oracle routine sets are typically prefix-less and package/schema-qualified — do not expect `dbo.` / `sp_` / `TR_` naming; the examples above are illustrative T-SQL from a fictional system. For a trigger-less, routine-only Oracle corpus, the Trigger Cascade Map and hub sections legitimately come back empty — state "None" per the explicit-empty-case rules rather than forcing a cascade narrative.

### Empty-Scope Compact Report (short-circuit)

When the Dimension 1 empty-scope short-circuit gate fires, this compact report REPLACES the full five-dimension template above — never produce both. `sproc-migration-plan`'s input validator keys its intake acceptance on the `### Extraction Metrics` heading, one of the two unique dimension titles (`## 3. CRUD Matrix & Trigger Cascade Map` or `## 5. Dialect Footguns & Hidden Risks`), and `## Coverage Declaration`; a report missing any of those is bounced as stale. This compact report keeps exactly that skeleton, with an explicitly empty body at each marker, and drops everything else — no form→table CRUD matrix content, no injection-site enumeration, no application-layer "analogue" findings for any dimension, and no Recommended Next Steps pointing at an application-layer refactor, no matter how much logic the application layer itself holds (that analysis is out of this skill's charter regardless):

```
## Executive Summary — Critical Red Flags

None — 0 DB-resident routines found.

[Source-file glob command and its raw output showing 0 matches, then the
`CREATE (PROCEDURE|FUNCTION|TRIGGER|PACKAGE)` search command and its raw output showing 0
matches — pasted verbatim per the skill's existing proof-block discipline. This is the
headline finding's proof; nothing below repeats it.]

---

## Coverage Declaration

- **Objects provided:** 0 objects across `<find|wc file count>` files — the empty routine set is fully covered
- **Objects referenced but missing:** 0
- **Estimated coverage:** 100% (0 of 0 referenced objects)
- **Reduced-confidence dimensions:** None — no routines to analyze
- **Key gaps:** None

---

## 1. Inventory & Completeness

0 stored procedures, 0 functions, 0 triggers, 0 packaged routines (proof above). [A single
factual line on where the logic actually lives is permitted here — e.g., "All DB access is
inline application SQL (parameterized ADO.NET `CommandType.Text` calls)" — as context for
the 0-finding, never as application-layer analysis.]

### Extraction Metrics

0 routines/triggers defined.

## 3. CRUD Matrix & Trigger Cascade Map

None — 0 routines.

## 5. Dialect Footguns & Hidden Risks

None — 0 routines.

---

**STOP.** Analysis complete: 0 DB-resident routines in scope. This skill's charter is
DB-resident logic extraction; application-layer code — and any refactor of it — is out of
charter and is not analyzed here.
```

The Extraction Metrics column contract, `metrics.tsv`, and the LOC/UDT rules earlier in Dimension 1 are unchanged by this short-circuit — they govern the non-empty case exactly as written; the compact report's `### Extraction Metrics` body is empty because there is nothing to tabulate, not because the contract stops applying.

## Cleanup

**MANDATORY:** After the report has been written, remove the per-run scratch directory created in Step 1 — `cd "$ORIG"` then `rm -rf "$WORK"` (use the literal paths recorded in Step 1). This runs for EVERY analysis (the scratch dir is always created, for local-path and GitHub input alike) and removes both the clone, if any, and all scratch files. Do NOT leave scratch directories in `/tmp/` or any other temporary location.

