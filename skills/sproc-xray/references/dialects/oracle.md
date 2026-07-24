# Oracle (PL/SQL) Dialect Reference

**Validated against a real Oracle codebase (ADempiere PL/SQL).**

PL/SQL (Procedural Language/SQL) is Oracle Database's procedural extension to SQL. This reference provides the dialect-specific facts that sproc-xray uses when analyzing PL/SQL codebases for extraction migration.

## Package-Based Modularity and Stored Procedure Model

Oracle PL/SQL provides extensive package-based modularity. A `PACKAGE` declares a public interface, while a `PACKAGE BODY` carries the implementation. Package-level variables persist for the duration of a session (i.e., across calls within the same database connection).

**Migration risk:** this session-scoped package state has no equivalent in PostgreSQL (schemas are namespaces, not packages) or in stateless application code. Cross-call state that Oracle keeps in a package variable silently resets unless it is deliberately re-homed — a session/request-scoped object, a temp table, or a config parameter (GUC). Logic that assumes a package variable set by one call is still present on the next behaves differently once extracted. The reverse hazard appears under a **connection pool**: package state lives for the life of the *database session*, not the logical request, so one request's leftover state can leak into the next request that reuses the same pooled connection — a bug that is invisible until the code runs under pooling.

Procedures and functions can exist at the schema level (standalone objects) or inside packages. The `%TYPE` and `%ROWTYPE` attributes anchor variable declarations to a column or table shape, decoupling code from schema drift in the structural sense.

Both `CREATE PROCEDURE` and `CREATE OR REPLACE PROCEDURE` are standard. The same pattern applies to functions, packages, and package bodies: `CREATE OR REPLACE` is the idiomatic form.

**Standalone functions cannot be overloaded.** Oracle permits overloading only inside packages. Two schema-level `CREATE OR REPLACE FUNCTION` definitions with the same name but different signatures do not coexist — the second silently replaces the first, and which one survives is decided by install order (build scripts), not by call-site arity. When inventorying standalone routines, treat duplicate function names as a replacement hazard, not an overload set.

Some codebases also install trivial no-op **forward-declaration stubs** (functions whose entire body is `RETURN 0;`) to break circular dependencies at build time, then replace them with real bodies later. These inflate a naive object count and can read as complete or dead definitions when they are neither.

## NULL Semantics

**Oracle treats the empty string `''` as identical to NULL.** This is the inverse of T-SQL's behavior.

- `'' IS NULL` returns **true** in Oracle (returns **false** in T-SQL).
- Concatenating anything with `NULL` using the `||` operator returns the non-`NULL` value — `NULL` collapses under concatenation, unlike most other SQL dialects. For example, `'Hello' || NULL || 'World'` yields `'HelloWorld'`.
- Comparisons with `NULL` return unknown — neither true nor false — so `WHERE x = NULL` never matches; use `WHERE x IS NULL`.
- There is no null-aware equality operator (no `IS NOT DISTINCT FROM`). Engineers commonly emulate it with `(a = b OR (a IS NULL AND b IS NULL))`.
- In **procedural control flow**, a `NULL` condition is neither true nor false, so `IF <null> THEN … ELSE …` takes the `ELSE` branch and `WHILE <null>` never iterates. Ported to a host language this diverges — a null `Boolean` throws on unboxing (Java) or coerces to falsy by a different rule — so the branch taken can change or the code can blow up. Reproduce the three-valued test explicitly.

**Migration impact:** Any PL/SQL code that relies on `'' IS NULL` returning true will break if naively translated to T-SQL or other dialects that distinguish empty string from NULL.

## Trigger Model

Oracle triggers can be `BEFORE`, `AFTER`, or `INSTEAD OF` (the last only on views). Triggers execute at either **row granularity** or **statement granularity**.

A single trigger can declare multiple events: `FOR INSERT OR UPDATE OR DELETE` (OR-separated, not comma-separated). Oracle also supports **compound triggers**, which bundle multiple timing points (before statement, before each row, after each row, after statement) into a single trigger definition for the same event.

Multiple triggers per event are allowed. Their firing order is non-deterministic by default, but can be controlled explicitly using the `FOLLOWS` or `PRECEDES` clauses to declare inter-trigger dependencies.

