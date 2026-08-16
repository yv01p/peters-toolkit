## Executive Summary — Critical Red Flags

Ranked, cited, severity-tagged concrete hazards. NOT a score, NOT a verdict.

- **[CRITICAL]** Trigger cascade chain not in application code: `UPDATE accounts SET status = ...` (external) → `TRIGGER trg_account_status_sync` → `CALL prc_log_status_change` → `INSERT INTO account_status_log` (`03-trg_account_status_sync.sql:9`, `:38`, `02-prc_log_status_change.sql:10`). The application must reimplement this entire chain explicitly — see Dimension 3.
- **[HIGH]** Self-referential `UPDATE` inside a row-level trigger, against the trigger's own base table: `trg_account_status_sync` runs `UPDATE accounts ...` at `03-trg_account_status_sync.sql:34-36` while defined `BEFORE UPDATE OF status ON accounts FOR EACH ROW` (`:9-10`). This is the textbook precondition for Oracle's mutating-table restriction (`ORA-04091`). See Dimension 3 for the full citation and hedged assessment.
- **[MEDIUM]** Business-status vocabulary hardcoded as string literals directly in trigger control flow, with no backing enumeration or reference table: `:NEW.status = 'CLOSED'` (`03-trg_account_status_sync.sql:17`), `:NEW.status = 'FROZEN'` (`:35`). See Dimension 5.
- **[LOW]** Server-evaluated timestamp defaults (`DEFAULT SYSDATE`) on `accounts.updated_at` (`01-schema.sql:7`) and `account_status_log.changed_at` (`:24`) must be reproduced explicitly by the application on insert. See Dimension 5.
- **[LOW]** Sequence `seq_status_log` (`01-schema.sql:27`) is a shared, gap-prone counter, consumed by exactly one routine (`02-prc_log_status_change.sql:11`). Standard migration note; single-consumer case, not a shared-state cluster. See Dimension 5.

---

## Coverage Declaration

This section is positioned first but written last, after the Component Manifest and Missing-Reference Table exist — every number below is copied from the section that owns it.

- **Objects provided:** 6 objects across 3 files (Tables: 3, Sequences: 1, Standalone Procedures: 1, Triggers: 1) — copied from the Component Manifest grand total.
- **Objects referenced but missing:** 0 (none) — copied from the Missing-Reference Table, which has zero rows.
- **Estimated coverage:** 100% of referenced objects analyzed (6 of 6 — see Coverage Honesty Check).
- **Reduced-confidence dimensions:** None — no dynamic SQL (`EXECUTE IMMEDIATE`, `DBMS_SQL`) detected in the analyzed source; Dimension 2's dynamic-SQL confidence flagging is unexercised in this analysis.
- **Key gaps:** No application-tier caller of the triggering `UPDATE accounts SET status = ...` statement is included in this source — the corpus is schema + trigger + procedure only, with no calling application code provided. This does not create a missing-reference gap (every object DEFINED in the source is fully analyzed), but it does limit Dimension 2's liveness evidence for the trigger's own invocation to "triggers are always entry points" rather than a cited external caller.

---

## 1. Inventory & Completeness

### Context Intake

**Documentation check.** `README.md` was read during intake. Two verifications, both performed:

