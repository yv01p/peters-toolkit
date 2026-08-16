# Baseline-arm results — sproc-xray v0.4.0, trigger fixtures (`trg-oracle` + `trg-mssql`)

**Arm:** baseline. `{SKILL_PATH}` = a staged neutral copy of `skills/sproc-xray/` at v0.4.0,
unmodified. Unlike the sibling `sproc-metrics` baseline (which tested a skill with *no*
extraction-metrics content at all), v0.4.0 already ships the `### Extraction Metrics` table —
this arm tests whether its current "one row per routine" wording (`SKILL.md:121`) resolves
consistently for a *trigger*, which is not a routine under today's Context-Intake taxonomy.
**Fixtures:** `tests/sproc-triggers/trg-oracle` (reps o1–o3) and `tests/sproc-triggers/trg-mssql`
(reps m1–m3) — 6 reps total, 3 per dialect, each run against the stripped rep-facing copy built
by `prepare-xray-fixture.sh`.
**Reps:** 6, fresh context each (Sonnet, pinned), one neutral leak-free sandbox per rep, current
un-amended skill staged into that same sandbox — REP-ISOLATION (Ruling 14) applied to every rep,
not only a hardened subset.
**Rubric:** `xray-rep-prompt-template.md` Part 2 (criteria 1–4).

**Outcome: RED — mild, real, Oracle-concentrated divergence. Component A is JUSTIFIED AS
SPECIFIED — no shrink.** 5 of 6 reps place the trigger's metrics in the canonical
`### Extraction Metrics` table with correct `Params=0`/`UDT=none`. 1 of 6 (Oracle rep `o1`)
excludes the trigger from that table entirely — moving it to a self-invented "Migration-Sizing
View" extension section — and reports its `Params` cell as `"N/A"` rather than the fixture's
ground-truth `0`. No rep of either dialect got a single Cursor-Loop, Branch, or numeric-Params
count wrong.

## Primary evidence

`.superpowers/sdd/2026-08-16-trigger-first-class-implementation-plan/baseline-rep-evidence/rep-{o1,o2,o3,m1,m2,m3}.md`

Six full rep reports, 3218 lines total (`o1` 544, `o2` 481, `o3` 476, `m1` 501, `m2` 747, `m3`
469). **These are not committed** — `.superpowers/` is gitignored in this repository, the same
convention `tests/sproc-metrics/baseline-results.md` documents for its own (scratch-only)
evidence. They are recorded here as a path so the scoring below is re-auditable for as long as
that directory survives; the scoring itself, and the verbatim quotes below, are the durable
record once it is cleared.

## Tell-scan / isolation check (independently re-verified, not just taken on report)

Every claim in this file was cross-checked directly against the six raw rep reports before being
recorded — not transcribed from the controller's summary. Independently re-ran a leak scan across
all six files for any string that would indicate a rep saw outside its sandbox or was told about
the harness (`peters-toolkit`, `sproc-triggers`, `trigger-first-class`, `worktree`, `Ground
truth`, `baseline arm`, `xray-rep-prompt-template`, `scoring rubric`, `blind rep`): **zero hits
across all six files.** All six ran under a neutral sandbox path (e.g. `/tmp/xrsb/o1/trg-oracle`
— no segment naming this repo, branch, or skill) with a staged copy of `skills/sproc-xray/`
(v0.4.0) as `{SKILL_PATH}`, per REP-ISOLATION.

## Per-rep scoring

Criteria (`xray-rep-prompt-template.md` Part 2b): (1) Computed vs asserted, (2) Fabrication,
(3) Explicit absence — including trigger placement in the metrics table (the RED-gate
criterion), (4) Rationalizations.

| Rep | Dialect | Report LOC | 1. Computed | 2. Fabrication | 3. Trigger placement + zero-case explicitness | 4. Rationalizations | Verdict |
|---|---|---|---|---|---|---|---|
| o1 | Oracle | 544 | COMPUTED (all 4 families, both objects, both the canonical table and its own extension table) | none | trigger **excluded** from the canonical `### Extraction Metrics` table; moved, with a stated reason, to a self-invented "Migration-Sizing View" extension | `Params = "N/A — no formal parameter list"` in place of the fixture's ground-truth `0` | **DIVERGENT** |
| o2 | Oracle | 481 | COMPUTED | none | trigger **included** as a full row in the canonical table; `Params=0`, `UDT=none` both explicit | none | **CLEAN** |
| o3 | Oracle | 476 | COMPUTED | none | trigger **included** as a full row; explicit | none | **CLEAN** |
| m1 | T-SQL | 501 | COMPUTED | none | both triggers **included** as full rows; explicit | none | **CLEAN** |
| m2 | T-SQL | 747 | COMPUTED | none | both triggers **included**; explicit | none | **CLEAN** |
| m3 | T-SQL | 469 | COMPUTED | none | both triggers **included**; explicit | none | **CLEAN** |