The `WHEN (...)` clause on row-level triggers provides a server-side filter, avoiding unnecessary trigger body invocation for rows that don't match the condition.

Triggers have explicit `EXCEPTION` blocks. Exception swallow risk applies the same way as for procedures: an exception handler that does not re-raise silently swallows the error.

Schema-level (`AFTER LOGON ON SCHEMA`) and database-level (`AFTER STARTUP ON DATABASE`) triggers exist, but are typically operational or administrative — rarely encountered in application schemas.

**Migration impact:** T-SQL has no `BEFORE` trigger, so Oracle `BEFORE` triggers must be reimplemented as `INSTEAD OF` or moved into the application logic. Compound triggers have no direct T-SQL equivalent. Firing order does not carry over either: Oracle's `FOLLOWS`/`PRECEDES` give explicit inter-trigger ordering, but PostgreSQL fires multiple same-event triggers in **alphabetical name order** with no override, so triggers that depend on running in a set sequence can silently fire in the wrong order after migration — encode the order in the names, or consolidate into one trigger.

## Transaction Control and the Commit Model

Oracle does **not** autocommit. DML inside a PL/SQL block accumulates in the caller's transaction and persists only when an explicit `COMMIT` runs (or the caller commits); a multi-statement procedure is therefore atomic up to its first `COMMIT`, and an unhandled exception rolls the batch back. Procedures often contain no `COMMIT` of their own and rely on the *caller* to commit.

**Migration risk:** PostgreSQL and SQL Server run each statement in **autocommit** mode by default (unless wrapped in an explicit `BEGIN`/transaction). A procedure ported statement-by-statement silently loses its all-or-nothing boundary: each statement commits on success, so a failure partway through leaves earlier statements permanently applied instead of rolled back. Reproduce the original atomicity explicitly (a single wrapping transaction, or a service-layer transaction boundary), and preserve any reliance on caller-side commit.

**Error-rollback scope also differs.** When a statement raises, Oracle rolls back only that *statement* and leaves the transaction alive, so a caller that catches the error can continue and commit prior work. PostgreSQL instead marks the entire *transaction* as aborted — every subsequent statement fails with `current transaction is aborted` until a `ROLLBACK` (or a rollback to a `SAVEPOINT`). A PL/pgSQL `BEGIN ... EXCEPTION` block sets an implicit savepoint and can recover locally, but Oracle logic that catches an exception mid-transaction and carries on at the *top level* has no equivalent without explicit savepoints. A naive port either loses the surviving-transaction behavior or leaves the connection wedged.

**DDL implicitly commits.** Every Oracle DDL statement — including DDL run through `EXECUTE IMMEDIATE` — issues an implicit `COMMIT` immediately before and after itself, so any pending DML is durably committed the moment a procedure runs a `CREATE`/`ALTER`/`DROP`/`TRUNCATE`. PostgreSQL DDL is fully transactional (it rolls back with the surrounding transaction) and T-SQL DDL is transactional inside an explicit transaction, so a procedure that interleaves DML with dynamic DDL — assuming the DDL flushed the earlier DML — will, once ported, roll that DML back together with everything else on a later error. Make the intended commit boundaries explicit.

## Autonomous Transactions

`PRAGMA AUTONOMOUS_TRANSACTION` marks a procedure, function, or anonymous block to commit and roll back independently of the calling transaction.

Common use cases include:
- Audit logging that must persist even if the caller rolls back
- Counter-style updates that bypass long-running transaction locks

