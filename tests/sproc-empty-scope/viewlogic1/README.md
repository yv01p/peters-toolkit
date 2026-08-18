# viewlogic1 — answer key

A small subscription-billing schema (SQL Server / T-SQL) — dialect-consistent
with `empty1` and with `tests/sproc-xray-binary/binonly1`.

This is the **negative** / over-fire-guard corpus for the empty-scope
short-circuit (design spec `docs/specs/2026-08-18-sproc-duet-empty-scope-design.md`
§2.1, "the short-circuit does **not** fire"). It has **zero routines** — same
as `empty1` on that axis — but it is deliberately **not** empty-scope,
because it carries DB-resident logic in two other categories the x-ray
tracks: a logic-bearing view and business-rule constraints
(`CONSTRAINT_LOGIC`).

## What's in this corpus

- `sql/01-schema.sql` — 2 `CREATE TABLE` statements (`Customers`, `Orders`).
  No procedures, functions, triggers, or views in this file.
- `sql/02-views.sql` — 1 `CREATE VIEW` (`dbo.vw_CustomerOrderSummary`) with
  real logic: two `CASE` expressions producing computed columns, not a
  passthrough projection.
- No `.mdf`/`.ndf`/`.ldf`/`.bak`/`.dbf`/`.dmp` — no binary DB file.

## Ground truth (computed by command over the corpus)

```
$ grep -rniE 'CREATE (OR REPLACE )?(PROCEDURE|FUNCTION|TRIGGER|PACKAGE)' viewlogic1/
(no matches)
$ grep -n 'CREATE VIEW' viewlogic1/sql/*.sql
viewlogic1/sql/02-views.sql:7:CREATE VIEW dbo.vw_CustomerOrderSummary AS
$ grep -n 'CHECK' viewlogic1/sql/01-schema.sql
viewlogic1/sql/01-schema.sql:15:        CONSTRAINT CK_Customers_Tier CHECK (Tier IN ('STANDARD', 'PREMIUM', 'VIP')),
viewlogic1/sql/01-schema.sql:27:        CONSTRAINT CK_Orders_Subtotal CHECK (Subtotal >= 0),
viewlogic1/sql/01-schema.sql:29:        CONSTRAINT CK_Orders_Status CHECK (Status IN ('OPEN', 'SHIPPED', 'CANCELLED'))
$ grep -n 'DEFAULT' viewlogic1/sql/01-schema.sql
viewlogic1/sql/01-schema.sql:17:        CONSTRAINT DF_Customers_CreatedBy DEFAULT SUSER_SNAME(),
viewlogic1/sql/01-schema.sql:19:        CONSTRAINT DF_Customers_CreatedAt DEFAULT SYSUTCDATETIME()
```

| Category | Count |
|---|---|
| Stored procedures | 0 |
| Functions | 0 |
| Triggers | 0 |
| Packages | 0 |
| Logic-bearing views (`CREATE VIEW`) | **1** — `dbo.vw_CustomerOrderSummary` |
| CHECK constraints | **3** — `CK_Customers_Tier` (`01:15`), `CK_Orders_Subtotal` (`01:27`), `CK_Orders_Status` (`01:29`) |
| Logic-bearing DEFAULT clauses | **2** — `DF_Customers_CreatedBy DEFAULT SUSER_SNAME()` (`01:17`, captures the calling principal — not a static literal), `DF_Customers_CreatedAt DEFAULT SYSUTCDATETIME()` (`01:19`, captures wall-clock time at insert — not a static literal) |
| Binary DB files | 0 |

**The logic-bearing view, `dbo.vw_CustomerOrderSummary`** (`sql/02-views.sql:7`):

- `DiscountedTotal` (`02:15-19`) — `Subtotal * CASE c.Tier WHEN 'VIP' THEN
  0.85 WHEN 'PREMIUM' THEN 0.90 ELSE 1.00 END` — a 3-arm tier-based discount
  computation, not a column passthrough.
- `AgingBucket` (`02:20-24`) — a 3-arm `CASE` classifying each order as
  `EXCLUDED` / `AGED` / `CURRENT` based on `Status` and `DATEDIFF` against
  `SYSUTCDATETIME()` — a computed classification, not a stored column.

Routines are 0 — same as `empty1`. But logic-bearing views are 1 (not 0) and
`CONSTRAINT_LOGIC` findings are 5 (3 CHECK + 2 logic-bearing DEFAULT), not 0.
Per design spec §2.1, the empty-scope short-circuit requires **all** of:
0 routines, 0 logic-bearing views, 0 `CONSTRAINT_LOGIC` findings, and no
binary DB file. This corpus satisfies only the first and last of those four
conditions.

## Expected x-ray report behavior (per design spec §2.1)

The short-circuit must **NOT** fire. The report must be the **fuller** form —
covering the view's logic (both `CASE` arms, cited) and the `CONSTRAINT_LOGIC`
findings (all 5 constraints, cited) under Dimension 5 (`Dialect Footguns &
Hidden Risks`, `CONSTRAINT_LOGIC` category) — not the compact "0 DB-resident
routines" skeleton this corpus's sibling `empty1` should produce.

The extraction backlog is still conceptually empty either way (views and
constraints are not migration units per
`sproc-migration-plan/SKILL.md:325`), but the **x-ray itself** must not
collapse to the compact report and hide them — the migration-plan side
deciding they aren't migration units is a separate, later step from the
x-ray under-reporting them in the first place.

**Task-1 scope note:** this corpus is the negative/over-fire-guard fixture
for the empty-scope gate. Per the implementation plan's Task-1/Task-3 split
(`.superpowers/sdd/2026-08-18-sproc-duet-empty-scope-implementation-plan/progress.md`,
"viewlogic1 is an over-fire guard, not a RED→GREEN"), it is **not** one of
Task 1's RED-baseline cells — the pre-fix skill has no short-circuit at all,
so it cannot over-fire yet. `viewlogic1` earns its keep in Task 3, proving
the post-fix skill's new gate stays off here.
