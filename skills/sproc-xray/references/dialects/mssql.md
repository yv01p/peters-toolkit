# MS SQL Server (T-SQL) Dialect Reference

T-SQL (Transact-SQL) is Microsoft SQL Server's procedural extension to SQL. This reference provides the dialect-specific facts that sproc-xray uses when analyzing T-SQL codebases for extraction migration.

## Stored Procedure and Function Model

T-SQL procedures and functions are top-level objects in a schema. The default schema is `dbo`; named schemas like `audit`, `reporting`, or `billing` are also common. There is no Oracle-style "package" concept — each procedure and function is a separate schema object.

Both `CREATE PROCEDURE` and `CREATE OR ALTER PROCEDURE` (introduced in SQL Server 2016) are common. The same applies to functions: `CREATE FUNCTION` and `CREATE OR ALTER FUNCTION`.

Identifier quoting uses the `[bracketed]` form by default. `"double-quoted"` identifiers are also valid when `QUOTED_IDENTIFIER` is `ON`, which is the typical default for stored procedures.

## NULL Semantics

**Empty string is distinct from NULL in T-SQL.** This is the inverse of Oracle's behavior.

- `'' IS NULL` returns **false** in T-SQL (returns **true** in Oracle).
- Concatenating `NULL` with any other value returns `NULL` by default (SQL-standard behavior; Oracle's `||` concatenation collapses `NULL` to empty string unless `CONCAT_NULL_YIELDS_NULL` is set to `ON`).
- Comparisons with `NULL` follow standard three-valued logic: `WHERE x = NULL` never matches; use `WHERE x IS NULL`.
- There is no native null-aware equality operator (no `IS NOT DISTINCT FROM`). Engineers commonly emulate it with `(a = b OR (a IS NULL AND b IS NULL))` or use `EXISTS (SELECT a INTERSECT SELECT b)` as a terser idiom.

**Migration impact:** Any Oracle code that relies on `'' IS NULL` returning true will break if naively translated to T-SQL.

## Trigger Model

T-SQL DML triggers are `AFTER` (also written `FOR`) or `INSTEAD OF`. **There is no `BEFORE` trigger in T-SQL** — this is the most common Oracle-to-T-SQL surprise.

Triggers run at **statement granularity by default**. Row-level access to changed rows is provided via the `INSERTED` and `DELETED` virtual tables, both of which contain **all rows affected by the firing statement**. What looks like "row-level" logic in T-SQL is implemented as set-oriented operations against these tables.

A single trigger can declare multiple events: `FOR INSERT, UPDATE, DELETE` (comma-separated). Multiple triggers per event are allowed. Their firing order is non-deterministic by default, but `sp_settriggerorder` can pin the first and last triggers explicitly.

T-SQL also supports **DDL triggers** at database scope (`ON DATABASE`) and server scope (`ON ALL SERVER`), which fire on schema-modification events (CREATE, ALTER, DROP). These expose exception handlers via `BEGIN TRY/CATCH` blocks inside the trigger body.

There is no T-SQL equivalent of Oracle's "compound trigger." Multi-phase logic is implemented as separate triggers or as conditional branches inside one trigger body.

## Exception Handling

T-SQL uses `BEGIN TRY ... END TRY BEGIN CATCH ... END CATCH` for structured exception handling.

Inside a `CATCH` block, error metadata is available via:
- `ERROR_NUMBER()`
- `ERROR_MESSAGE()`
- `ERROR_LINE()`
- `ERROR_PROCEDURE()`
- `ERROR_SEVERITY()`

Errors are raised using `THROW` (modern, rethrows the active error when used with no arguments) or `RAISERROR` (legacy, more verbose). With arguments, the form is `THROW error_number, message, state` — the third argument is STATE, not severity; `THROW` always raises at severity 16 (hence always catchable).

**Error swallowing risk:** A `CATCH` block that does not re-throw the error (via `THROW;` with no arguments, or `RAISERROR`) silently swallows it. This is the same risk as Oracle's `EXCEPTION WHEN OTHERS THEN NULL` — a common source of "the procedure returned success but the transaction was rolled back" bugs.

**Uncatchable errors:** Severe errors (severity 20+, fatal connection errors) are not catchable. These bypass `CATCH` blocks and terminate the connection.

## Dynamic SQL and Dependency Tracking

T-SQL supports two dynamic SQL mechanisms:

1. **`sp_executesql`** (preferred): Runs a dynamically constructed SQL statement with parameter binding.
   - Example: `EXEC sp_executesql N'SELECT * FROM t WHERE id = @id', N'@id int', @id = 5`
   - Parameter-safe (avoids SQL injection when used correctly)

2. **`EXEC('...')`** (legacy): Executes a string as SQL with no parameter binding.
   - Typical SQL-injection vector when the query string is built from user input

**Critical limitation:** Dynamically referenced objects **do not appear in `sys.sql_expression_dependencies`**. This means:
- The dependency graph underreports edges out of any procedure that uses dynamic SQL.
- Static analysis tools (including catalog views) cannot see what a procedure calls if the call is constructed at runtime.
- Sproc-xray flags dynamic SQL edges as **reduced-confidence** (`[MEDIUM-CONF]` or `[LOW-CONF]`) in the dependency graph.

**Migration impact:** Any procedure using `sp_executesql` or `EXEC(@variable)` requires manual inspection to discover its true dependency footprint.

## MERGE Statement

`MERGE` performs a single-statement upsert (insert/update/delete based on a join condition). T-SQL's `MERGE` has had a checkered correctness history: multiple concurrency bugs in multi-writer scenarios have been documented over the years. Many shops standardize on separate `INSERT` / `UPDATE` / `DELETE` statements for safety.

**Migration risk:** A `MERGE` block needs analysis for the specific upsert semantics it implements. Target languages typically lack a single equivalent statement, and the naive translation can introduce race conditions under concurrent writes.

## OUTPUT Clause

The `OUTPUT` clause on `INSERT`/`UPDATE`/`DELETE`/`MERGE` returns affected rows (or before/after columns from `INSERTED` / `DELETED`) as a result set or into a target table.

This is the T-SQL idiom for:
- Capturing surrogate-key values generated by an `INSERT` (e.g., `OUTPUT INSERTED.ID`)
- Logging row-level changes inline with the DML (e.g., `OUTPUT DELETED.*, INSERTED.* INTO @audit_table`)

**Migration risk:** `OUTPUT INTO @audit_table` patterns combine "the write" and "the audit" **atomically**. The target architecture must preserve that atomicity, typically via a transactional outbox or an audit-trigger equivalent.

## Security Context: EXECUTE AS

`CREATE PROCEDURE ... WITH EXECUTE AS OWNER` (or `CALLER`, `SELF`, or a named user) sets the security context the procedure body runs under.

- **`EXECUTE AS OWNER`** is roughly the T-SQL analogue of Oracle's `AUTHID DEFINER`.
- **`EXECUTE AS CALLER`** (the default if no clause is specified) is the analogue of Oracle's `AUTHID CURRENT_USER`.

**Migration implications:**
- Any target architecture must replicate the privilege boundary, typically via service accounts or dedicated database roles per service.
- Mixing `OWNER` and `CALLER` procedures across the same call chain is a common audit-trail confusion.
- Sproc-xray flags any use of `EXECUTE AS` as a security-context boundary that the extraction migration must preserve.

## Autonomous Transactions

**T-SQL has no direct equivalent of Oracle's `PRAGMA AUTONOMOUS_TRANSACTION`.**

Where Oracle code uses autonomous transactions for audit logging that must persist across a parent rollback, T-SQL implementations typically use:
- A loopback linked server
- A Service Broker queue
- An out-of-process logging path (Windows Event Log, file system, external service)

**Migration detection:** Sproc-xray flags any of these patterns in the deep analysis phase as autonomous-transaction-equivalent infrastructure. Look for:
- Linked-server calls to the same database (loopback pattern)
- Service Broker `SEND` operations in `CATCH` blocks
- Calls to `xp_logevent`, file-system CLR procedures, or external HTTP endpoints in error-handling paths

## Extended Stored Procedures (`xp_*`)

Extended procedures (`xp_fileexist`, `xp_fixeddrives`, `xp_create_subdir`, `xp_logevent`, etc.) live in `master` and execute native code on the SQL Server host machine. They touch the host OS directly — filesystem, registry, drives — and are a hard coupling to the DB server machine that is invisible to portability analysis unless explicitly surfaced. Sproc-xray must enumerate every `xp_*` call with `FILE:LINE` and classify it as an external/unresolvable edge representing server-surface coupling the application must absorb or replace.

## Extraction-Metrics Detection Patterns

Dimension 1's `### Extraction Metrics` table is computed by command, not read off the source by eye. These are the T-SQL patterns each column is searched with. Every pattern is a starting point whose RAW output goes into the report's proof block; the count is the length of the hit list after the stated exclusions are removed, so the exclusions below matter as much as the matches, and each removal is named with its line.

### Parameter lists

T-SQL parameters are the `@`-prefixed declarations between the object name and the `AS` that opens the body — parenthesised or not, and one per line by convention:

```bash
grep -niE '^[[:space:]]*CREATE[[:space:]]+(OR[[:space:]]+ALTER[[:space:]]+)?(PROCEDURE|PROC|FUNCTION)[[:space:]]' sql/
```

- Read each declaration from the object name through the `AS` (procedures) or the `RETURNS` clause (functions), and count the comma-separated `@param` formals. One count per formal regardless of `OUTPUT`/`OUT`, `READONLY`, or a `= <default>` value.
- **Only the parameter list counts.** `DECLARE @x …` statements inside the body are local variables, not parameters, and the `@`-sigil makes them look identical to a naive grep — bound the search to the declaration region.
- A function's `RETURNS <type>` clause is the return type, never a parameter. For a table-valued function, `RETURNS @t TABLE (…)` names a return variable and its column list — neither the variable nor its columns are parameters.
- A procedure with no parameters has `0`. `0` is written; the row is not omitted and the cell is not left blank.

### Cursor loops

T-SQL has no cursor `FOR` loop; every cursor loop is an explicit declare/open/fetch cycle:

```bash
grep -niE 'DECLARE[[:space:]]+[^[:space:]]+[[:space:]]+CURSOR|OPEN[[:space:]]+|FETCH[[:space:]]+NEXT|CLOSE[[:space:]]+|DEALLOCATE[[:space:]]+|WHILE[[:space:]]+@@FETCH_STATUS' sql/
```

- The canonical shape is `DECLARE <c> CURSOR FOR <select>` → `OPEN <c>` → `FETCH NEXT FROM <c> INTO …` → `WHILE @@FETCH_STATUS = 0 … END` → `CLOSE` / `DEALLOCATE`. **Count the loop once per cursor**, not once per `FETCH` — the priming fetch before the `WHILE` and the fetch inside it belong to the same loop.
- **A `WHILE` that is not driven by a cursor is not a cursor loop.** `WHILE @i <= @n` over a counter, or a `WHILE` draining a `@table` variable with `DELETE … OUTPUT`, iterates rows without a cursor; it is a branch keyword (below), not a cursor loop. Record it in the branch count only.
- **A cursor DECLARATION is not a loop.** A declared-but-never-opened cursor is noted as such, not counted.
- **Nesting is depth, not one loop.** An inner cursor inside an outer cursor's `WHILE` body is TWO cursor loops; report the count and state the nesting depth alongside it.
- Set-based DML (`UPDATE … FROM`, `MERGE`) processes many rows with no loop at all and contributes `0` here — that is a real `0`, not a gap.

### Branch keywords

Dimension 1 fixes the branch basis — counted: `IF`, `ELSE IF`, `CASE` `WHEN` arms, `WHILE`; not counted: bare `ELSE`, `CATCH` handlers, `END`/`END IF` terminators.

```bash
grep -niEw 'IF|ELSE|CASE|WHEN|WHILE|BEGIN|END|CATCH' sql/
```

- **`ELSE IF` is a nested `IF` and counts once, as the `IF`.** A bare `ELSE` does not count — no condition is tested there.
- `WHEN` is overloaded. A `CASE … WHEN` arm counts. A `MERGE`'s `WHEN MATCHED` / `WHEN NOT MATCHED [BY SOURCE|TARGET]` clauses are DML routing, not body branches — record them in Dimension 3 with the `MERGE`, and if you choose to count them here, say so and apply it to every `MERGE` in the corpus.
- `CASE` is an expression in T-SQL, never a statement; it appears in `SELECT` lists, `SET`, `WHERE`, and `ORDER BY`. Its `WHEN` arms count wherever it appears.
- `BEGIN`/`END` are block delimiters, not branches. `BEGIN TRY` / `BEGIN CATCH` are error handling (Dimension 4), never branch points.
- `GOTO` and `RETURN` are early exits, not branch points on this basis. If a corpus leans on them, note that fact in prose rather than folding it silently into the number.
- Keywords inside `--` and `/* … */` comments, inside string literals, and inside SSMS View-Designer metadata blocks are not code.

### User-defined types in signatures

T-SQL's user-defined type surface is narrower than Oracle's and lives entirely in the declaration:

```bash
grep -niE 'READONLY|CREATE[[:space:]]+TYPE|AS[[:space:]]+TABLE|EXTERNAL[[:space:]]+NAME|ASSEMBLY|hierarchyid|geography|geometry|sql_variant|xml' sql/
```

- **Table-valued parameters (TVPs)** — a parameter whose type is a user-defined table type, mandatorily `READONLY`. `READONLY` in a parameter list is the reliable TVP marker; the type itself comes from a `CREATE TYPE … AS TABLE (…)` that may or may not be in the provided source (if it is not, it is a missing reference, not an invented shape).
- **CLR / assembly types** — a `CREATE TYPE … EXTERNAL NAME <assembly>.<class>` alias, or a parameter typed by one. These carry host-machine coupling as well as a type.
- **System types with no plain application equivalent** — `hierarchyid`, `geography`, `geometry`, `sql_variant`, and `xml` are not user-defined, but a signature carrying one is the same extraction problem the column exists to surface. Record them, labeled as system types so the distinction is not lost.
- **Signature only.** A `DECLARE @t <table type>` local, or a `CREATE TYPE` sitting in the DDL that no signature uses, is not a signature UDT.
- A routine whose signature carries none of these gets the literal word `none`, never a blank cell.

### Global and shared state (the `GLOBAL_STATE` footgun class)

State that outlives one call, or that is shared between routines. Record one `findings.tsv` row per OBJECT per resource — cluster detection joins two objects on one shared resource, so a merged row naming several objects destroys the finding.

```bash
# temp tables: session-scoped (#) and global (##), plus explicit tempdb references
grep -nE '#{1,2}[A-Za-z_][A-Za-z0-9_]*' sql/
grep -niE 'tempdb\.\.|tempdb\.dbo\.' sql/
# ambient session state
grep -niE 'CONTEXT_INFO|SESSION_CONTEXT|sp_set_session_context' sql/
# sequences
grep -niE 'NEXT[[:space:]]+VALUE[[:space:]]+FOR|CREATE[[:space:]]+SEQUENCE' sql/
# server- and database-scoped configuration read as state
grep -niE 'SET[[:space:]]+ROWCOUNT|@@SPID|@@IDENTITY|SCOPE_IDENTITY|@@TRANCOUNT' sql/
```

T-SQL has no package construct, so its shared state is table- and session-shaped instead of variable-shaped. What to record:

- **`##global` temp tables are the sharpest finding here.** A `##` table is visible to EVERY session on the server and lives until its creator disconnects, so two routines — or two concurrent invocations of one routine — collide on it. Record the creating routine and every touching routine as separate rows.
- **`#local` temp tables** are session-scoped, and that is broader than a single call: a `#temp` created by an outer procedure is visible to every procedure it calls, which is a documented, load-bearing handoff channel with no invocation edge to show it. Record the creator and each consumer separately; a `#temp` created and dropped inside one routine is intra-call scratch and is recorded as such, not as shared state.
- **`CONTEXT_INFO` / `SESSION_CONTEXT`** are ambient per-connection key/value state, commonly set by a login procedure or the application and read far away — the T-SQL analogue of Oracle's `SYS_CONTEXT`. Under a **connection pool** the value outlives the logical request and leaks into whichever request reuses the connection. Cite every read and every write with its object, and state occurrences AND distinct objects as two separate labeled numbers.
- **Sequences** (`NEXT VALUE FOR <seq>`) are shared, cross-session, gap-prone counters. Record the sequence's definition site and each consuming routine. `IDENTITY` columns are table-scoped rather than shared and belong in Dimension 3, but `@@IDENTITY` (connection-scoped, and wrong across triggers) is session state — record it here with the reason.
- **Session `SET` options** (`SET ROWCOUNT`, and the `SET ANSI_NULLS` / `SET QUOTED_IDENTIFIER` pair captured at create time) change behavior for the rest of the session, not just the statement. Where a routine sets one and does not restore it, that is state escaping the call.
- If a class returns no hits, state that explicitly and show the empty output. An unlisted class reads as "not searched".

## Silent-Behavior Footguns (Migration)

These are T-SQL constructs whose behavior silently changes meaning when logic is extracted to application code or ported to PostgreSQL/Oracle — code that compiles and runs but produces different results, data, or side effects. They rarely surface as errors, so migration tools miss them and only production divergence reveals them.

### Strings and comparison

- **Trailing-space equality.** `=` pads the shorter operand per SQL-92, so `'abc' = 'abc   '` is TRUE — across CHAR/VARCHAR boundaries. PostgreSQL `text`/`varchar` and Oracle `VARCHAR2` compare non-padded and return FALSE, silently dropping rows that used to match. `LIKE` is the exception: it does **not** pad the right-hand value, so `col = 'abc '` and `col LIKE 'abc '` can disagree within T-SQL itself.
- **`LEN()` excludes trailing spaces.** `LEN('Hello ')` returns 5; PostgreSQL `length()` and Oracle `LENGTH()` return 6, so every length check, padding calculation, and truncation guard shifts by the number of trailing blanks. Use `DATALENGTH()` when trailing spaces must count.
- **`ISNULL(a, b)` casts the result to the type and length of its FIRST argument.** `ISNULL(col_varchar3, 'longvalue')` silently truncates the default to 3 characters. `COALESCE` follows CASE rules and returns the highest-precedence/widest type, so a mechanical `ISNULL`→`COALESCE` rewrite changes output width.
- **Silent truncation on variable and parameter assignment.** Over-length strings assigned to a variable or passed into a procedure parameter are truncated with no error, regardless of `ANSI_WARNINGS` — unlike table inserts, which raise error 8152.
- **`CHARINDEX(needle, haystack)` takes the search string FIRST** — the reverse of PostgreSQL `STRPOS(haystack, needle)` and Oracle `INSTR(haystack, needle)`. Both arguments are strings, so a naive port that keeps the order compiles and runs but silently searches for the text *inside* the pattern and returns 0 ("not found").

### Numbers and rounding

- **`money`/`smallmoney` cause rounding errors through truncation in calculations.** The types carry a fixed 4-decimal scale, so intermediate division/multiplication results are truncated and a `money`→`numeric`/`NUMBER` remapping changes totals in the fourth decimal and up. Avoid `money` for any calculated value — use `decimal` with at least four decimal places.
- **decimal division result scale is derived from operands' DECLARED precision/scale, not their values.** For `e1 / e2` the result scale is `max(6, s1 + p2 + 1)` (floor 6, absolute max 38); excess fraction is rounded to fit, so long division chains silently lose digits that PostgreSQL `numeric` keeps.
- **`ROUND(x, n, <non-zero>)` truncates instead of rounding.** Any non-zero third argument switches `ROUND` to truncation; no other dialect's `ROUND` has that parameter, so a literal port turns truncation back into rounding.

### Dates

- **Legacy `datetime` rounds to 1/300-second increments.** Stored values only end in `.000`/`.003`/`.007` and were already rounded on the way in; migrating to `datetime2`/`timestamp` preserves the rounded value, so range comparisons against exact times start landing differently.
- **`DATEDIFF` counts datepart boundary crossings, not elapsed time.** `DATEDIFF(year, '2021-12-31', '2022-01-01')` is 1. Age and duration logic diverges from any target that subtracts intervals (`AGE()`, interval math).
- **`GETDATE()` is volatile; PostgreSQL `CURRENT_TIMESTAMP`/`NOW()` is frozen at transaction start.** A multi-statement procedure or loop stamping rows with `GETDATE()` gets advancing timestamps in SQL Server (and Oracle `SYSDATE`), but identical ones in PostgreSQL — silently collapsing time-ordering. Use `clock_timestamp()` in PostgreSQL for per-call behavior.

### NULL and expression semantics

- **`COALESCE` evaluates its argument more than once.** It expands to a `CASE`, so a subquery or non-deterministic argument can execute twice and return two different values, and it can return NULL under the READ COMMITTED isolation level. `ISNULL` evaluates once, and PostgreSQL/Oracle `COALESCE` evaluate each argument once, so both side effects and results can differ after migration.
- **Data-type precedence in mixed comparisons.** `int` outranks `varchar`, so `WHERE varchar_col = 7` converts the *column* to `int` and `'007'` matches; the same predicate in application code or a strictly-typed target compares strings and doesn't. (A non-numeric value in the column raises a conversion error — the loud case.)

### Session settings

- **`SET ANSI_WARNINGS OFF` rewrites query semantics in scope.** It turns divide-by-zero and arithmetic overflow into `NULL` results and turns insert truncation into silent data loss. The setting has no equivalent in the target, so the same statements behave differently after migration.

### Transactions, triggers, and concurrency

- **Statement-level error rollback vs. whole-transaction abort.** With `XACT_ABORT` OFF (the default), the common case is that an error rolls back only the failing statement and the transaction continues — the opposite of PostgreSQL, which dooms the entire transaction, and different again from Oracle's implicit per-statement savepoint. Caveat: actual T-SQL behavior varies by error class (some errors abort the batch, some leave the transaction uncommittable), so treat "only the statement rolls back" as the common case, not a rule.
- **Nested `BEGIN TRAN` is not nested.** An inner `BEGIN TRAN` only increments `@@TRANCOUNT`; an inner `COMMIT` commits nothing (only the outermost commit is real), and a bare `ROLLBACK` discards the entire outermost transaction. PostgreSQL treats a nested `BEGIN` as a no-op warning, and both PostgreSQL and Oracle use `SAVEPOINT`, so ported error-handling silently commits or rolls back a different scope than intended.
- **Table variables ignore ROLLBACK.** `@table` contents survive a transaction rollback by design — rollbacks do not affect them; the same logic on a temp table, a PostgreSQL temp table, or an app-side collection inside a transaction does not.
- **`NOLOCK` / READ UNCOMMITTED anomalies vanish under MVCC.** `WITH (NOLOCK)` permits dirty reads and allocation-scan anomalies (rows read twice or skipped). PostgreSQL and Oracle are MVCC with no such hint — it silently disappears and the query runs under snapshot/read-committed isolation. Relatedly, T-SQL's default READ COMMITTED uses shared locks (readers block writers) unless `READ_COMMITTED_SNAPSHOT` is on, so timing- and deadlock-dependent logic behaves differently in both directions.
- **Trigger rowcount inflation.** Without `SET NOCOUNT ON` in the trigger body, the client receives the trigger's row counts too, so an ORM or driver checking "rows affected" for optimistic concurrency reads the wrong number. (See also the Trigger Model section: triggers fire once per statement, so `SELECT @v = col FROM inserted` silently grabs one arbitrary row of a multi-row change.)
- **Temp table scope differs three ways.** A `#temp` created inside a stored procedure is dropped when that procedure exits, but a `#temp` created in the outer batch is session-scoped; PostgreSQL temp tables live for the whole session; and Oracle global temporary tables default to `ON COMMIT DELETE ROWS`, silently emptying at each commit. A naive port can reuse stale rows, fail on the second call, or lose a working set mid-procedure.

### Ordering and determinism

- **`TOP 100 PERCENT` + `ORDER BY` in a view is discarded.** Since SQL Server 2005 the optimizer removes both, so a view that "returned sorted rows" for years silently stops — and the target never had the guarantee anyway. Add `ORDER BY` at the outer query.
- **`UPDATE … FROM` with a non-unique join picks one source row arbitrarily.** When multiple source rows match one target row, SQL Server silently applies one with no error or warning; Oracle's `MERGE` raises ORA-30926 for the same shape, so migration surfaces a latent bug that was always there.

### Identity

- **`@@IDENTITY` crosses scopes.** It returns the last identity generated anywhere in the session, so adding an audit trigger that inserts into another identity table silently makes it return the wrong key. `SCOPE_IDENTITY()` is scope-limited and correct; PostgreSQL `RETURNING` / Oracle `RETURNING INTO` are the portable equivalents.

### Lower-frequency / context-dependent notes

- **`STR(float, length, decimal)` formats length-first:** it right-justifies, space-pads, rounds, and returns `**` (asterisks) on overflow. A reimplementation with `to_char`/`FORMAT` must replicate the width and overflow rules.
- **`TOP (n)` without `ORDER BY`** returns an arbitrary set that was often stable on a clustered-index scan; `LIMIT n` picks a different arbitrary set — silent if the code leaned on incidental ordering.
- **`float`→`varchar` default conversion** switches to scientific notation (`1e+08`) for values with seven or more digits, so exported or concatenated values change shape based on magnitude.
- **`datetime`/`datetime2` are timezone-naive.** Casting to `datetimeoffset` stamps `+00:00` rather than the server's offset, and mapping to a timezone-aware target (`timestamptz`, which converts on read) silently reinterprets historical timestamps.
- **`SET ROWCOUNT`** silently caps rows processed by INSERT/UPDATE/DELETE (and triggers) for the session; it is deprecated for DML and has no equivalent, so the cap disappears on migration.

---

## Export Appendix: Getting Source to Disk

Sproc-xray analyzes SQL source files on disk. If you have only a live database with no exported source, use one of the methods below to export your stored procedures, functions, and triggers to `.sql` files.

### Method 1: SSMS Generate Scripts Wizard (GUI)

**Tool:** SQL Server Management Studio (SSMS)

**Steps:**
1. In SSMS, connect to your database.
2. Right-click the database name → **Tasks** → **Generate Scripts...**
3. In the wizard:
   - Select specific objects (Stored Procedures, Functions, Triggers) or script the entire database.
   - Under **Set Scripting Options**, click **Advanced**.
   - Set:
     - **Types of data to script:** Schema only
     - **Script for Server Version:** Match your target (or use the default)
     - **Include descriptive headers:** Yes (optional, helpful for readability)
   - Choose output destination: **Save to file** (one file per object recommended for sproc-xray).
4. Complete the wizard. SSMS will generate `.sql` files in your chosen directory.

**Encoding warning:** SSMS-exported files are often **not UTF-8**. Ground truth is typically ISO-8859-1 or Windows-1252 with mixed CRLF/LF line endings. This can break naive `grep` or text-processing tools. Use encoding-tolerant tools (`grep -a` for binary-safe search, `file` command to detect encoding, `iconv` if conversion is needed).

### Method 2: mssql-scripter (CLI)

**Tool:** `mssql-scripter` (cross-platform, Python-based CLI)

**Installation:**
```bash
pip install mssql-scripter
```

**Usage:**
```bash
mssql-scripter -S <server> -d <database> -U <user> -P <password> \
  --include-objects --object-type StoredProcedure --object-type Function --object-type Trigger \
  --file-per-object --output-dir ./sql-export
```

**Options:**
- `--include-objects`: Script only the specified object types.
- `--object-type`: Specify `StoredProcedure`, `Function`, `Trigger`, etc.
- `--file-per-object`: Generate one file per object (recommended for sproc-xray).
- `--output-dir`: Destination directory for exported files.

**Example for a specific schema:**
```bash
mssql-scripter -S localhost -d AdventureWorks -U sa -P MyPassword \
  --include-objects --schema dbo --object-type StoredProcedure \
  --file-per-object --output-dir ./sprocs
```

See `mssql-scripter --help` for full options.

### Method 3: sys.sql_modules / OBJECT_DEFINITION() via sqlcmd (SQL Query)

**Tool:** `sqlcmd` (ships with SQL Server client tools)

**Query:**
```sql
SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    m.definition
FROM sys.sql_modules m
INNER JOIN sys.objects o ON m.object_id = o.object_id
INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE o.type IN ('P','FN','IF','TF','TR')  -- Procedures, Functions, Triggers
ORDER BY s.name, o.name;
```

**Invocation:**
```bash
sqlcmd -S <server> -d <database> -U <user> -P <password> -Q "<query>" -o sproc-export.txt
```

**Truncation workaround:** For very large modules, `sys.sql_modules.definition` may appear truncated. Fall back to:
```sql
SELECT
    s.name + '.' + o.name AS object_name,
    OBJECT_DEFINITION(o.object_id) AS definition
FROM sys.objects o
INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE o.type IN ('P','FN','IF','TF','TR');
```

`OBJECT_DEFINITION()` returns `nvarchar(max)`, which avoids the truncation issue.

**Post-processing:** You will need to parse the output and split each object's definition into separate `.sql` files for sproc-xray to analyze. A simple Python or Bash script can do this.
