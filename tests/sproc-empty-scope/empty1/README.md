# empty1 — answer key

PartsTrack: a small parts-inventory application (SQL Server / T-SQL). This
corpus mirrors the Wave-2 beta finding-B candidate shape (`Inventory-Management-System`,
all SQL inline in application source via string literals, `CommandType.Text`
equivalent) — reauthored here in T-SQL/C# to stay dialect-consistent with the
rest of the sproc-empty-scope suite (`viewlogic1` is T-SQL; the migration-plan
binary cell reuses `tests/sproc-xray-binary/binonly1`, a SQL Server `.mdf`).

This is the **positive** empty-scope corpus: a genuinely empty DB-resident-logic
set, in a supported dialect, with no binary DB file present. Per the design
spec (`docs/specs/2026-08-18-sproc-duet-empty-scope-design.md` §2.1), this is
exactly the condition under which the x-ray's empty-scope short-circuit
**should** fire.

## What's in this corpus

- `app/db/schema.sql` — 4 `CREATE TABLE` statements (`Products`, `Customers`,
  `Orders`, `OrderLines`). No procedures, functions, triggers, views, CHECK
  constraints, or DEFAULT clauses of any kind.
- `app/src/ProductRepository.cs`, `app/src/OrderRepository.cs` — data-access
  classes issuing inline parameterized T-SQL (`SELECT`/`INSERT`/`UPDATE`, one
  multi-statement transaction) as C# string literals via `SqlCommand`.
- `app/src/InventoryReorderService.cs` — the system's actual business logic
  (reorder-quantity sizing, rush-order surcharge pricing) lives here, entirely
  in C#. It reads/writes the database only through the plain CRUD SQL in the
  repositories above.
- `app/src/Program.cs` — wiring / entry point.
- No `.mdf`/`.ndf`/`.ldf`/`.bak`/`.dbf`/`.dmp` — no binary DB file anywhere in
  this corpus, so the binary-DB gate (`sproc-xray/SKILL.md:145`) does not
  apply and cannot suppress the short-circuit.

## Ground truth (computed by command over the corpus)

```
$ grep -rniE 'CREATE (OR REPLACE )?(PROCEDURE|FUNCTION|TRIGGER|PACKAGE)' empty1/
(no matches)
$ grep -rni 'CREATE VIEW' empty1/
(no matches)
$ grep -rniE 'CHECK|DEFAULT' empty1/app/db/schema.sql
(no matches outside comment text)
```

| Category | Count |
|---|---|
| Stored procedures | 0 |
| Functions | 0 |
| Triggers | 0 |
| Packages | 0 (T-SQL corpus; N/A concept anyway) |
| Logic-bearing views (`CREATE VIEW`) | 0 |
| CHECK constraints | 0 |
| Logic-bearing DEFAULT clauses | 0 |
| Binary DB files (`.mdf` etc.) | 0 |

**DB-resident-logic set: empty**, across every category the x-ray's
empty-scope gate (design spec §2.1) tests: 0 routines (procedures + functions
+ triggers + packaged routines) **and** 0 logic-bearing views **and** 0
`CONSTRAINT_LOGIC` findings (CHECK / logic-bearing DEFAULT) **and** no binary
DB file present.

File inventory: `app/db/schema.sql` (44 lines), `app/src/ProductRepository.cs`
(120 lines), `app/src/OrderRepository.cs` (87 lines),
`app/src/InventoryReorderService.cs` (53 lines), `app/src/Program.cs`
(27 lines). 331 lines total across 5 files.

## Expected x-ray report behavior (per design spec §2.1)

The short-circuit **should fire**. The report should be the **compact**
form:

- Headline: `0 DB-resident routines`, with a proof block (the source-file
  glob and the `CREATE (PROCEDURE|FUNCTION|TRIGGER|PACKAGE)` grep, both
  returning 0 — reproducible against the two commands above).
- `## 1. Inventory & Completeness` containing the `### Extraction Metrics`
  **heading** with an explicitly empty body ("0 routines/triggers defined").
- The two unique dimension headings the downstream migration-plan validator
  keys on (`## 3. CRUD Matrix & Trigger Cascade Map`, `## 5. Dialect Footguns
  & Hidden Risks`), each with a `None — 0 routines` body.
- `## Coverage Declaration` (0 objects provided; empty routine set fully
  covered).
- Terminal STOP with a one-line charter-boundary note (application-layer
  refactoring is out of this skill's charter).
- Optionally, one factual sentence on where the logic actually lives ("all DB
  access is inline application SQL; business logic lives in
  `InventoryReorderService.cs`") — this is context for the 0-finding, not
  analysis.

**What the report must NOT contain** (the Wave-2 ballooning this fixture is
built to catch): a form→table CRUD matrix built from the C# repositories, an
enumeration of injection-adjacent findings in `ProductRepository.cs`/
`OrderRepository.cs` reframed as "application-layer analogues," or a
Recommended-Next-Steps section pointing at an app-layer refactor
(parameterize SQL, introduce a DAL, etc.). All of that is legitimate
analysis for a different tool — it is out of `sproc-xray`'s charter, which is
DB-resident logic only.

## Expected migration-plan behavior (per design spec §2.2)

Consumed as `EMPTY1-SPROC-XRAY.md` (the report fixture generated from a real
x-ray run against this corpus — see `../empty-report/README.md` for
provenance) together with this corpus's `app/` tree, `sproc-migration-plan`
should state the empty extraction backlog with the trivial partition
reconciliation (`0 routines = 0 wave-assigned + 0 deletion + 0 retained + 0
deferred`) and terminate — no inverse-refactor content, no application-layer
waves, no DAL/schema-refactor plan.