**Path claims** (README's Layout section vs. actual `sql/` contents):

| Documented path | Found on disk? |
|---|---|
| `sql/01-schema.sql` | Yes |
| `sql/02-prc_log_status_change.sql` | Yes |
| `sql/03-trg_account_status_sync.sql` | Yes |

All three documented paths match the actual directory layout exactly (`sql/` contains exactly these three files — see `find sql -type f` below). No path mismatch.

```console
$ find sql -type f | sort
sql/01-schema.sql
sql/02-prc_log_status_change.sql
sql/03-trg_account_status_sync.sql
```

**Count and structural claims** (README's intro paragraph: *"There is one trigger, one standalone procedure, no packages, and no views"*), checked against the parsed Component Manifest counts below:

| Claim | Documented N | Parsed M (same category) | N = M? | Verdict |
|---|---|---|---|---|
| "one trigger" | 1 | 1 (Triggers) | yes | VERIFIED |
| "one standalone procedure" | 1 | 1 (Standalone Procedures) | yes | VERIFIED |
| "no packages" | 0 | 0 (Packages) | yes | VERIFIED |
| "no views" | 0 | 0 (Views) | yes | VERIFIED |

All four documented claims match the parsed source exactly. No documentation drift found in this corpus.

**Encoding and line-ending detection:**

```console
$ file sql/*
sql/01-schema.sql:                  ASCII text
sql/02-prc_log_status_change.sql:   ASCII text
sql/03-trg_account_status_sync.sql: ASCII text
```

All three files are plain ASCII text. No mixed line endings, no non-UTF-8 encoding, no non-English comments.

**Context-intake table:**

| Artifact Type | Extensions | Found? | Count |
|---|---|---|---|
| Stored procedures | `.sql`, CREATE PROCEDURE | Yes | 1 |
| Scalar functions | `.sql`, CREATE FUNCTION RETURNS scalar | No | 0 |
| Table-valued functions | `.sql`, CREATE FUNCTION RETURNS TABLE | No | 0 |
| Triggers | `.sql`, CREATE TRIGGER, `.trg` | Yes | 1 |
| Views (with logic) | `.sql`, CREATE VIEW | No | 0 |
| DDL / table schemas | `.sql`, CREATE TABLE, `.ddl` | Yes | 3 tables + 1 sequence |
| Jobs / scheduled tasks | `.sql`, CREATE JOB, SQL Agent | No | 0 |
| Packages (Oracle) | `.pks`, `.pkb`, CREATE PACKAGE | No | 0 |
| Test scripts | `*Test*.sql`, `*_test.sql` | No | 0 |

No test scripts in this corpus — nothing to flag as excluded from the production logic inventory.

### Component Manifest

Object counts come from parsing `CREATE` statements, never from counting files.

```console
$ grep -nE '^[[:space:]]*CREATE[[:space:]]+TABLE' sql/*.sql
sql/01-schema.sql:2:CREATE TABLE accounts (
sql/01-schema.sql:11:CREATE TABLE account_holds (
sql/01-schema.sql:19:CREATE TABLE account_status_log (

$ grep -nE '^[[:space:]]*CREATE[[:space:]]+SEQUENCE' sql/*.sql
sql/01-schema.sql:27:CREATE SEQUENCE seq_status_log START WITH 1 INCREMENT BY 1;

$ grep -nE '^[[:space:]]*CREATE([[:space:]]+OR[[:space:]]+REPLACE)?[[:space:]]+PROCEDURE' sql/*.sql
sql/02-prc_log_status_change.sql:4:CREATE OR REPLACE PROCEDURE prc_log_status_change (

$ grep -nE '^[[:space:]]*CREATE([[:space:]]+OR[[:space:]]+REPLACE)?[[:space:]]+TRIGGER' sql/*.sql
sql/03-trg_account_status_sync.sql:9:CREATE OR REPLACE TRIGGER trg_account_status_sync

$ grep -nE '^[[:space:]]*CREATE([[:space:]]+OR[[:space:]]+REPLACE)?[[:space:]]+(FUNCTION|PACKAGE|VIEW|DATABASE)' sql/*.sql
(no output)
```

| Type | Object Name | File | LOC | Notable Flags |
|---|---|---|---|---|
| Table | `accounts` | `01-schema.sql` | (shared file — see Tables subtotal) | Self-referential `UPDATE` from `trg_account_status_sync` at `:34` — see Dimension 3 |
| Table | `account_holds` | `01-schema.sql` | (shared file) | Read + written by `trg_account_status_sync` |
| Table | `account_status_log` | `01-schema.sql` | (shared file) | Written by `prc_log_status_change` |
| Sequence | `seq_status_log` | `01-schema.sql` | 0 (counted under Tables — same file) | Consumed by `prc_log_status_change` (`:11`) |
| Standalone Procedure | `prc_log_status_change` | `02-prc_log_status_change.sql` | 13 | Called by trigger at `03:38` |
| Trigger | `trg_account_status_sync` | `03-trg_account_status_sync.sql` | 40 | `BEFORE UPDATE OF status`, row-level; calls `prc_log_status_change`; self-referential `UPDATE` on `accounts` |

`accounts`, `account_holds`, `account_status_log`, and `seq_status_log` all live in the single file `01-schema.sql` (27 lines). To avoid quadruple-counting that file's LOC across four manifest rows, the full 27 LOC is attributed to the **Tables** subtotal and the **Sequences** subtotal is stated as `0` with the file named — this keeps the grand-total addition below equal to the actual `wc -l` sum.

```console
$ wc -l sql/*.sql
  27 sql/01-schema.sql
  13 sql/02-prc_log_status_change.sql
  40 sql/03-trg_account_status_sync.sql
  80 total
```

- Tables subtotal: 3 objects, 27 LOC (`01-schema.sql`, shared with the sequence below)
- Sequences subtotal: 1 object, 0 LOC (counted under Tables — same file)
- Standalone Procedures subtotal: 1 object, 13 LOC
- Triggers subtotal: 1 object, 40 LOC

**Grand total: 6 objects (= 3 + 1 + 1 + 1), 80 LOC (= 27 + 0 + 13 + 40)**

```console
$ echo $((3+1+1+1)); echo $((27+0+13+40))
6
80
```

Both totals reproduce the `wc -l` total (80) and the per-type object counts shown above.

### Extraction Metrics

Scratch file `metrics.tsv` (`Object|Params|CursorLoops|Branches|UDTFlags|File`), materialized before this subsection was written:

```console
$ cat metrics.tsv
prc_log_status_change|3|0|0|none|02-prc_log_status_change.sql
```

**One row per routine defined in the source.** `trg_account_status_sync` is a trigger, not a procedure or a function — it does not appear in this table. Its definition site, its role as an entry point, and its cascade into `prc_log_status_change` are covered in the Component Manifest above and in the Trigger Cascade Map (Dimension 3) instead.

```console
$ grep -nE '^[[:space:]]*(CREATE[[:space:]]+(OR[[:space:]]+REPLACE[[:space:]]+)?)?(PROCEDURE|FUNCTION)[[:space:]]+[A-Za-z_][A-Za-z0-9_$#]*' sql/*.sql
sql/02-prc_log_status_change.sql:4:CREATE OR REPLACE PROCEDURE prc_log_status_change (
```

Reading `02-prc_log_status_change.sql:4-8` through the closing `)` counts 3 comma-separated formals: `p_account_id`, `p_old_status`, `p_new_status`.

```console
$ grep -nE 'CURSOR[[:space:]]+[A-Za-z_]|FOR[[:space:]]+[A-Za-z_][A-Za-z0-9_$#]*[[:space:]]+IN[[:space:]]|OPEN[[:space:]]+|FETCH[[:space:]]+' sql/02-prc_log_status_change.sql
(no output)
```

Zero cursor-search hits inside `prc_log_status_change` — 0 cursor loops.

```console
$ grep -nEw 'IF|ELSIF|WHEN|WHILE|ELSE|EXCEPTION|EXIT' sql/02-prc_log_status_change.sql
(no output)
```

Zero branch-keyword hits — 0 branches. `prc_log_status_change` is a single `INSERT`, no conditional of any kind.

```console
$ grep -nE '%ROWTYPE|%TYPE|IS[[:space:]]+RECORD|VARRAY|IS[[:space:]]+TABLE[[:space:]]+OF|REF[[:space:]]+CURSOR|SYS_REFCURSOR' sql/02-prc_log_status_change.sql
(no output)
```

Zero UDT-search hits — `UDT Usage` is `none`.

| Object | Params | Cursor Loops | Branches | UDT Usage | File |
|---|---|---|---|---|---|
| `prc_log_status_change` | 3 | 0 | 0 | none | `02-prc_log_status_change.sql` |

**Branch-counting basis** (restated per the fixed basis this skill uses): counted — `IF`, `ELSIF`, `CASE`/`WHEN` arms, non-cursor `WHILE` heads, non-cursor `EXIT WHEN`; not counted — `ELSE` arms, `EXCEPTION WHEN` handlers, `FOR`/bare `LOOP` heads, `END IF`/`END CASE`, and any loop test the Cursor Loops column already counts. This is a reproducible keyword count on a stated basis, not cyclomatic complexity, not a defect measure, and not an effort measure.

### Missing-Reference Table

| Source File:Line | Reference Type | Target | Impact |
|---|---|---|---|
| — | — | — | — |

**None.** Every object referenced anywhere in this corpus (`accounts`, `account_holds`, `account_status_log`, `seq_status_log`, `prc_log_status_change`) is defined in the analyzed source. The table has zero rows.

### Coverage Honesty Check

Analysis covers 6 of 6 referenced objects (100% coverage). Zero objects are referenced but not defined in the provided files.

### Dead / Orphan Code

None. Both objects are reachable:
- `prc_log_status_change` has a cited caller: `trg_account_status_sync` at `03-trg_account_status_sync.sql:38`.
- `trg_account_status_sync` is a trigger — always an entry point (see Dimension 2). Its firing statement (`UPDATE accounts SET status = ...`) is external to this corpus (application code or another routine not provided here) — this is a coverage-honesty note (see Coverage Declaration), not evidence of dead code.

---

## 2. Call & Dependency Graph

Scratch file `calls.tsv` (`caller|callee|File:Line`), materialized before this section was written:

```console
$ cat calls.tsv
trg_account_status_sync|prc_log_status_change|03-trg_account_status_sync.sql:38
```

**Dependency Graph:**

```
UPDATE accounts SET status = ...   (external — application code or another routine, not present in this corpus)
  -> TRIGGER trg_account_status_sync (03-trg_account_status_sync.sql:9)
     -> CALL prc_log_status_change (03-trg_account_status_sync.sql:38)
        -> INSERT INTO account_status_log (02-prc_log_status_change.sql:10)
```

Entry point: `trg_account_status_sync` (a trigger — always an entry point). No top-level standalone sproc with zero callers exists in this corpus; `prc_log_status_change` has exactly one caller, the trigger.

**Dynamic SQL flagging:** None. No `EXECUTE IMMEDIATE` or `DBMS_SQL` construct appears anywhere in this corpus (confirmed by the `EXCEPTION`/branch/cursor searches above and by direct reading of both routine bodies, which contain only static `SELECT`/`INSERT`/`UPDATE` statements). No edge in this graph is reduced-confidence.

**External / Unresolvable Edges:** None. The only invocation edge (`trg_account_status_sync` → `prc_log_status_change`) resolves to an object defined in this corpus. No `sp_*`/`xp_*`-equivalent, no `master.`-style reference, no linked-object call exists in Oracle PL/SQL of that shape in this source.

**Liveness Claims Require Citations:** `prc_log_status_change` HAS a caller — cited at `03-trg_account_status_sync.sql:38`. `trg_account_status_sync` is a trigger and is therefore always treated as an entry point per this skill's convention for trigger-less-vs-trigger-bearing Oracle corpora; no external caller citation is required or claimed for it. No explicit `UPDATE accounts SET status = ...` statement (the trigger's firing DML) is present anywhere in the analyzed source — stated here, not implied, per Hard Constraint 6.

**Hub Objects:**

```console
$ wc -l calls.tsv
1 calls.tsv
```

One edge, one caller, one callee. Neither `trg_account_status_sync` (1 distinct callee: `prc_log_status_change`) nor `prc_log_status_change` (1 distinct caller: `trg_account_status_sync`) reaches the 3+ threshold on invocation edges. **No hub objects in the call graph.** Cross-reference Dimension 3: the CRUD-matrix Resource Touch Tally there independently shows no resource touched by 3+ objects either — both measures agree, consistent with a two-object, one-edge system.

**Extraction Sequencing:** (1) `prc_log_status_change` — leaf, zero outgoing calls, extract first; (2) `trg_account_status_sync` — the trigger, always last (it is the entry point that invokes the chain).

---

## 3. CRUD Matrix & Trigger Cascade Map

Scratch file `crud.tsv` (`Object|Resource|Type|CRUD|Pattern|File:Line`), materialized before this section was written:

```console
$ cat crud.tsv
trg_account_status_sync|account_holds|Table|R|SELECT ... INTO (aggregate)|03-trg_account_status_sync.sql:18
trg_account_status_sync|account_holds|Table|R|SELECT (cursor FOR loop)|03-trg_account_status_sync.sql:24
trg_account_status_sync|account_holds|Table|U|UPDATE (inside cursor loop)|03-trg_account_status_sync.sql:28
trg_account_status_sync|accounts|Table|U|UPDATE (own triggering table)|03-trg_account_status_sync.sql:34
trg_account_status_sync|prc_log_status_change|Procedure||direct call|03-trg_account_status_sync.sql:38
prc_log_status_change|account_status_log|Table|C|INSERT INTO|02-prc_log_status_change.sql:10
prc_log_status_change|seq_status_log|Sequence||NEXTVAL|02-prc_log_status_change.sql:11
```

```console
$ wc -l crud.tsv
7 crud.tsv
```

7 rows, rendered below:

| Object | Resource | Type | C | R | U | D | Access Pattern | File:Line |
|---|---|---|---|---|---|---|---|---|
| `trg_account_status_sync` | `account_holds` | Table | | X | | | `SELECT ... INTO` (aggregate) | `03:18` |
| `trg_account_status_sync` | `account_holds` | Table | | X | | | `SELECT` (cursor `FOR` loop) | `03:24` |
| `trg_account_status_sync` | `account_holds` | Table | | | X | | `UPDATE` (inside cursor loop) | `03:28` |
| `trg_account_status_sync` | `accounts` | Table | | | X | | `UPDATE` (own triggering table — see note below) | `03:34` |
| `trg_account_status_sync` | `prc_log_status_change` | Procedure | | | | | direct call | `03:38` |
| `prc_log_status_change` | `account_status_log` | Table | X | | | | `INSERT INTO` | `02:10` |
| `prc_log_status_change` | `seq_status_log` | Sequence | | | | | `NEXTVAL` | `02:11` |

No view rows and no PL/SQL read-side false positives apply here: this corpus has no views, and the one `SELECT ... INTO` (`03:18`) targets the local variable `v_open_holds` for its `INTO` clause but reads FROM the real table `account_holds` — the matrix row correctly records `account_holds` as the resource, not the local variable.

**Resource Touch Tally** (computed by command before this table was written):

```console
$ awk -F'|' '{print $2, $1}' crud.tsv | sort -u | awk '{c[$1]++} END {for (r in c) print r, c[r]}' | sort
account_holds 1
account_status_log 1
accounts 1
prc_log_status_change 1
seq_status_log 1
```

| Resource | Distinct objects touching | Hub? (3+) |
|---|---|---|
| `account_holds` | 1 | no |
| `account_status_log` | 1 | no |
| `accounts` | 1 | no |
| `prc_log_status_change` | 1 | no |
| `seq_status_log` | 1 | no |

**No hub resources.** Every resource in the tally is touched by exactly 1 distinct object — the corpus is too small (2 objects, 5 resources, 7 touches) to have accumulated a 3+-object hub. Cross-reference Dimension 2: consistent with "No hub objects in the call graph" there.

**Trigger Cascade Map:**

```
UPDATE accounts SET status = ...   (external — application code or another routine, not present in this corpus)
  -> TRIGGER trg_account_status_sync (03-trg_account_status_sync.sql:9, BEFORE UPDATE OF status, row-level)
     -> SELECT ... INTO v_open_holds FROM account_holds (03-trg_account_status_sync.sql:18, only when :NEW.status = 'CLOSED')
     -> UPDATE account_holds SET released = 'Y' (03-trg_account_status_sync.sql:28, inside cursor loop, only when :NEW.status = 'CLOSED')
     -> UPDATE accounts SET risk_flag = ... (03-trg_account_status_sync.sql:34) — SELF-REFERENTIAL, see note below
     -> CALL prc_log_status_change (03-trg_account_status_sync.sql:38)
        -> INSERT INTO account_status_log (02-prc_log_status_change.sql:10)
```

Each arrow above cites `FILE:LINE`. No table referenced by the trigger or the procedure lacks a trigger definition in the source worth flagging — `accounts`, `account_holds`, and `account_status_log` are all base tables with no cascading trigger of their own defined in this corpus.

**[HIGH] Self-referential `UPDATE` inside a row-level trigger.** At `03-trg_account_status_sync.sql:34-36`, `trg_account_status_sync` issues `UPDATE accounts SET risk_flag = CASE WHEN :NEW.status = 'FROZEN' THEN 'Y' ELSE 'N' END WHERE account_id = :NEW.account_id;` — a DML statement against `accounts`, the exact table the trigger is itself defined on (`BEFORE UPDATE OF status ON accounts FOR EACH ROW`, `03:9-10`). A row-level trigger that queries or modifies its own base table by anything other than `:NEW`/`:OLD` field references is the textbook precondition for Oracle's mutating-table restriction (`ORA-04091: table ... is mutating, trigger/function may not see it`). This is flagged as a correctness risk to verify against the live schema before extraction — whether this specific statement actually raises depends on server-side specifics not visible from static source alone, so it is stated as a hedged risk, not asserted as a confirmed runtime failure.

**The application must reimplement the entire cascade chain explicitly.** This is a CRITICAL finding — see Executive Summary.

---

## 4. Transaction & Error-Handling Semantics

```console
$ grep -nEw 'EXCEPTION|COMMIT|ROLLBACK|SAVEPOINT|PRAGMA' sql/*.sql
(no output)
```

**Transaction Boundaries:** None found. Neither `prc_log_status_change` nor `trg_account_status_sync` contains an explicit `COMMIT`, `ROLLBACK`, or `SAVEPOINT`. Both execute inside whatever transaction the caller's DML statement is already part of — standard Oracle behavior (PL/SQL blocks do not autocommit; see the dialect reference's "Transaction Control and the Commit Model" section).

