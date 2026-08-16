# orderguard (T-SQL / SQL Server)

A minimal orders schema for a small order-processing system. An `AFTER
UPDATE` trigger reacts to status changes and cascades into one standalone
procedure that writes an audit trail; a second, `INSTEAD OF DELETE` trigger
guards against deleting completed orders. Two triggers, one standalone
procedure, no views, no CLR types.

Layout:

- `sql/01-schema.sql` — tables (`dbo.Orders`, `dbo.OrderStatusLog`)
- `sql/02-sp_LogOrderStatusChange.sql` — standalone procedure, called from
  the `AFTER` trigger below
- `sql/03-trg_Orders_StatusSync.sql` — `AFTER UPDATE` trigger (the cascade)
- `sql/04-trg_Orders_PreventDeleteCompleted.sql` — `INSTEAD OF DELETE`
  trigger (realism object, modeled on PBD-Project's
  `trg_Orders_PreventModifyingCompletedOrders`)

## Ground truth

This fixture exists to be measured, so the measurements are recorded here.
Every number below was produced by running a command against the files in
`sql/`, not by reading them.

**Counting bases** (same bases as `tests/sproc-metrics/xraytest1/README.md`
adapted to T-SQL, plus the trigger-specific notes below). A *parameter* is
one formal `@`-prefixed parameter in the routine's own declaration. A
*cursor loop* is a declare/open/fetch/close cycle, counted once per cursor
(the priming `FETCH` before the `WHILE` and the `FETCH` inside it are the
SAME loop). A *branch point* is an `IF`, an `ELSE IF`, or a `CASE` `WHEN`
arm; bare `ELSE`, `BEGIN`/`END` delimiters, and `CATCH` handlers are not
branch points.

**Trigger-specific basis.** Both triggers' `Params` are `0`, definitionally
— T-SQL triggers take no parameters and never match the
`CREATE|ALTER ... PROCEDURE|PROC|FUNCTION` search. `UDT Usage` is `none`
for both triggers and for the procedure: this corpus has no table-valued
parameter, no CLR/assembly type, and no system type (`hierarchyid`,
`geography`, `geometry`, `sql_variant`, `xml`). Each trigger file opens
with an out-of-body `IF OBJECT_ID(...) IS NOT NULL DROP TRIGGER` drop-guard
that runs BEFORE `CREATE TRIGGER` — it is excluded from that trigger's
branch count; only the `CREATE TRIGGER ... AS BEGIN ... END` body counts.
There is no firing `WHEN` clause to exclude in T-SQL (unlike Oracle) — the
`WHILE @@FETCH_STATUS = 0` cursor-loop head is the exclusion that matters
here instead, per the double-count rule below.

### Per-object metrics

```console
$ grep -niE '^[[:space:]]*(CREATE|ALTER)[[:space:]]+(OR[[:space:]]+ALTER[[:space:]]+)?(PROCEDURE|PROC|FUNCTION)[[:space:]]' sql/*
sql/02-sp_LogOrderStatusChange.sql:4:CREATE PROCEDURE dbo.sp_LogOrderStatusChange
```

One banner match. Reading `02-sp_LogOrderStatusChange.sql:4-8` through the
`AS` counts 4 comma-separated `@`-formals: `@OrderID`, `@OldStatus`,
`@NewStatus`, `@Severity`. Neither trigger's `CREATE TRIGGER` banner
matches this search — `TRIGGER` is not `PROCEDURE`/`PROC`/`FUNCTION` —
which is why both triggers' `Params` are stated as `0` by definition, not
by this command.

```console
$ grep -niE 'DECLARE[[:space:]]+[^[:space:]]+[[:space:]]+CURSOR|OPEN[[:space:]]+|FETCH[[:space:]]+NEXT|CLOSE[[:space:]]+|DEALLOCATE[[:space:]]+|WHILE[[:space:]]+@@FETCH_STATUS' sql/*
sql/03-trg_Orders_StatusSync.sql:20:    DECLARE status_cursor CURSOR FOR
sql/03-trg_Orders_StatusSync.sql:26:    OPEN status_cursor;
sql/03-trg_Orders_StatusSync.sql:27:    FETCH NEXT FROM status_cursor INTO @order_id, @old_status, @new_status;
sql/03-trg_Orders_StatusSync.sql:29:    WHILE @@FETCH_STATUS = 0
sql/03-trg_Orders_StatusSync.sql:38:    FETCH NEXT FROM status_cursor INTO @order_id, @old_status, @new_status;
sql/03-trg_Orders_StatusSync.sql:41:    CLOSE status_cursor;
sql/03-trg_Orders_StatusSync.sql:42:    DEALLOCATE status_cursor;
```

