# GREEN-arm results — sproc-xray v0.4.0, fixture `xraytest1`

**Arm:** GREEN. `{SKILL_PATH}` = `skills/sproc-xray/SKILL.md` at v0.4.0, amended by
Task 2: the `### Extraction Metrics` subsection and its fixed column set, the
`GLOBAL_STATE` category and search class, the report-template additions, and the
dialect detection patterns.
**Fixture:** the same script-built stripped copy of `tests/sproc-metrics/xraytest1`
that the baseline arm used, built by `prepare-rep-fixture.sh` (both arms, one code
path — see `rep-prompt-template.md`).
**Reps:** 5, fresh context each, one empty scratch working directory per rep.
**Rubric:** `rep-prompt-template.md` Part 2.

**Companion file:** `baseline-results.md` records the RED arm (v0.3.0, 5/5 CLEAN)
and the reasoning that shrank Task 2 to format additions only. Read it first — this
file only makes sense against it.

**Outcome: 5 of 5 conforming, total convergence on the numbers.**

## What this arm could and could not test

The baseline arm came back clean, so **there was no defect to fix and no fact-quality
improvement available to demonstrate.** This arm therefore tests exactly two things:

1. **Regression** — did the amended skill break anything the clean baseline already
   did right? (The only check a clean baseline permits.)
2. **Contract conformance** — do reps now emit the *stable, named structure* a
   downstream planner can parse, instead of five differently-shaped sections?

Nothing below is a claim that v0.4.0 produces better facts than v0.3.0. It does not,
and this experiment could not show it if it did: the baseline was already at ceiling
on every fact-quality criterion in the rubric.

## Convergence — the numbers

Machine-extracted from the five preserved `metrics.tsv` files
(`awk -F'|' '{printf "%s,%s,%s;",$2,$3,$4}'`, then `sort -u | wc -l` → **1**):

| Column | Value across all 5 reps | Ground truth (rubric 2a) |
|---|---|---|
| Params | `3 1 4 2 0 2` | matches |
| Cursor loops | `0 1 0 2 0 0` | matches (incl. the depth-2 nest) |
| Branches | `0 0 11 1 0 2` | matches |

**One distinct numeric signature across five independent fresh-context reps** — the
three numeric columns and the row order are character-identical in all five. Per
writing-skills, variance across reps means the wording is not yet binding; there is
none here on the numbers.

## Pre-registered prediction — CONFIRMED 5/5

The Task 2 implementation report (concern 2) predicted, **before any GREEN rep was
run or scored**, that the newly stated branch basis would move
`prc_apply_rate_rules` from 15 → 11 and `fn_trip_surcharge` from 3 → 2 relative to
the baseline arm. The controller recorded that prediction in the scoring ledger
before scoring began. It held in all five reps.

**This is the stated basis taking effect, not a regression.** The baseline arm's 15
and 3 were credited under rubric 2a's stated-basis exception (all five baseline reps
declared an ELSE-inclusive basis and applied it consistently); the GREEN numbers now
match rubric 2a's own ground truth because the skill states the narrower basis. The
frozen fixture ground truth and the rubric's branch-basis note were **not** changed
in either direction, so the two arms remain comparable.

## Regression check — PASSED