**Atomic groups:** The trigger body (`account_holds` reads/updates, the self-referential `accounts` update, and the call into `prc_log_status_change`) and the procedure's `INSERT` all run as part of the single outer DML statement that fired the trigger — there is no internal `COMMIT` splitting this into separate atomic groups.

**Error Swallowing:** None to report — there is no `EXCEPTION` block in either object (confirmed by the empty grep output above), so no exception handler exists that could swallow an error. Any exception raised inside either object propagates uncaught to the caller. This absence is stated explicitly, per this skill's convention that a zero/none finding is reported, not omitted.

**Autonomous Transactions:** None. `PRAGMA AUTONOMOUS_TRANSACTION` does not appear anywhere in this corpus (confirmed by the same empty grep output above).

**Uncatchable Errors (T-SQL-specific):** Not applicable — this corpus is PL/SQL (Oracle), not T-SQL.

---

## 5. Dialect Footguns & Hidden Risks

Scratch file `findings.tsv` (`Category|Scope|Object|File:Line|Evidence|Severity`), materialized before this section was written:

```console
$ cat findings.tsv
NULL_SEMANTICS|production|trg_account_status_sync|03-trg_account_status_sync.sql:18|NVL(SUM(hold_amount), 0)|LOW
HARDCODED_VALUE|production|trg_account_status_sync|03-trg_account_status_sync.sql:17|:NEW.status = 'CLOSED'|MEDIUM
HARDCODED_VALUE|production|trg_account_status_sync|03-trg_account_status_sync.sql:35|:NEW.status = 'FROZEN'|MEDIUM
CONSTRAINT_LOGIC|production|accounts|01-schema.sql:7|updated_at DATE DEFAULT SYSDATE|LOW
CONSTRAINT_LOGIC|production|account_status_log|01-schema.sql:24|changed_at DATE DEFAULT SYSDATE|LOW
GLOBAL_STATE|production|prc_log_status_change|02-prc_log_status_change.sql:11|seq_status_log.NEXTVAL|LOW
```

