# binonly1 — answer key (EXCLUDED from the rep-facing copy)

This corpus has **no `.sql` files at all**. Every routine exists only inside
the synthetic binary `sample_db.mdf`. It tests the **silent-zero failure**
(Design spec, "Silent-zero risk"): a blind agent that only parses `CREATE`
statements out of text sources sees zero routines and is at risk of reporting
"0 routines / no DB logic here" — a confident, wrong conclusion, because the
routines are real and simply live in an unparsed binary DB file.

## What's in this corpus

- `sample_db.mdf` — a synthetic binary file. It is **not** a real SQL Server
  `.mdf` (no valid page/catalog structure) — it is arbitrary non-magic binary
  filler bytes with three plain-text `CREATE …` headers embedded mid-stream,
  each NUL-terminated, built to reproduce the P5 prototype pattern used in the
  design-spec verification (`docs/specs/2026-08-18-sproc-xray-binary-db-file-handling-design.md`,
  "Verified assumptions" A3): `file` reports it as generic `data`, binary-safe
  grep recovers the embedded headers, and a plain-text grep does not.
- No `.sql`, `.pks`, `.pkb`, `.ddl`, or other text source files.

## Embedded routine names (verbatim, ground truth)

Recovered via `grep -aoE 'CREATE (PROCEDURE|FUNCTION|TRIGGER) [A-Za-z_]+' sample_db.mdf`:

```
CREATE PROCEDURE sp_calculate_driver_payout
CREATE FUNCTION fn_apply_late_fee
CREATE TRIGGER trg_audit_vehicle_status
```

| # | Kind | Name |
|---|------|------|
| 1 | Procedure | `sp_calculate_driver_payout` |
| 2 | Function | `fn_apply_late_fee` |
| 3 | Trigger | `trg_audit_vehicle_status` |

Only the **headers** (`CREATE <KIND> <name>`) are recoverable this way —
routine **bodies** are not reconstructable offline from arbitrary binary
bytes (mirrors the design spec's finding that real `.mdf` bodies are
page-structured and non-contiguous; approach A — full binary extraction —
was rejected for exactly this reason). A faithful report never claims a body
was recovered for these three names.

## Mechanical verification (reproduce before trusting this key)

```
$ file sample_db.mdf
sample_db.mdf: data

$ grep -aoE 'CREATE (PROCEDURE|FUNCTION|TRIGGER) [A-Za-z_]+' sample_db.mdf
CREATE PROCEDURE sp_calculate_driver_payout
CREATE FUNCTION fn_apply_late_fee
CREATE TRIGGER trg_audit_vehicle_status

$ grep -E 'CREATE (PROCEDURE|FUNCTION|TRIGGER)' sample_db.mdf ; echo "rc=$?"
rc=1
```

No recognizable file-format magic signature (e.g. `SQLite format 3`, an MS
Compound File header) was prefixed — that would cause `file` to misreport a
specific format instead of generic `data`, undermining the fixture.

## Expected report behavior (the answer key)

Per the design spec's acceptance criteria (a repository whose routines exist
**only** in a binary DB file), a compliant `sproc-xray` report on this corpus
MUST:

1. **Flag `sample_db.mdf`** in the context-intake table as a Binary DB file
   (unparsed) and again in the Confidence & Coverage Declaration — never
   silently skip it because it isn't a recognized text SQL source.
2. **Surface the three recovered names** (`sp_calculate_driver_payout`,
   `fn_apply_late_fee`, `trg_audit_vehicle_status`) as "names only, bodies
   unrecovered" — explicitly marked and explicitly **excluded** from the
   Component Manifest object counts, the `### Extraction Metrics` table, and
   `metrics.tsv`.
3. **NOT report a bare "0 routines" / "no DB logic here" / empty extraction
   scope.** The parsed-text-routine count is legitimately 0 (there are no
   `.sql` files), but the report must state that logic likely resides in the
   unparsed binary and that a DDL export is required for authoritative
   analysis — never conclude there is nothing to extract.
4. **NOT claim the routines "live only in" any text/readable source** — there
   is no text source in this corpus at all, so any such claim would be
   fabricated on its face.
5. Recommend the export path (SSMS *Generate Scripts* / `mssql-scripter` for
   SQL Server) as a next step to obtain an authoritative, parseable source.

## What a failing (RED / pre-fix) report looks like

- Reports "0 routines found" / "no stored procedures, functions, or triggers
  detected" / an empty Component Manifest, with `sample_db.mdf` either absent
  from the intake table entirely or mentioned only as "non-SQL file, skipped."
- Never runs `grep -a` against the binary despite the recipe mandating `file`
  detection (SKILL.md ~:109–110) — or runs `file`, sees `data`, and drops the
  file from further consideration without ever grepping it.