Every numeric cell that appears **anywhere** in any of the 6 reports — including o1's
self-invented extension table — matches the fixture ground truth exactly: procedure `Params`
(3 Oracle / 4 T-SQL), Cursor Loops (1 for each cascading trigger, 0 for the `INSTEAD OF DELETE`
trigger and both procedures), Branches (2 / 2 / 1 as designed), `UDT Usage` `none` throughout.
Criterion 2 (Fabrication) is 0/6 without qualification.

### Per-rep detail

- **o1** reasons from the *same* underlying fact every other rep also observed — a trigger's
  `CREATE TRIGGER` banner does not match the `(PROCEDURE|FUNCTION)` pattern the dialect
  reference's parameter-list search uses — but draws a different conclusion from it. Verbatim:
  *"trg_account_status_sync does not match this pattern at all: CREATE TRIGGER is a structurally
  different declaration with no parameter list — see the Migration-Sizing View extension below
  for how it is sized instead"* (rep-o1.md:185), and states the canonical table is *"contractually
  scoped to PROCEDURE/FUNCTION declarations (per the dialect reference's own detection pattern),
  so it has exactly one row in this system"* (rep-o1.md:230). Having decided the trigger has no
  parameter-list construct at all — not even an empty one — it reports `Params` as `"N/A — ...
  this is deliberately N/A, not 0. A 0 is reserved ... for a PROCEDURE/FUNCTION declared with
  empty parentheses"* (rep-o1.md:235-237) instead of the fixture's definitional `0`. Every other
  metric in o1's report (Cursor Loops=1, Branches=2, UDT=none, both correctly derived with the
  same exclusion reasoning as every other rep) is correct — this is a placement/labeling
  divergence, not a counting failure.
- **o2** observes the identical structural fact and reaches the opposite, correct placement:
  *"trg_account_status_sync is a CREATE TRIGGER, which has no PROCEDURE/FUNCTION-style
  parameter-list syntax at all ... → Params = 0, a genuine zero, not a search miss"*
  (rep-o2.md:145) — included directly in the canonical table.
- **o3** likewise: *"trg_account_status_sync is a trigger, not a PROCEDURE/FUNCTION; it has no
  formal parameter list at all ... its Params cell is 0, written as 0, not blank"*
  (rep-o3.md:168), and correctly excludes the trigger's local `%TYPE` declaration from `UDT
  Usage` (rep-o3.md:194) — same reasoning as the fixture's own ground truth.
- **m1** (T-SQL): *"T-SQL CREATE TRIGGER has no formal parameter list (confirmed: neither
  trg_Orders_StatusSync ... nor trg_Orders_PreventDeleteCompleted ... declares one between the
  object name and AS) → Params = 0 for both triggers"* (rep-m1.md:159) — both triggers land in
  the canonical table with correct Cursor Loops/Branches (1/2 and 0/1).
- **m2**, **m3** (T-SQL): both independently produce the identical canonical-table shape — both
  triggers as full rows, `Params=0`/`UDT=none`, correct Cursor Loops/Branches — with their own
  from-scratch documentation-verification and CRUD-matrix work (m2 additionally flags that
  `dbo.Orders` has no `INSERT` anywhere in the provided source, a genuine coverage observation
  outside this rubric's scope).

## Aggregate (6 reps)

- **C1 — computed: 6/6.** Every metric family, every object, in every report, is backed by a
  shown command and its raw output. Zero `ASSERTED` or `ABSENT` cells anywhere.
- **C2 — fabrication: 0/6.** No stated count anywhere (including o1's extension table) disagrees
  with the fixture's ground truth.
- **C3 — trigger placement (the RED-gate criterion): DIVERGES 5-vs-1, entirely on the Oracle
  side.** Oracle: 2/3 clean (o2, o3), 1/3 divergent (o1). T-SQL: 3/3 clean (m1, m2, m3). Both
  sides of the divergence are internally consistent, well-reasoned, and cite the same underlying
  structural fact (a trigger's declaration doesn't match the dialect reference's own
  `PROCEDURE`/`FUNCTION` detection pattern) — this is a genuine reading-of-underspecified-contract
  split, not a mistake by either side.
- **C4 — rationalizations: 1/6.** o1's `Params = "N/A"` is the one hedge-shaped substitution for
  the fixture's computed `0` across all 6 reports; the substitution is explicitly reasoned (not a
  vague hedge like "approximately"), but it still replaces a definite ground-truth value with a
  different token, and a downstream planner parsing this table mechanically would not treat `N/A`
  the same way it treats `0`.

## Root cause

Traces to `SKILL.md:121` ("One row per routine DEFINED in the source...") combined with the
Oracle dialect reference's own parameter-list detection pattern
(`references/dialects/oracle.md`, "Extraction-Metrics Detection Patterns" → "Parameter lists"),
which is scoped to lines matching `(CREATE OR REPLACE )?(PROCEDURE|FUNCTION)`. "Routine" is never
defined to include or exclude a trigger anywhere in the shipped skill text, and the detection
pattern that actually populates the table's rows structurally cannot match a `CREATE TRIGGER`
banner. o1 takes that structural fact as decisive — no matching pattern, no row, full stop — and
invents a parallel table to hold the trigger's numbers instead, reasoning further that since a
trigger's `Params` cell isn't reserved by "empty parentheses" the way a real zero-arg
`PROCEDURE`/`FUNCTION`'s is, `N/A` is the more honest value than `0`. o2, o3, m1, m2, and m3 all
notice the identical structural fact (every one of them states, in their own words, that a
trigger has no `PROCEDURE`/`FUNCTION`-style parameter list) but choose to fold the trigger into
the canonical table anyway and report the zero-arg case as `0` like any other. **Both readings
are defensible given the current wording** — that is what makes this a contract-clarification
gap, not a comprehension failure specific to o1.

Both dialect reference files (`oracle.md` and `mssql.md`) use structurally the same
`PROCEDURE`/`FUNCTION`(`/PROC`)-scoped detection-pattern text for their parameter-list search, so
the divergence is not explained by a wording difference between the two dialect files — none of
the 3 T-SQL reps happened to draw o1's inference, but at n=3 per dialect that is consistent with
sampling noise as much as with a genuine dialect-specific gap. This is exactly why the plan
describes the `mssql.md` clause as **codification** (it guarantees, contractually, what all 3
T-SQL reps already did unaided) rather than **correction** (fixing a divergence T-SQL reps
actually produced) — a distinction worth preserving rather than overselling into a proven
dialect asymmetry from a 3-rep sample.

## Gate outcome and consequence for Task 2

Per `xray-rep-prompt-template.md` §2c, the RED gate does not require a single fixed "right"
answer for the trigger-placement question — it fires on reps reaching different,
internally-consistent conclusions at a rate worth authoring guidance against. That is exactly
what happened: 1/6 reps placed the trigger's metrics outside the fixed contract a downstream
planner mechanically parses (`### Extraction Metrics`), and gave its `Params` cell a token
(`N/A`) a planner script comparing against `0` would not match. **The gate fires RED. Component A
— the `SKILL.md:121` "routine and trigger" wording change, plus the `oracle.md`/`mssql.md`
enumerator clauses specified in the plan — is justified as specified. No scope shrink.**

- The **`SKILL.md:121` change + the `oracle.md` enumerator clause** are corrective: they close a
  divergence one of three independent Oracle reps actually produced, tracing directly to the
  detection pattern's `PROCEDURE`/`FUNCTION` scoping.
- The **`mssql.md` clause** is codification, not correction, on the evidence gathered here: all 3
  T-SQL reps already produced the canonical-table row with the correct `Params=0` unaided: the
  amendment guarantees that outcome contractually rather than fixing an observed T-SQL failure.
- **Component A's justified scope is narrowly the placement contract** (make "one row per
  routine" unambiguously include a trigger, everywhere), **not new anti-fabrication discipline
  text** — no rep of either dialect fabricated a wrong Params/Cursor-Loop/Branch/UDT number, and
  no rep silently dropped a zero-value cell it did report. Task 2 should not add counting-
  discipline prose this evidence doesn't call for.

## Scope limit — do not overstate this arm

This baseline demonstrates a real but narrow contract ambiguity, not a broad counting-competence
problem: every rep, including the divergent one, computed every number correctly by command, with
citations, on both dialects. The divergence rate (1/6, Oracle-only) is modest — this is a
contract-clarification fix, not a rescue of broken extraction logic. As with the sibling
`sproc-metrics`/`sproc-migration-plan` baselines, this result is a ceiling finding on a
deliberately small, 2–3-object-per-dialect fixture built for hand-countability; it does not by
itself establish that trigger-placement ambiguity behaves the same way at the scale of a
multi-trigger, multi-hundred-object corpus (e.g. a future `ADempiere`-scale trigger-bearing
system) — only that on this fixture, with this skill text, the ambiguity is real and
demonstrated, at a rate that justifies the plan's specified fix and no more than that fix.