```console
$ wc -l findings.tsv
6 findings.tsv
```

6 rows. Every production row appears below; every claim below is one of these rows.

**Security context changes:**

```console
$ grep -nE 'AUTHID' sql/*.sql
(no output)
```

No explicit `AUTHID` clause anywhere in this corpus — both `prc_log_status_change` and `trg_account_status_sync` run under the default (`AUTHID DEFINER`). No finding row; the empty search result is the finding.

**NULL vs empty-string semantics:**

```console
$ grep -nE "NVL\(|COALESCE\(|= *''|<> *''" sql/*.sql
sql/03-trg_account_status_sync.sql:18:        SELECT NVL(SUM(hold_amount), 0)
```

One hit. `NVL(SUM(hold_amount), 0)` at `03-trg_account_status_sync.sql:18` — `NVL` always evaluates both arguments (unlike `COALESCE`), but the second argument here is the literal `0` with no side effect, so the usual `NVL`-side-effect hazard does not bite in this specific case. Recorded as `LOW` in `findings.tsv` for completeness of the search class, not because it is dangerous here.

**Hardcoded values & environment names:**

```console
$ grep -nE "= *'[A-Za-z]+'" sql/*.sql
sql/03-trg_account_status_sync.sql:17:    IF :NEW.status = 'CLOSED' THEN
sql/03-trg_account_status_sync.sql:22:           AND released = 'N';
sql/03-trg_account_status_sync.sql:27:                     AND released = 'N') LOOP
sql/03-trg_account_status_sync.sql:29:               SET released = 'Y'
sql/03-trg_account_status_sync.sql:35:       SET risk_flag = CASE WHEN :NEW.status = 'FROZEN' THEN 'Y' ELSE 'N' END
```

