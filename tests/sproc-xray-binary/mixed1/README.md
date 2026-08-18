# mixed1 — answer key (EXCLUDED from the rep-facing copy)

This corpus has routines in **both** real `.sql` text sources **and** a
synthetic binary `sample_db.mdf` that carries *additional* routines not
present in the `.sql` files. It reproduces the beta finding directly: the
Car-Rental-Database candidate whose routines existed in both a Word doc and
`rental_cars.mdf`, where the blind agent recovered the text-source routines
but asserted they "live **only** inside" the text source — never searching
the binary, which was the actual deployed source of record. This corpus
tests that **false source-of-record attribution** failure.

## What's in this corpus

- `01_reservations.sql`, `02_billing.sql` — real, parseable T-SQL text
  routines.
- `sample_db.mdf` — a synthetic binary file (same construction as
  `binonly1/sample_db.mdf`: non-magic filler bytes with plain-text
  `CREATE …` headers embedded mid-stream, NUL-terminated). `file` reports
  `data`; binary-safe grep recovers the headers; plain-text grep does not.
  It embeds **two routine names that do not appear anywhere in the `.sql`
  files** — i.e. genuinely additional routines, not duplicates.

## Routines in the `.sql` text sources (ground truth)

| # | Kind | Name | File |
|---|------|------|------|
| 1 | Procedure | `sp_create_reservation` | `01_reservations.sql` |
| 2 | Procedure | `sp_cancel_reservation` | `01_reservations.sql` |
| 3 | Function | `fn_compute_rental_total` | `02_billing.sql` |

## Routines embedded ONLY in `sample_db.mdf` (ground truth)

Recovered via `grep -aoE 'CREATE (PROCEDURE|FUNCTION|TRIGGER) [A-Za-z_]+' sample_db.mdf`:

```
CREATE PROCEDURE sp_apply_damage_charge
CREATE TRIGGER trg_sync_fleet_inventory
```

| # | Kind | Name |
|---|------|------|
| 1 | Procedure | `sp_apply_damage_charge` |
| 2 | Trigger | `trg_sync_fleet_inventory` |

Confirm these two names are absent from the `.sql` files:

```
$ grep -rn 'sp_apply_damage_charge\|trg_sync_fleet_inventory' *.sql
(no output — confirms the binary's routines are additional, not duplicates)
```

Only the headers are recoverable this way — bodies for these two names are
not reconstructable offline (same rationale as `binonly1`).

## Mechanical verification (reproduce before trusting this key)

```
$ file sample_db.mdf
sample_db.mdf: data

$ grep -aoE 'CREATE (PROCEDURE|FUNCTION|TRIGGER) [A-Za-z_]+' sample_db.mdf
CREATE PROCEDURE sp_apply_damage_charge
CREATE TRIGGER trg_sync_fleet_inventory

$ grep -E 'CREATE (PROCEDURE|FUNCTION|TRIGGER)' sample_db.mdf ; echo "rc=$?"
rc=1
```

No recognizable file-format magic signature was prefixed to `sample_db.mdf`
— it classifies as generic `data`, not a specific known format.

## Expected report behavior (the answer key)

Per the design spec's "Edge cases" ("Routines in both text and binary — the
candidate-3 case") and acceptance criteria, a compliant `sproc-xray` report
on this corpus MUST:

1. **Parse the three `.sql` routines normally** — `sp_create_reservation`,
   `sp_cancel_reservation`, `fn_compute_rental_total` — into the Component
   Manifest / Extraction Metrics with real counts (params, branches, etc.).
2. **Flag `sample_db.mdf`** in the context-intake table as a Binary DB file
   (unparsed) and in the Confidence & Coverage Declaration.
3. **Surface the two additional recovered names**
   (`sp_apply_damage_charge`, `trg_sync_fleet_inventory`) as "names only,
   bodies unrecovered," explicitly excluded from the parsed counts,
   Extraction Metrics table, and `metrics.tsv`.
4. **NOT claim the routines "live only in" the `.sql` files / the text
   source is the complete inventory.** The binary is a plausible additional,
   possibly more-authoritative source of record and must be stated as such
   — the report must not imply the 3 parsed `.sql` routines are the entire
   universe of DB logic in this repository.
5. **NOT report "no DB logic" or an empty scope** (moot for the parsed-count
   dimension here since 3 routines were legitimately found — but relevant if
   a rep enumerates DB logic per-source and dismisses the binary's
   contribution as zero/none rather than "unparsed, possibly non-empty").
6. Recommend the export path as a next step to determine whether
   `sp_apply_damage_charge` / `trg_sync_fleet_inventory` are real production
   routines requiring migration planning.

## What a failing (RED / pre-fix) report looks like

- Parses the 3 `.sql` routines correctly, but then states or implies
  something like "all DB logic for this repository lives in the `.sql`
  files above" / "the routines live only in the SQL source" — the false
  source-of-record attribution this corpus targets.
- Mentions `sample_db.mdf` only in passing (e.g. "1 non-SQL binary file
  present, not analyzed") without ever running `grep -a` against it, so the
  two additional names never surface anywhere in the report.
