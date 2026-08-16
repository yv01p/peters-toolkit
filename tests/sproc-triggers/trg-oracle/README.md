# accountguard (Oracle / PL/SQL)

A minimal account schema for a small ledger system. A row-level trigger keeps
`accounts.risk_flag` in sync and releases holds when an account closes; the
trigger's own firing DML cascades into one standalone procedure that writes
an audit trail. There is one trigger, one standalone procedure, no packages,
and no views.

Layout:

- `sql/01-schema.sql` — tables (`accounts`, `account_holds`,
  `account_status_log`) and the audit-log sequence
- `sql/02-prc_log_status_change.sql` — standalone procedure, called from the
  trigger below
- `sql/03-trg_account_status_sync.sql` — the trigger

## Ground truth

This fixture exists to be measured, so the measurements are recorded here.
Every number below was produced by running a command against the files in
`sql/`, not by reading them.

**Counting bases** (same bases as `tests/sproc-metrics/xraytest1/README.md`,
plus the trigger-specific notes below). A *parameter* is one formal
parameter in the routine's own signature. A *cursor loop* is a
`FOR … IN <cursor-or-inline-query> LOOP`, or an explicit
`OPEN`/`FETCH`/`CLOSE` cycle driven by a loop, counted once per cursor. A
*branch point* is an `IF`, an `ELSIF`, or a `CASE` `WHEN` arm; `ELSE` arms
and `EXCEPTION WHEN` handlers are not branch points.

**Trigger-specific basis.** A trigger has no parameter list — `Params` is
always `0`, definitionally, never computed by the parameter-list search
(which only matches `PROCEDURE`/`FUNCTION` banners). `UDT Usage` is always
`none` for a trigger in this fixture: the trigger has no signature at all,
so anything a UDT search matches inside its `DECLARE` section is a local
anchor, not a signature type — see the `%TYPE` trap below. The trigger's
`REFERENCING` clause and its `WHEN (<condition>)` firing predicate sit in
the trigger's HEADER, before the body's `BEGIN`, and neither is a branch
point — see the header-`WHEN` trap below.

### Per-object metrics

```console
$ grep -nE '^[[:space:]]*(CREATE[[:space:]]+(OR[[:space:]]+REPLACE[[:space:]]+)?)?(PROCEDURE|FUNCTION)[[:space:]]+[A-Za-z_][A-Za-z0-9_$#]*' sql/*
sql/02-prc_log_status_change.sql:4:CREATE OR REPLACE PROCEDURE prc_log_status_change (
```

`prc_log_status_change` has one banner match; reading its declaration
(`02-prc_log_status_change.sql:4-8`) through the closing `)` counts 3
comma-separated formals (`p_account_id`, `p_old_status`, `p_new_status`).
The trigger's banner (`CREATE OR REPLACE TRIGGER …`) does not match this
search at all — `TRIGGER` is not `PROCEDURE`/`FUNCTION` — which is exactly
why its `Params` is stated as `0` by definition, not by this command.

```console
$ grep -nE 'CURSOR[[:space:]]+[A-Za-z_]|FOR[[:space:]]+[A-Za-z_][A-Za-z0-9_$#]*[[:space:]]+IN[[:space:]]|OPEN[[:space:]]+|FETCH[[:space:]]+' sql/*
sql/03-trg_account_status_sync.sql:24:        FOR h IN (SELECT hold_id
```

One hit, one cursor loop: `03-trg_account_status_sync.sql:24`, an
inline-query cursor `FOR` loop (`FOR h IN (SELECT …) LOOP`, closed at
`:31`). `prc_log_status_change` has zero cursor-search hits — 0 cursor
loops.

```console
$ grep -nEw 'IF|ELSIF|WHEN|WHILE|ELSE|EXCEPTION|EXIT' sql/*
sql/03-trg_account_status_sync.sql:13:    WHEN (NEW.status != OLD.status)
sql/03-trg_account_status_sync.sql:17:    IF :NEW.status = 'CLOSED' THEN
sql/03-trg_account_status_sync.sql:32:    END IF;
sql/03-trg_account_status_sync.sql:35:       SET risk_flag = CASE WHEN :NEW.status = 'FROZEN' THEN 'Y' ELSE 'N' END
```

Four raw hits, two exclusions, two counted branches:

- `:13` — the trigger's HEADER `WHEN (...)` firing predicate. This is a
  firing-condition clause, not a `CASE WHEN` arm and not a branch inside the
  trigger body — **excluded**. (It is the header trap: a naive keyword
  search cannot tell this `WHEN` apart from a real `CASE WHEN` arm by the
  keyword alone; telling them apart requires reading which side of `BEGIN`
  the hit falls on.)
- `:17` — `IF :NEW.status = 'CLOSED' THEN` — **counted (1)**.
- `:32` — `END IF;` — the `END IF` terminator, not a fresh `IF` — **excluded**
  (same trap as `xraytest1`: a substring match over-counts `IF`; `END IF`
  must be dropped explicitly).
- `:35` — `CASE WHEN :NEW.status = 'FROZEN' THEN 'Y' ELSE 'N' END` — the
  `WHEN` arm is a genuine `CASE`-expression branch — **counted (2)**. The
  `ELSE 'N'` on the same line is not a branch point and is not counted.

Trigger branch total: **2**. `prc_log_status_change` has zero hits in this
search — 0 branches.

```console
$ grep -nE '%ROWTYPE|%TYPE|IS[[:space:]]+RECORD|VARRAY|IS[[:space:]]+TABLE[[:space:]]+OF|REF[[:space:]]+CURSOR|SYS_REFCURSOR' sql/*
sql/03-trg_account_status_sync.sql:15:    v_open_holds account_holds.hold_amount%TYPE;
```

One hit, and it is the trap: `v_open_holds account_holds.hold_amount%TYPE`
at `03-trg_account_status_sync.sql:15` is a **local variable declaration**
inside the trigger's `DECLARE` section, anchored to a column for
schema-drift safety — it is not a parameter and the trigger has no
signature for it to appear in. `UDT Usage` for the trigger is `none`.
`prc_log_status_change` has zero hits in this search — `none` as well.

| Object | Kind | Defined at | Params | Cursor loops | Branches | UDT Usage |
|---|---|---|---|---|---|---|
| `prc_log_status_change` | standalone procedure | `02-prc_log_status_change.sql:4` | 3 | 0 | 0 | none |
| `trg_account_status_sync` | trigger (`BEFORE UPDATE OF status`, row-level) | `03-trg_account_status_sync.sql:9` | 0 | 1 | 2 | none |
| **Totals** | 2 objects | — | **3** | **1** | **2** | — |

### Traps this fixture plants

- **Trigger `Params` is `0` by definition, not by search.** The
  parameter-list search only matches `PROCEDURE`/`FUNCTION` banners; a
  trigger's banner never matches it. Reporting the trigger with a blank
  `Params` cell, or omitting the row, is a miss — `0` must be written.
- **Trigger `UDT Usage` is `none`, and the one `%TYPE` hit in the corpus is
  the reason why.** `v_open_holds account_holds.hold_amount%TYPE` at `:15`
  is a local anchor inside the trigger's `DECLARE` section. Counting it as
  a trigger UDT is wrong on two counts: it isn't in a signature, and the
  trigger has no signature at all.
- **The header `WHEN (...)` firing predicate is not a branch.** It sits
  before the trigger body's `BEGIN` (line 13, body starts at line 16). Only
  the `CASE WHEN` arm inside the body (`:35`) counts. Conflating the two
  because both match the keyword `WHEN` inflates the trigger's branch count
  to 3.
- **`REFERENCING NEW AS NEW OLD AS OLD`** (`:11`) is also header syntax,
  same treatment as the firing `WHEN` — it contributes nothing to Params,
  Cursor loops, Branches, or UDT Usage.
- **`END IF` is not a second `IF`.** `:32` is the terminator closing the
  `IF` opened at `:17` — one `IF`, one `END IF`, one branch point, not two.
- **Standalone-procedure branch-free case.** `prc_log_status_change` is a
  single `INSERT` with zero conditionals — `0` branches, stated as `0`, not
  omitted.
- **The cascade.** `trg_account_status_sync` calls
  `prc_log_status_change(:NEW.account_id, :OLD.status, :NEW.status)` at
  `03-trg_account_status_sync.sql:38` — the trigger's firing DML (an
  `UPDATE OF status` on `accounts`) is what reaches the standalone
  procedure. This is the one call edge in the system.
