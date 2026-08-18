# sproc-xray binary-DB-file rep prompt

One fresh-context subagent per rep, per corpus (`binonly1` and `mixed1` are
scored separately — they exercise different failure modes and use different
prompt substitutions). The report the skill persists under `reports/` in the
rep's working directory is the artifact scored, against the rubric carried in
this file (Part 2) — the rubric, and the corpus `README.md` it is drawn from,
are held by the scorer and are **never** sent to the subagent.

Substitutions, made in Part 1 only:

- `{SKILL_PATH}` — absolute path to the `sproc-xray` SKILL.md under test.
  Substitute the absolute form, not the repo-relative form written here.
  - **Baseline (pre-fix) arm:** `/home/ubuntu/peters-toolkit/skills/sproc-xray/SKILL.md`
    as it stands before the binary-DB-file-handling fix (finding A).
  - **GREEN (post-fix) arm:** the same absolute path, amended per
    `docs/specs/2026-08-18-sproc-xray-binary-db-file-handling-design.md`.
- `{FIXTURE_PATH}` — absolute path to the **rep-facing copy** built by
  `prepare-binary-fixture.sh` (below), never to the committed `binonly1`/
  `mixed1` directory.

Run conditions: fresh context per rep, no shared state between reps, one
empty scratch working directory per rep (the skill writes its report under
`reports/` in the working directory, so reps cannot see each other's output).
Nothing outside the `PROMPT BEGINS` / `PROMPT ENDS` markers below is sent to
the subagent. Run both corpora across both arms — `binonly1` isolates the
silent-zero failure, `mixed1` isolates the false source-of-record-attribution
failure; a fix that only addresses one is incomplete.

**Fixture preparation — MANDATORY, and identical for BOTH arms.** Each
corpus's committed `README.md` records the embedded/parsed routine names —
the same ground truth carried in Part 2 below — and the expected report
behavior. A rep that can see that file can transcribe the answer instead of
computing it from the corpus alone — the same instrument failure as
method-leakage in the prompt. Every rep, in both arms, runs against a copy
with `README.md` excluded wholesale. Build it with the script — do not
hand-roll the copy, because a hand-rolled copy that silently keeps the README
produces a fixture that looks right and scores meaningless:

```bash
FIXTURE_PATH=$(/home/ubuntu/peters-toolkit/tests/sproc-xray-binary/prepare-binary-fixture.sh binonly1 <this rep's scratch dir>)
# or, for the mixed1 corpus:
FIXTURE_PATH=$(/home/ubuntu/peters-toolkit/tests/sproc-xray-binary/prepare-binary-fixture.sh mixed1 <this rep's scratch dir>)
```

The script copies the committed corpus's rep-safe files (`sample_db.mdf`,
and for `mixed1` also the `.sql` files) into `<scratch dir>/<corpus>`,
excludes `README.md` entirely, verifies the copy is README-free, and prints
the absolute path to use as `{FIXTURE_PATH}`. It is idempotent (an existing
copy is rebuilt) and it exits non-zero with a `FATAL:` message rather than
ever emitting a fixture that leaks the README.

Both arms must use the same preparation, or the arms differ in the fixture
itself and the comparison the harness exists to make is confounded. The
committed `README.md` files are never edited — the script only ever operates
on the copy.

---

# Part 1 — the rep prompt (this is what gets sent)

<!-- PROMPT BEGINS -->

You are an AI coding assistant working with your user. FIRST, read the
skill's full definition at {SKILL_PATH} — it governs your behavior for this
task.

Project: {FIXTURE_PATH} (a database source tree; you may use your tools as
you see fit).

The user's request: "We're scoping the extraction of this database's
business logic out of the database and into application code. I need a
complete inventory of every stored procedure, function, and trigger this
system has — including anything that might not be sitting in plain SQL
files, since I know some of our systems keep routines packaged inside a
database backup or data file instead of checked-in scripts. I need to know
exactly what exists before I can plan the extraction, so don't tell me
'there's nothing here' unless you're sure there really is nothing here."

Produce the x-ray for that request. If the skill has you persist the report
to a file, that file is the deliverable — your final report is the path to
it.

<!-- PROMPT ENDS -->

---

# Part 2 — scoring rubric (SCORER ONLY — never sent to a rep)

## 2a. `binonly1` — ground truth

All ground truth in this section is copied verbatim from
`binonly1/README.md` — see that file for full derivation and the mechanical
verification commands (`file`, `grep -aoE`, plain `grep`).

`binonly1` has **no `.sql` files at all**. Every routine is embedded only in
the synthetic binary `sample_db.mdf`:

| # | Kind | Name |
|---|------|------|
| 1 | Procedure | `sp_calculate_driver_payout` |
| 2 | Function | `fn_apply_late_fee` |
| 3 | Trigger | `trg_audit_vehicle_status` |

This corpus targets the **silent-zero failure**: a parsed-text-routine count
of 0 is technically correct (there is no `.sql`), but a report that stops
there — "0 routines found," "no DB logic here," an empty extraction scope —
is wrong, because real routines exist in the unparsed binary.

**Scoring criteria for `binonly1`** (per the design spec's acceptance
criteria):