Five raw hits, three excluded, two counted as findings:

- `:17` — `:NEW.status = 'CLOSED'` — **finding (business status vocabulary hardcoded in control flow)**.
- `:22`, `:27`, `:29` — `released = 'N'` / `SET released = 'Y'` — ordinary boolean Y/N flag-column literals, not business constants requiring config externalization — **excluded**.
- `:35` — `:NEW.status = 'FROZEN'` — **finding**, same class as `:17`.

Both findings share the same hazard: the account-status taxonomy (`'CLOSED'`, `'FROZEN'`, and by implication whatever other status values `accounts.status` accepts) is embedded directly as string-literal comparisons inside trigger control flow, with no enumeration or reference table backing it in this corpus. **Migration implication:** the application layer must hardcode or otherwise externalize the same vocabulary, and any status-value drift between the two silently breaks the trigger's logic with no error.

**Business rules in constraints:**

```console
$ grep -nE 'DEFAULT[[:space:]]+[A-Za-z_]+' sql/01-schema.sql
7:    updated_at  DATE DEFAULT SYSDATE
24:    changed_at   DATE DEFAULT SYSDATE
```

Two hits, both `DEFAULT SYSDATE` — a function-call default, the same shape as this skill's own `DEFAULT GETDATE()` example. `accounts.updated_at` (`01-schema.sql:7`) and `account_status_log.changed_at` (`:24`) are both stamped by the database at insert time. **Migration implication:** the application must set these timestamps explicitly on insert; a naive port that omits an explicit timestamp write will leave the column `NULL` instead.