Seven raw hits, all one cursor (`status_cursor`): declare (`:20`), open
(`:26`), priming fetch (`:27`), the `WHILE @@FETCH_STATUS = 0` loop head
(`:29`), the in-loop fetch (`:38`), close (`:41`), deallocate (`:42`). Per
the "count once per cursor" rule, this is **1 cursor loop**, in
`trg_Orders_StatusSync`. Neither `sp_LogOrderStatusChange` nor
`trg_Orders_PreventDeleteCompleted` has any hit in this search — 0 cursor
loops for each.

```console
$ grep -niEw 'IF|ELSE|CASE|WHEN|WHILE|BEGIN|END|CATCH' sql/*
sql/03-trg_Orders_StatusSync.sql:4:IF OBJECT_ID(N'[dbo].[trg_Orders_StatusSync]', N'TR') IS NOT NULL
sql/03-trg_Orders_StatusSync.sql:12:BEGIN
sql/03-trg_Orders_StatusSync.sql:15:    IF NOT UPDATE(status)
sql/03-trg_Orders_StatusSync.sql:29:    WHILE @@FETCH_STATUS = 0
sql/03-trg_Orders_StatusSync.sql:30:    BEGIN
sql/03-trg_Orders_StatusSync.sql:31:        IF @new_status = 'CANCELLED'
sql/03-trg_Orders_StatusSync.sql:33:        ELSE
sql/03-trg_Orders_StatusSync.sql:39:    END
sql/03-trg_Orders_StatusSync.sql:43:END;
sql/02-sp_LogOrderStatusChange.sql:10:BEGIN
sql/02-sp_LogOrderStatusChange.sql:15:END;
sql/04-trg_Orders_PreventDeleteCompleted.sql:6:IF OBJECT_ID(N'[dbo].[trg_Orders_PreventDeleteCompleted]', N'TR') IS NOT NULL
sql/04-trg_Orders_PreventDeleteCompleted.sql:14:BEGIN
sql/04-trg_Orders_PreventDeleteCompleted.sql:17:    IF EXISTS (SELECT 1 FROM deleted WHERE status = 'COMPLETED')
sql/04-trg_Orders_PreventDeleteCompleted.sql:18:    BEGIN
sql/04-trg_Orders_PreventDeleteCompleted.sql:21:    END
sql/04-trg_Orders_PreventDeleteCompleted.sql:25:END;

```

Per object:

**`trg_Orders_StatusSync`** — 9 raw hits, 7 exclusions, 2 counted:
- `:4` — `IF OBJECT_ID(...) IS NOT NULL` — the out-of-body drop-guard,
  running before `CREATE TRIGGER` at `:8` — **excluded**.
- `:12`, `:30`, `:39`, `:43` — `BEGIN`/`END` block delimiters — **excluded**
  (never branch points on this basis).
- `:15` — `IF NOT UPDATE(status)` — **counted (1)**.
- `:29` — `WHILE @@FETCH_STATUS = 0` — this IS the cursor loop counted
  above; per the double-count rule it contributes `0` here — **excluded**.
- `:31` — `IF @new_status = 'CANCELLED'` — **counted (2)**.
- `:33` — bare `ELSE` — **excluded** (no condition tested at `ELSE`).

Trigger branch total: **2**.

**`sp_LogOrderStatusChange`** — 2 raw hits (`:10`, `:15`), both `BEGIN`/
`END` delimiters — **excluded**. Branch total: **0**.

**`trg_Orders_PreventDeleteCompleted`** — 6 raw hits, 5 exclusions, 1
counted:
- `:6` — the out-of-body drop-guard, before `CREATE TRIGGER` at `:10` —
  **excluded**.