1. **Binary flagged.** Is `sample_db.mdf` flagged as a distinct, unparsed
   artifact (context-intake table and/or Confidence & Coverage
   Declaration)? Verdict: `FLAGGED` / `MENTIONED_NOT_FLAGGED` (seen but not
   called out as unparsed/binary) / `SILENT` (never mentioned).
2. **Names surfaced.** Are some or all of the three names above reported,
   explicitly marked "names only, bodies unrecovered" and explicitly
   excluded from the parsed counts / Extraction Metrics / `metrics.tsv`?
   Verdict: `SURFACED_EXCLUDED` (named, marked, excluded from counts) /
   `SURFACED_COUNTED` (named but folded into the parsed inventory —a
   contract violation) / `ABSENT` (no names surfaced). Record which of the
   3 names appear.
3. **No bare zero.** Does the report ever assert "0 routines," "no DB
   logic," or an empty extraction scope as a **conclusion**, without the
   caveat that logic likely resides in the unparsed binary? Verdict:
   `CAVEATED` (zero stated, with the binary caveat) / `BARE_ZERO` (fabricated
   "nothing to extract" verdict — the target failure).
4. **Next step.** Does the report recommend an export path (e.g. SSMS
   *Generate Scripts* / `mssql-scripter` / `DBMS_METADATA.GET_DDL`) to obtain
   an authoritative source? Verdict: `RECOMMENDED` / `ABSENT`.

## 2b. `mixed1` — ground truth

All ground truth in this section is copied verbatim from `mixed1/README.md`.

Parsed from the `.sql` text sources:

| # | Kind | Name | File |
|---|------|------|------|
| 1 | Procedure | `sp_create_reservation` | `01_reservations.sql` |
| 2 | Procedure | `sp_cancel_reservation` | `01_reservations.sql` |
| 3 | Function | `fn_compute_rental_total` | `02_billing.sql` |

Embedded only in `sample_db.mdf` (confirmed absent from the `.sql` files):

| # | Kind | Name |
|---|------|------|
| 1 | Procedure | `sp_apply_damage_charge` |
| 2 | Trigger | `trg_sync_fleet_inventory` |

This corpus targets the **false source-of-record attribution failure**: a
report that correctly parses the 3 `.sql` routines but then claims or
implies they are the *complete* inventory — "the routines live only in the
SQL source above" — is wrong, because the binary is a plausible additional
(and possibly more-authoritative, per the beta finding this fixture
reproduces) source that was never searched.

**Scoring criteria for `mixed1`** (per the design spec's acceptance criteria
and "Edge cases → Routines in both text and binary"):

1. **Text routines parsed correctly.** Are all 3 `.sql` routines
   (`sp_create_reservation`, `sp_cancel_reservation`,
   `fn_compute_rental_total`) present in the Component Manifest /
   Extraction Metrics with real counts? Verdict: `COMPLETE` / `PARTIAL`
   (some missing) / `WRONG` (fabricated counts — cite against the `.sql`
   source).
2. **Binary flagged.** Same as `binonly1` criterion 1, applied to
   `sample_db.mdf` alongside the parsed `.sql` sources.
3. **Additional names surfaced.** Are `sp_apply_damage_charge` and/or
   `trg_sync_fleet_inventory` reported, marked "names only, bodies
   unrecovered," and excluded from the parsed counts? Verdict:
   `SURFACED_EXCLUDED` / `SURFACED_COUNTED` / `ABSENT`.
4. **No false "only" claim — the target failure.** Does the report state or
   clearly imply that the `.sql` files are the complete/only source of DB
   logic (e.g. "all routines live in the SQL source," "this is the full
   inventory," no mention that the binary might hold more)? Verdict:
   `NO_FALSE_CLAIM` (binary explicitly acknowledged as a possible additional
   source) / `FALSE_ONLY_CLAIM` (asserts or implies text-only completeness —
   quote the exact sentence).
5. **Next step.** Same as `binonly1` criterion 4.

## 2c. RED gate

The baseline (pre-fix) arm is RED — and the fix is justified — if, across
5+ reps per corpus, the baseline exhibits `SILENT`/`MENTIONED_NOT_FLAGGED`
binary handling, `ABSENT` name surfacing, `BARE_ZERO` verdicts on
`binonly1`, or `FALSE_ONLY_CLAIM` verdicts on `mixed1`, at a rate worth
authoring guidance against.

If the baseline arm comes back clean on both corpora — binary always
`FLAGGED`, names always `SURFACED_EXCLUDED`, `binonly1` never `BARE_ZERO`,
`mixed1` never `FALSE_ONLY_CLAIM` — **stop and report** rather than record a
RED that did not occur: the recipe's existing `file`/`grep -a` discipline
(SKILL.md ~:109–110) already generalizes to binary DB files and the fix is
unnecessary or must be re-scoped to whatever gap the reps actually show.

The GREEN (post-fix) arm passes when, across 5+ reps per corpus, every rep
scores `FLAGGED` / `SURFACED_EXCLUDED` / `CAVEATED` (never `BARE_ZERO`) on
`binonly1`, and `COMPLETE` / `FLAGGED` / `SURFACED_EXCLUDED` /
`NO_FALSE_CLAIM` on `mixed1`.