No count regressed against the baseline arm. No global-state fact was lost. No zero
was silently dropped: `prc_purge_stale_holds` is `0 | 0 | 0` in all five, with `none`
for UDTs, written as a row rather than omitted. The near-miss traps stay rejected —
the numeric `FOR` at `03:21` and the `OPEN … FOR` at `03:30` are still excluded from
cursor-loop counts, and `EXCEPTION WHEN OTHERS` at `05:45-47` is still excluded from
branches (now by a stated rule rather than by each rep's own reasoning).

## Contract conformance — what Task 2 was actually for

| Contract element | Baseline arm (v0.3.0) | GREEN arm (v0.4.0) |
|---|---|---|
| Section heading | invented per rep: "Section 6", "Dimension 6", "§6 Migration-Sizing View" | exactly one `### Extraction Metrics`, 5/5 |
| Column set | invented per rep, varying | the exact mandated set, 5/5 |
| Scratch file name | invented: `migration_sizing.tsv` / `sizing.tsv` / `migration-sizing.tsv` | the mandated `metrics.tsv`, 5/5 |
| Global-state findings | ad hoc prose section | `GLOBAL_STATE` category, per-object rows, 5/5 |
| Downstream pointer | absent | `## Recommended Next Steps`, 5/5 |

The baseline arm produced the right facts in five different shapes. A parser cannot
consume five shapes. That gap — not a fact-quality defect — was the justification
for keeping these additions after the RED gate came back clean, and the arm confirms
the gap is closed on this fixture.

## Cluster-join verification — the load-bearing check

The per-object row rule (`GLOBAL_STATE` gets one `findings.tsv` row per **object**
per resource, never one merged row per resource) exists so that shared-state clusters
are *derivable* by joining rows on the resource name. Joining the GREEN reps' rows on
the resource name carried in the verbatim `Evidence` recovers every cluster the
fixture plants:

| Resource | Objects recovered | Consequence |
|---|---|---|
| `g_run_total` | `load_driver_batch` (`03:19`) + `post_batch_totals` (`03:46,49,57`) | 2 objects → cluster edge |
| `tmp_settlement_stage` | `prc_settlement_sweep` INSERT (`05:36`) + `post_batch_totals` SELECT (`03:42`) | 2 objects, **no invocation edge** — the critical cluster |
| `g_last_driver_id` | `load_driver_batch` only | single toucher, correctly weaker |
| `g_batch_id` | `post_batch_totals` only | single toucher, correctly weaker |
| `SYS_CONTEXT` | 2 objects, 3 occurrences | both numbers stated separately |

The `tmp_settlement_stage` pair is the one that matters: two routines functionally
sequenced through a global temporary table with **zero call-graph edge between
them**. Rep 4 promoted it to its headline CRITICAL and rep 5 carried it into
extraction sequencing as an ordering constraint the invocation graph alone cannot
supply. A merged one-row-per-resource finding would have made that pair underivable.

This also settles the CIR-round-2 candidate finding "GLOBAL_STATE rows lack a join
key", which was dropped on the reasoning that the resource name appears in the
verbatim `Evidence` text. It does, in every row. Dropping it was correct; adding a
join-key column would have been an unfalsified addition.

## Variance found, and the REFACTOR decision

**Ruling: no REFACTOR round. Nothing authored.**

writing-skills says to repeat until reps converge, because variance means the wording
is not yet binding. Five reps produced a character-identical numeric table in a
character-identical row order under the mandated heading, column set, and scratch
file name. The wording is binding. Authoring more text now would add guidance no
failure justifies — the same Iron Law that kept the anti-fabrication counters out of
v0.4.0 after the RED gate came back clean.

The variance that does exist is **presentational, and is accepted as such**:

- **Object naming.** All five `metrics.tsv` files use the qualified
  `pkg_fleet_billing.load_driver_batch`. The `GLOBAL_STATE` rows and prose mix the
  qualified and bare forms — rep 4's `findings.tsv` rows use bare
  `load_driver_batch` / `post_batch_totals`, and every report uses both forms
  somewhere in prose. Each report is internally consistent and resolvable, so the
  intra-report join the planner performs is unaffected **on this corpus**.
- **`UDT Usage` rendering.** All five identify the same three constructs on
  `load_driver_batch`; they render them differently (`drivers%ROWTYPE` vs `%ROWTYPE`;
  `t_charge_code_list (VARRAY)` vs bare vs the full `VARRAY(20) OF VARCHAR2(12)`).
  The column is specified as verbatim copy-out, so this is the spec working, not
  drifting.
- **`File` column form.** Bare filename (reps 1–3) vs `sql/`-prefixed (reps 4–5);
  reps 1 and 2 differ on whether a packaged routine's `.pks` is listed alongside the
  `.pkb`.

**Watch item, not a defect (recorded, not acted on).** The qualified/bare naming
variance is cosmetic only because this fixture has one package. On a corpus where two
packages export the same routine name, a bare `Object` value in a `GLOBAL_STATE` row
would not join unambiguously to a qualified `metrics.tsv` row. Nothing failed here,
and one 6-routine fixture is not evidence that it would — so no text was authored
against it. It is the specific thing to look for first if Task 5's larger corpus
shows join trouble.

## Scope limit

Identical to the baseline arm's, and it has not moved:

- This is **one 314-line, 6-routine fixture**, five reps, one dialect (PL/SQL). The
  T-SQL detection patterns in `references/dialects/mssql.md` were authored new and
  are **entirely unexercised** — no rep in either arm analyzed a T-SQL corpus.
- Convergence at this scale says nothing about ADempiere's ~50-object scale, where
  counting volume is far higher and an in-context working set drifts further from the
  on-disk scratch file. Task 5 is where that is tested.
- Criterion 5 (README contamination) remains **not exercised** in this arm too, for
  the same reason as the baseline: the fixture is stripped, so an `INDEPENDENT`
  verdict is trivially true and carries no information.
- The clean baseline means this arm can report *no regression* and *contract
  conformance*. It cannot report improved fact quality, and does not.

## Evidence

Five reports plus their five `metrics.tsv` files are preserved outside this
repository, alongside the controller's per-rep scoring. As with the baseline arm,
x-ray reports of a synthetic fixture are not plugin content and are deliberately not
committed; this file is the surviving record. Re-running either arm uses the same
preparation: `prepare-rep-fixture.sh` plus `rep-prompt-template.md` Part 1.