- `:14`, `:18`, `:21`, `:25` — `BEGIN`/`END` delimiters — **excluded**.
- `:17` — `IF EXISTS (SELECT 1 FROM deleted WHERE status = 'COMPLETED')` —
  **counted (1)**.

Trigger branch total: **1**.

```console
$ grep -niE 'READONLY|CREATE[[:space:]]+TYPE|AS[[:space:]]+TABLE|EXTERNAL[[:space:]]+NAME|ASSEMBLY|hierarchyid|geography|geometry|sql_variant|xml' sql/*
```

Zero hits — the empty output is itself the result. `UDT Usage` is `none`
for all three objects.

| Object | Kind | Defined at | Params | Cursor loops | Branches | UDT Usage |
|---|---|---|---|---|---|---|
| `dbo.sp_LogOrderStatusChange` | standalone procedure | `02-sp_LogOrderStatusChange.sql:4` | 4 | 0 | 0 | none |
| `dbo.trg_Orders_StatusSync` | trigger (`AFTER UPDATE`) | `03-trg_Orders_StatusSync.sql:8` | 0 | 1 | 2 | none |
| `dbo.trg_Orders_PreventDeleteCompleted` | trigger (`INSTEAD OF DELETE`) | `04-trg_Orders_PreventDeleteCompleted.sql:10` | 0 | 0 | 1 | none |
| **Totals** | 3 objects | — | **4** | **1** | **3** | — |

### Traps this fixture plants

- **Both triggers' `Params` are `0` by definition, not by search.** The
  parameter-list search matches only `PROCEDURE`/`PROC`/`FUNCTION` banners;
  `CREATE TRIGGER` never matches it. A blank cell or an omitted row for
  either trigger is a miss.
- **The out-of-body drop-guard is not a branch.** Each trigger file opens
  with `IF OBJECT_ID(...) IS NOT NULL DROP TRIGGER ...; GO` — idiomatic
  T-SQL, and it runs BEFORE `CREATE TRIGGER`, not inside the trigger body.
  Counting `trg_Orders_StatusSync:4` or
  `trg_Orders_PreventDeleteCompleted:6` inflates each trigger's branch
  count by one.
- **`WHILE @@FETCH_STATUS = 0` is the cursor loop, not a branch.**
  `trg_Orders_StatusSync:29` is the one line where the two columns would
  double-count if the exclusion were skipped: it is already the trigger's
  1 cursor loop, so it contributes `0` to Branches. Every T-SQL cursor loop
  is a `WHILE`, so this exclusion applies every time a cursor loop is
  present — skipping it double-counts the loop as a second branch on top
  of the two genuine `IF`s.
- **Bare `ELSE` is not a branch.** `trg_Orders_StatusSync:33` sets the
  `ELSE` path of the `IF` at `:31`; the decision was already made at the
  `IF`, so `ELSE` itself does not add a branch point.
- **`BEGIN`/`END` are delimiters, not branches**, even though both appear
  in the same keyword search as `IF`/`WHEN`/`CASE`. Every `BEGIN`/`END`
  raw hit across all three files is excluded.
- **No firing `WHEN` clause exists in T-SQL** (unlike Oracle) — there is
  nothing in this dialect's trigger header for a keyword search to
  conflate with a body branch. The corresponding trap here is the
  drop-guard `IF` and the cursor-loop `WHILE`, both above.
- **Standalone-procedure branch-free case.** `sp_LogOrderStatusChange` is a
  single `INSERT` with zero conditionals — `0` branches, stated as `0`,
  not omitted.
- **The `INSTEAD OF` trigger is realism, not the cascade.**
  `trg_Orders_PreventDeleteCompleted` does not call
  `sp_LogOrderStatusChange` — only `trg_Orders_StatusSync` does, at
  `03-trg_Orders_StatusSync.sql:36` (`EXEC dbo.sp_LogOrderStatusChange
  @order_id, @old_status, @new_status, @severity;`), inside the cursor
  loop, once per changed row. That is the one call edge in the system, and
  the only trigger cascade in this corpus.