**Migration risk:** Nearly every target language equivalent (`Propagation.REQUIRES_NEW` in Spring, a fresh `TransactionScope` in .NET, a separate connection in Python's typical DB-API code) requires explicit infrastructure setup. Silent assumption of rollback isolation is a frequent source of post-migration data drift.

**Migration detection:** Sproc-xray flags any use of `PRAGMA AUTONOMOUS_TRANSACTION` as requiring autonomous-transaction infrastructure in the target architecture.

## Security Context: AUTHID DEFINER vs CURRENT_USER

`AUTHID DEFINER` (the default for PL/SQL stored procedures) means the procedure runs with the privileges of its owner, not its caller. The opposite, `AUTHID CURRENT_USER`, runs with caller privileges.

- **`AUTHID DEFINER`** is the Oracle analogue of T-SQL's `EXECUTE AS OWNER`.
- **`AUTHID CURRENT_USER`** is the analogue of T-SQL's `EXECUTE AS CALLER` (the default if no clause is specified in T-SQL).

**Migration implications:**
- Any target architecture must replicate the privilege boundary, typically via service accounts or dedicated database roles per service.
- Mixing `DEFINER` and `CURRENT_USER` procedures across the same call chain is a common audit-trail confusion.
- Sproc-xray flags any explicit use of `AUTHID` as a security-context boundary that the extraction migration must preserve.

## Dynamic SQL and Dependency Tracking

PL/SQL supports dynamic SQL via `EXECUTE IMMEDIATE <sql_string>`, which runs a dynamically constructed SQL statement.

**Critical limitations and failure modes:**

1. **SQL injection risk:** If the constructed string interpolates user input directly (rather than using bind variables with the `USING` clause), the code is vulnerable to SQL injection.

2. **Untracked dependencies:** `EXECUTE IMMEDIATE` does not appear in `all_dependencies`, so the dependency graph underreports edges out of any procedure that uses it. Static analysis tools (including catalog views) cannot see what a procedure calls if the call is constructed at runtime.

**Migration impact:** Any procedure using `EXECUTE IMMEDIATE` requires manual inspection to discover its true dependency footprint. Sproc-xray flags dynamic SQL edges as **reduced-confidence** (`dependencyConfidence: medium`) in the deep analysis phase.

**A second dynamic-SQL mechanism: `DBMS_SQL`.** The `DBMS_SQL` package (`DBMS_SQL.OPEN_CURSOR` → `PARSE` → `EXECUTE`) runs statements assembled at runtime, exactly like `EXECUTE IMMEDIATE`, and with the same blind spot: those statements do not appear in `all_dependencies`, so the dependency graph under-reports edges out of any routine that uses it. Flag `DBMS_SQL` edges with the same reduced confidence (`dependencyConfidence: medium`) as `EXECUTE IMMEDIATE`.

## Exception Handling: RAISE_APPLICATION_ERROR

`RAISE_APPLICATION_ERROR(error_code, message)` raises a user-defined error with codes in the `-20000 .. -20999` range. This range is reserved for application-defined exceptions.

**Migration contract:** These codes are typically significant to the application layer, which catches errors by code rather than by message. Migrations must preserve both the numeric code and the message format, since calling code often pattern-matches on these.

**Migration impact:** Any target language must map Oracle's user-defined error codes to equivalent custom exception types or error codes. The `-20000 .. -20999` range is a contract between the database and the application layer.

## Exception Swallowing Risk

Oracle's exception model uses named exceptions, predefined error codes, and the `EXCEPTION` block at the end of any `BEGIN ... END;` block.

An exception handler that does not re-raise (via `RAISE;` with no arguments inside a handler, or by explicitly re-raising the same exception) silently swallows the error.

**Common bug pattern:** `EXCEPTION WHEN OTHERS THEN NULL` is the Oracle equivalent of T-SQL's empty `CATCH` block — a common source of "the procedure returned success but did nothing" bugs.

**Migration impact:** Any exception-swallowing pattern must be preserved if it is intentional (e.g., best-effort cleanup logic), or surfaced for review if it appears to be a bug.

`EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE(SQLERRM)` is a swallow too, not a log: the message goes to the server-side `DBMS_OUTPUT` buffer, which is discarded unless a client has explicitly enabled and drained it, and control returns normally as though the block had succeeded. When the handler sits inside a loop, each failing iteration is silently skipped and the loop continues.

**`SELECT ... INTO` turns cardinality into control flow — and `WHEN OTHERS` hides it.** A PL/SQL `SELECT ... INTO` raises `NO_DATA_FOUND` on zero rows and `TOO_MANY_ROWS` on more than one — these are *implicit control flow*, not ordinary errors. Application-code data access (JDBC/ORM) instead returns an empty result or the first row *without throwing*, so a naive reimplementation silently drops that control flow: a no-rows case that today short-circuits into an exception handler (often `RETURN <default>`) will instead fall through with a `NULL`/uninitialized value. When the `SELECT INTO` sits under a blanket `WHEN OTHERS`, the raised `NO_DATA_FOUND` is *also* swallowed, so an entire "no matching row ⇒ return default" branch is invisible unless you know both facts. A `WHERE ROWNUM = 1` guard suppresses `TOO_MANY_ROWS` but not `NO_DATA_FOUND` (see the ROWNUM footgun). Migration must reproduce the zero-row / multi-row contract explicitly.

---

## Oracle-Specific Footguns

Constructs where a naive reimplementation silently changes behavior — the lens for Dimension 5.

- **`ROWNUM` applied before `ORDER BY`.** Oracle assigns `ROWNUM` *before* the `ORDER BY` runs, so `SELECT ... WHERE ... AND ROWNUM <= 1 ORDER BY col DESC` keeps an arbitrary row and then sorts that single row — it does **not** return the top-ranked row. The deterministic top-N idiom puts the `ORDER BY` inside an inline view and applies `ROWNUM` outside it. A third variant — a bare `WHERE ROWNUM = 1` with **no** `ORDER BY` — deliberately returns an arbitrary single row (and suppresses `TOO_MANY_ROWS` on a `SELECT INTO`); it ports faithfully to `LIMIT 1`/`TOP 1`, so do **not** flag it as the bug. All three variants often coexist in one codebase; classify each `ROWNUM` site individually, and check the **view layer** as well as routines — the before-`ORDER BY` bug recurs in reporting views, not just procedures and functions.
- **Legacy `(+)` outer-join operator.** Oracle's pre-ANSI outer join; placement decides which side is optional, and dropping or mis-placing it silently turns an outer join into an inner join. Translate to an explicit `LEFT`/`RIGHT JOIN`. In a mature schema this operator is typically **pervasive across the view layer** (often a large fraction of files), so grep the whole corpus for `(+)` rather than spot-checking a few objects.
- **`DECODE` treats two `NULL`s as equal**, unlike `CASE`/`=`; a naive `CASE` translation changes behavior whenever an operand can be `NULL`.
- **`NVL(a, b)` always evaluates both arguments** (unlike `COALESCE`, which short-circuits) and applies implicit type conversion between them — surprising when `a` and `b` differ in type, or when `b` has side effects. *(Calibration: many Oracle codebases favor ANSI `CASE`/`COALESCE` over `DECODE`/`NVL`, so the `DECODE` and `NVL` entries may match rarely even in a large corpus — but where they do appear, the hazards above are real.)*
- **`ADD_MONTHS` preserves end-of-month.** When the input is the last day of its month, Oracle forces the result to the last day of the *target* month (e.g. `ADD_MONTHS(DATE '2021-02-28', 1)` → `2021-03-31`, not the 28th) and clamps a day that would overflow a shorter month. PostgreSQL `+ interval '1 month'` and T-SQL `DATEADD(MONTH, …)` do **not** apply the last-day stickiness — they keep the day-of-month — so month-end date math (due dates, period ends) silently shifts by up to three days. (Overflow clamping like Jan 31 → Feb 28 happens to agree across engines; the stickiness is the divergence.)
- **`ROUND` rounds half away from zero.** Oracle's `ROUND(n, d)` always rounds a `.5` case away from zero (`ROUND(2.5)=3`, `ROUND(-2.5)=-3`). Many targets default to banker's rounding (half-to-even): PostgreSQL `round(double precision)`, .NET `Math.Round`, Python 3 `round`, Java `HALF_EVEN`. On monetary math this silently flips the last cent at exact-half boundaries and accumulates. It is the *least conspicuous* footgun in this class — `ROUND(x, 2)` reads as ordinary — so check it explicitly. (PostgreSQL `round(numeric, d)` and T-SQL `ROUND` match Oracle; the divergence bites only when `NUMBER` is mapped to a binary float, itself a hazard.)
- **Oracle has no native integer type — all numeric math is `NUMBER` (decimal).** `INTEGER`/`INT`/`SMALLINT` are subtypes of `NUMBER(38)`, so `10/3` yields `3.333…` and division never truncates. PostgreSQL and T-SQL integer/integer division **truncates** (`10/3` → `3`), so ported quantity or money math silently loses the fractional part unless an operand is cast to `numeric`/decimal. The 38-digit precision also does not survive extraction to app code: JDBC `getLong()`/`getDouble()`, JavaScript `number`, and most language numerics round beyond ~15–19 significant digits, so large IDs and high-precision money drift silently — carry these as `BigDecimal`/`numeric`/string, never as a binary float.
- **`GREATEST`/`LEAST` propagate `NULL`; PostgreSQL ignores it — the exact inverse.** Oracle returns `NULL` if *any* argument is `NULL`; PostgreSQL `greatest`/`least` skip `NULL`s and return `NULL` only when *all* arguments are, so a ported `GREATEST(a, b)` where `b` can be `NULL` silently starts returning `a` instead of `NULL`. Wrap operands in `NVL`/`COALESCE` (or guard for `NULL`) to preserve intent.
- **Oracle `DATE` is a fractional-day number.** Date arithmetic is numeric: `d1 - d2` yields a **number of days** (not an interval), `d + n` adds `n` days, `d + 0.9993` pushes to ~end-of-day, and `TRUNC(d)` drops the time component while `TRUNC(d,'MM')`/`TRUNC(d,'YYYY')` snap to a period boundary — all relying on `DATE` always carrying a time-of-day. PostgreSQL/T-SQL treat `date - date` as an interval (or forbid it) and reject `date + 0.9993`, so a literal port either fails to compile or silently drops the time component; port to explicit interval / `DATEADD` arithmetic on a timestamp type. (Watch magic fractions like `+ 0.9993` — ≈ 23:58:59, an *approximate* end-of-day, not 23:59:59.)
- **`SYSDATE` re-evaluates on every call; PostgreSQL `now()` freezes per transaction.** Oracle `SYSDATE`/`SYSTIMESTAMP` return the wall-clock instant at *each* evaluation (≈ PostgreSQL `clock_timestamp()`), so a value read repeatedly in a loop or across a multi-row `INSERT ... SELECT` advances row to row. PostgreSQL `now()`/`CURRENT_TIMESTAMP`/`transaction_timestamp()` freeze at the start of the *transaction* and return the same instant for every row, so audit timestamps, elapsed-time calculations, and per-row `Created`/`Updated` values silently collapse to one value on a naive port — use `clock_timestamp()` (or `statement_timestamp()`) to preserve per-call semantics. (T-SQL `GETDATE()`/`SYSDATETIME()` evaluate per call like Oracle, so this divergence is PostgreSQL-specific.) Independently, `SYSDATE`/`SYSTIMESTAMP` read the **database server's OS clock and time zone** and ignore the session time zone entirely, so rehosting the database (e.g. to a UTC cloud host) or porting `now()` to an app server in another zone silently shifts every `SYSDATE`-derived boundary ("last hour" windows, day cutoffs) with no error.
- **`TO_CHAR`/`TO_DATE` with territory- or format-sensitive models are NLS-dependent.** `TO_CHAR(d,'D')` returns the day-of-week number relative to the `NLS_TERRITORY` week start (1 = Sunday in some territories, 1 = Monday in others), so code that hardcodes `'1' = Sunday` breaks under a different territory *within Oracle*, and `EXTRACT(DOW)` (0 = Sunday) / `DATEPART(dw)` (`@@DATEFIRST`-dependent) do not match it. Numeric format models resolve group/decimal separators from `NLS_NUMERIC_CHARACTERS` at runtime (the `G` and `D` in a mask like `'99G999D99'`), so the emitted string flips between `1,234.56` and `1.234,56` with session settings. No target dialect reproduces NLS-driven formatting automatically — pin the convention explicitly. Implicit string↔date conversion is NLS-driven too: `WHERE date_col = '01-JAN-24'` (or `TO_DATE` with no explicit format) resolves the mask from `NLS_DATE_FORMAT` at runtime, so the same predicate parses differently under a different session setting and has no equivalent once the comparison becomes string-vs-string in app code.
- **`TO_DATE(…, 'RR')` / `'RRRR'` infer the century from a sliding pivot.** The `RR` format maps a two-digit year to a century by a 50/49 rule relative to the *current* year, so the same input parses to a different century depending on when the code runs; `YY` in a target dialect (or a naive `RR`→`YY` swap) always uses the current century, silently shifting 20th-century dates into the 21st. No target reproduces `RR` — expand two-digit years explicitly during migration.
- **String comparison and sort obey `NLS_SORT`/`NLS_COMP`.** Oracle's default `BINARY` sort orders by code point (uppercase before lowercase, accents last); `NLS_COMP=LINGUISTIC` with an `NLS_SORT` such as `BINARY_CI`/`GENERIC_M` makes `=`, `LIKE`, `ORDER BY`, `BETWEEN`, and range predicates case- or accent-insensitive **session-wide**, with no per-column syntax. PostgreSQL has no session-global equivalent — comparison and ordering follow the column/expression *collation* (a glibc/ICU locale interleaves case and accents differently) — and T-SQL follows the column/database collation. So `ORDER BY`, uniqueness, and `WHERE`/`BETWEEN` can match or order different rows after migration; map an Oracle `BINARY` default to a `C`/binary collation and reproduce any linguistic setting as an explicit per-column collation.
- **`ORDER BY` sorts `NULL`s last (ASC) / first (DESC) — matched by PostgreSQL, inverted by T-SQL.** Oracle treats `NULL` as *larger* than any value (`NULLS LAST` on ASC, `NULLS FIRST` on DESC); PostgreSQL's default is identical, but SQL Server treats `NULL` as *smallest* (nulls first on ASC) and has **no** `NULLS FIRST/LAST` clause. Any NULL-bearing sorted result — and especially top-N / "first row wins" / pagination built on it — silently picks different rows when ported to T-SQL. (Oracle↔PostgreSQL agree here; the divergence is Oracle→T-SQL.)
- **`SUBSTR` with a negative position counts from the end.** `SUBSTR(s, -4)` returns the *last 4 characters* in Oracle (the whole string if it is shorter; NULL if `s` is NULL). Targets diverge silently: PostgreSQL `substr(s, -4)` treats a start < 1 as before the string and returns the *entire* value; T-SQL has no from-the-end `SUBSTRING` (`SUBSTRING(s, -4, 4)` yields an empty string); app-code slicing differs again (Python `s[-4:]` matches, Java `substring(-4)` throws). Use `RIGHT(s, n)` — or `substr(s, greatest(length(s)-n+1, 1))` — to preserve intent.
- **`INSTR` has position and occurrence arguments with no direct target equivalent.** Oracle `INSTR(str, sub [, position [, occurrence]])` searches from an arbitrary start — a *negative* position searches backward from the end — and can locate the Nth occurrence. PostgreSQL `strpos`/`position` and T-SQL `CHARINDEX` cannot express the 3-/4-argument forms, so a naive replacement silently returns the first-from-start offset (or 0) instead of the intended one. Reproduce the extra arguments explicitly.
- **`FOR i IN REVERSE lo..hi` reverses iteration, not the bounds.** Oracle numeric `FOR` loops always write bounds low-to-high; `REVERSE` only flips the *iteration order* (it runs `hi` down to `lo`). PL/pgSQL uses the opposite convention — `FOR i IN REVERSE hi..lo` — so a copy-pasted `FOR i IN REVERSE 1..n` iterates from 1 *downward* and, for any `n > 1`, the loop body **never executes** (silently, no error). Bounds are inclusive on both ends, and a fractional `NUMBER` bound is rounded half-away-from-zero where app-code `range()`/`for` typically truncate. Order- or count-dependent logic changes silently. (This is easy to wave off as "just a loop" — two of five test reviewers did exactly that — so flag it whenever a `REVERSE` range loop appears.)
- **Sequence values are unique but not gapless, ordered, or a proxy for insertion order.** `seq.NEXTVAL` caches ranges per session and, under RAC `NOORDER`, is not even monotonic across sessions, so values have gaps and can be handed out in non-chronological order. Code that infers insertion order or contiguity from a sequence-generated ID is already fragile in Oracle and silently wrong once ported to a different sequence/identity/`SERIAL` implementation with its own caching — order by an explicit timestamp or ordering column instead. (`seq.NEXTVAL`/`CURRVAL` inline in `VALUES` also has no syntactic equivalent: PostgreSQL `nextval('seq')`, T-SQL `NEXT VALUE FOR`.)
- **An open cursor is a stable snapshot; paginated app queries are not.** Oracle returns a cursor's rows as of its **open** SCN, unaffected by commits that occur while it is being fetched (`FOR x IN (SELECT …) LOOP` included). Re-implemented as repeated, separately-executed page queries (`LIMIT`/`OFFSET` per request), each page sees a *fresh* snapshot, so concurrent inserts and deletes silently skip or duplicate rows across page boundaries. Preserve snapshot semantics with a held cursor/transaction, keyset pagination, or a snapshot isolation level.
- **`OUT`/`IN OUT` parameters are copy-out; an unhandled exception discards their writes.** Without `NOCOPY`, PL/SQL passes `OUT`/`IN OUT` arguments by value and copies the result back to the caller *only on normal return*, so if the procedure raises, any partial mutation of those parameters is reverted at the call site. Every mainstream host language passes objects/arrays by reference and keeps whatever was mutated before the throw, so extracted code that relied on "the caller's variable is unchanged if I fail" silently sees partial writes survive. Snapshot and restore explicitly if that rollback-on-error behavior is load-bearing.
- **Oracle may call a PL/SQL function far fewer times than there are rows.** Scalar-subquery caching and the `DETERMINISTIC` hint let Oracle memoize a function's result per distinct input within a statement, so a function with side effects or hidden non-determinism can appear to "work" because it runs once per distinct value rather than once per row. Extracted to app code that calls it once per row, the call count — and any side effects, counters, or `SYSDATE`/random reads inside it — changes silently. Treat function purity as a migration contract, not an implementation detail.
- **Global temporary tables differ in lifetime and default commit behavior.** An Oracle GTT is a *permanent* schema object whose *data* is session- or transaction-scoped, defaulting to `ON COMMIT DELETE ROWS` (rows vanish at commit). PostgreSQL and T-SQL temporary tables are *per-session* objects created on demand, and PostgreSQL defaults to `ON COMMIT PRESERVE ROWS`, so a literal port can silently see staging rows survive a commit that Oracle would have cleared. Carry the `ON COMMIT` semantics across explicitly.
- **`FROM DUAL` is a syntax artifact, not a footgun.** It disappears on migration (a bare `SELECT`) and changes no behavior. Do not flag its occurrences as risks — many appear only in header-comment examples.

---

## Export Appendix: Getting Source to Disk

Sproc-xray analyzes SQL source files on disk. If you have only a live Oracle database with no exported source, use one of the methods below to export your stored procedures, functions, packages, and triggers to `.sql` files.

### Method 1: DBMS_METADATA.GET_DDL (SQL Query)

**Tool:** SQL*Plus or any SQL client that can execute PL/SQL

**Query:**
```sql
SELECT DBMS_METADATA.GET_DDL('PROCEDURE', object_name, owner) AS ddl
FROM all_procedures
WHERE owner = 'YOUR_SCHEMA'
  AND object_type = 'PROCEDURE'
ORDER BY object_name;
```

Replace `'PROCEDURE'` with `'FUNCTION'`, `'PACKAGE'`, `'PACKAGE BODY'`, or `'TRIGGER'` as needed. Replace `'YOUR_SCHEMA'` with your target schema name.

**Spooling to disk (SQL*Plus):**
```sql
SET LONG 1000000
SET LONGCHUNKSIZE 1000000
SET PAGESIZE 0
SET LINESIZE 32767
SET FEEDBACK OFF
SET HEADING OFF
SET TRIMSPOOL ON

SPOOL /path/to/output/procedures.sql

SELECT DBMS_METADATA.GET_DDL('PROCEDURE', object_name, owner) || CHR(10) || '/' || CHR(10)
FROM all_procedures
WHERE owner = 'YOUR_SCHEMA'
  AND object_type = 'PROCEDURE'
ORDER BY object_name;

SPOOL OFF
```

The `CHR(10) || '/' || CHR(10)` adds a slash delimiter between objects, which is the standard terminator for PL/SQL blocks in SQL*Plus.

**Post-processing:** You will need to split the output file into separate `.sql` files (one per object) for sproc-xray to analyze. A simple Python or Bash script can parse the output and split on the `/` delimiter.

### Method 2: SQLcl (Oracle SQL Developer Command Line)

**Tool:** SQLcl (modern replacement for SQL*Plus, bundled with Oracle SQL Developer)

**Installation:** Download from Oracle's SQL Developer downloads page, or install via package manager if available.

**Usage:**
```bash
sql username/password@database
```

**Export a single object:**
```sql
SET SQLFORMAT ANSICONSOLE
SET DDL STORAGE OFF
SET DDL SEGMENT_ATTRIBUTES OFF
SET DDL TABLESPACE OFF

SELECT DBMS_METADATA.GET_DDL('PROCEDURE', 'PROC_NAME', 'SCHEMA_NAME') FROM DUAL;
```

**Export all objects of a type to individual files:**

Use SQLcl's `script` command to automate the process:

```sql
SET SQLFORMAT ANSICONSOLE
SET LONG 1000000
SET PAGESIZE 0
SET LINESIZE 32767
SET FEEDBACK OFF
SET HEADING OFF

SPOOL export_procs.sql

SELECT 'SPOOL ' || object_name || '.sql' || CHR(10) ||
       'SELECT DBMS_METADATA.GET_DDL(''' || object_type || ''', ''' || object_name || ''', ''' || owner || ''') FROM DUAL;' || CHR(10) ||
       'SPOOL OFF'
FROM all_objects
WHERE owner = 'YOUR_SCHEMA'
  AND object_type IN ('PROCEDURE', 'FUNCTION', 'PACKAGE', 'PACKAGE BODY', 'TRIGGER')
ORDER BY object_type, object_name;

SPOOL OFF

@export_procs.sql
```

This generates and executes a script that creates one `.sql` file per object.

**Encoding note:** SQLcl outputs UTF-8 by default. If your database uses a different character set, verify encoding with `file` or `iconv` to ensure proper text handling.

### Method 3: Oracle SQL Developer (GUI)

**Tool:** Oracle SQL Developer (GUI)

**Steps:**
1. Connect to your database in SQL Developer.
2. In the **Connections** navigator, expand your schema → **Procedures** (or **Functions**, **Packages**, **Triggers**).
3. Right-click on a procedure → **Save As...** → save to a `.sql` file.
4. For bulk export:
   - Right-click the schema name → **Export...** → **DDL**.
   - In the export wizard, select object types (Procedures, Functions, Packages, Triggers).
   - Choose output directory and file format (one file per object recommended).
   - Complete the wizard.

**Encoding warning:** SQL Developer's exported files may use platform-specific encodings. Ground truth is typically UTF-8 on modern systems, but verify with `file` or `iconv` if you encounter encoding issues.

---

## Sources

The core dialect facts in this reference were distilled from:

1. **Originating PL/SQL dialect notes** (pre-plugin working material, not distributed with this skill) — the origin of the substantive PL/SQL facts (package model, NULL semantics, trigger model, autonomous transactions, `AUTHID`, dynamic SQL, `RAISE_APPLICATION_ERROR`, exception swallowing).
2. Oracle Documentation: PL/SQL Language Reference (https://docs.oracle.com/en/database/oracle/oracle-database/)

The `DBMS_SQL`, `DBMS_OUTPUT`-swallow, standalone-overload, forward-declaration-stub, and Oracle-Specific-Footguns material was added from real sproc-xray runs against ADempiere PL/SQL and is not drawn from the notes file. A second, full-corpus run (adding the Oracle view layer) contributed the `ADD_MONTHS`, `ROUND`, `DATE`-as-fractional-day, and NLS-conversion footguns, plus the `ROWNUM` third-variant / view-layer and `(+)` at-scale notes.

A third pass expanded the footgun catalog and several sections from a vetted round of dialect research — the full-corpus run combined with cross-checked candidate lists from multiple external models, each item verified for accuracy and de-duplicated against the text above. Additions the ADempiere corpus itself exercises are corpus-grounded: sequence ordering, cursor read-consistency, `OUT`/`IN OUT` copy-out, dynamic-DDL commit, and procedural `IF <null>`. The rest are general Oracle behaviors documented for corpora that do use them — `GREATEST`/`LEAST` NULL propagation, the `RR` year pivot, `NLS_SORT`/`NLS_COMP` collation, `NUMBER`/integer-division precision, the T-SQL NULL-sort inversion, scalar-subquery caching, global temporary tables, and trigger firing order — and are not claimed as observed in this corpus.