**Global & shared state (`GLOBAL_STATE`):**

```console
# package-level state region search — N/A, no CREATE PACKAGE in this corpus
$ grep -nE 'CREATE[[:space:]]+(OR[[:space:]]+REPLACE[[:space:]]+)?PACKAGE' sql/*.sql
(no output)

# global temporary tables / staging-table naming
$ grep -niE 'CREATE[[:space:]]+GLOBAL[[:space:]]+TEMPORARY[[:space:]]+TABLE|ON[[:space:]]+COMMIT[[:space:]]+(DELETE|PRESERVE)[[:space:]]+ROWS|\b(TEMP|TMP)_[A-Za-z0-9_]+' sql/*.sql
(no output)

# ambient session state
$ grep -nE 'SYS_CONTEXT|DBMS_SESSION|USERENV' sql/*.sql
(no output)

# sequences
$ grep -niE '\.NEXTVAL|\.CURRVAL|CREATE[[:space:]]+SEQUENCE' sql/*.sql
sql/01-schema.sql:27:CREATE SEQUENCE seq_status_log START WITH 1 INCREMENT BY 1;
sql/02-prc_log_status_change.sql:11:    VALUES (seq_status_log.NEXTVAL, p_account_id, p_old_status, p_new_status, SYSDATE);
```

- **Package-level state:** not applicable — this corpus defines no package (0 `CREATE PACKAGE`), so there is no package declaration region to search.
- **Global temporary tables / staging tables:** none — the search returned no hits. Stated explicitly, not omitted.
- **Ambient session state (`SYS_CONTEXT`/`DBMS_SESSION`/`USERENV`):** none — the search returned no hits. Stated explicitly, not omitted.
- **Sequences:** `seq_status_log`, defined at `01-schema.sql:27`, is consumed by exactly one routine — `prc_log_status_change`, via `.NEXTVAL` at `02-prc_log_status_change.sql:11`. This is a genuine `GLOBAL_STATE` resource (shared, cross-session, gap-prone by nature), but with a single consumer in this corpus it is the weaker single-writer case, not a shared-state cluster — recorded as such (`LOW` severity) rather than inflated to match the two-writer pattern the sibling `xraytest1`/`fleetbill` fixture demonstrates.

**Other dialect-specific footguns:** No `FORALL`, no implicit-cursor pattern, and no other Oracle-specific construct from the dialect reference's catalog (`ROWNUM`, `(+)` outer join, `DECODE`, `ADD_MONTHS`, `ROUND`, `GREATEST`/`LEAST`, `TO_CHAR`/`TO_DATE` NLS dependence, `FOR ... REVERSE`, etc.) appears in this corpus — none of those keywords occur anywhere in `sql/`.

---

## Confidence & Coverage Declaration

Every number and verdict on these closing lines is copied from the section that owns it.

- **Files analyzed:** 3 of 3 provided.
- **Artifact types covered:** Stored procedures (1), Triggers (1), DDL/table schemas (3 tables + 1 sequence) — from the Context-Intake table. Scalar functions, table-valued functions, views, jobs, packages, and test scripts are all absent (0 each), also from that table.
- **Missing artifacts affecting analysis:** None — every object referenced anywhere in this corpus is defined in this corpus (see Missing-Reference Table, zero rows).
- **Encoding/format issues encountered:** None — all 3 files are ASCII text with no mixed line endings (see `file` output in Context Intake).
- **Path mismatches:** None — every path named in `README.md`'s Layout section matches the actual `sql/` directory contents exactly (see Context Intake path-claims table).

---

## Recommended Next Steps

This section names the downstream consumer of this report, and the optional evidence that would sharpen what that consumer can do — and nothing else. It is a RECOMMENDATION the reader may take or ignore — this report does not invoke anything, and no step below runs automatically. It states no migration pattern, no target architecture, no effort estimate, and no priority ranking; those remain non-goals of this report.

- **Downstream planner:** the `sproc-migration-plan` skill consumes this report — specifically the `### Extraction Metrics` table and the Dimension-5 `GLOBAL_STATE` rows — to sequence and size the extraction. Hand it the path to this file. Note for that downstream consumer: this report's `### Extraction Metrics` table carries one row (`prc_log_status_change`) — `trg_account_status_sync` is a trigger, not a routine, and is not in that table; its cascade and role are in the Component Manifest and the Dimension-3 Trigger Cascade Map instead.
- **Optional runtime evidence pack:** static source cannot show call frequency, row volumes, or which routines are actually invoked in production — and, specific to this corpus, it cannot confirm whether the self-referential `UPDATE` flagged in Dimension 3 (`03-trg_account_status_sync.sql:34`) has ever executed successfully against a live schema. If an execution-statistics export is available (Oracle AWR / `v$sql`), supplying it alongside this report would let the planner separate hot paths from dead weight, and would let this mutating-table risk be confirmed or ruled out directly. No such pack was provided for this analysis — stated here explicitly, not implied.
