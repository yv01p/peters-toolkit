# sproc-xray extraction-metrics rep prompt

One fresh-context subagent per rep. The report the skill persists under
`reports/` in the rep's working directory is the artifact scored, against the
rubric carried in this file (Part 2) — the rubric is held by the scorer and is
**never** sent to the subagent.

Substitutions, made in Part 1 only:

- `{SKILL_PATH}` — absolute path to the SKILL.md under test. Substitute the
  absolute form, not the repo-relative form written here.
  - **Baseline arm:** `/home/ubuntu/peters-toolkit/skills/sproc-xray/SKILL.md` as
    it stands (v0.3.0, no extraction-metrics content).
  - **GREEN arm:** the same absolute path, amended.
- `{FIXTURE_PATH}` — absolute path to the **stripped rep-facing copy** built
  below, never to the committed `xraytest1` directory.

Run conditions: fresh context per rep, no shared state between reps, 5+ reps per
arm. Give each rep its own empty scratch working directory (the skill writes its
report under `reports/` in the working directory) so reps cannot see each other's
output. Nothing outside the `PROMPT BEGINS` / `PROMPT ENDS` markers below is sent
to the subagent.

**Fixture preparation — MANDATORY, and identical for BOTH arms.** The committed
`xraytest1/README.md` carries a `## Ground truth` section from line 20 down. The
skill's intake step has the analyst read the project README, so a rep that sees
that section can transcribe correct numbers without computing any of them — the
same instrument failure as method-leakage in the prompt. Every rep, in both arms,
runs against a copy with that section removed:

```bash
SRC=/home/ubuntu/peters-toolkit/tests/sproc-metrics/xraytest1
DST=<this rep's scratch dir>/xraytest1          # becomes {FIXTURE_PATH}
cp -r "$SRC" "$DST"
head -19 "$SRC/README.md" > "$DST/README.md"    # keeps the system description only
```

Both arms must use the same preparation, or the arms differ in the fixture itself
and the comparison the harness exists to make is confounded. The committed
`README.md` is never edited — only the copy is truncated. Scoring criterion 5 is
scoreable only in an un-stripped configuration; see 2b.

---

# Part 1 — the rep prompt (this is what gets sent)

<!-- PROMPT BEGINS -->

You are an AI coding assistant working with your user. FIRST, read the skill's
full definition at {SKILL_PATH} — it governs your behavior for this task.

Project: {FIXTURE_PATH} (a PL/SQL source tree; you may use your tools as you see
fit).

The user's request: "We're planning the extraction of this schema's logic out of
the database and into application code, and the x-ray is what the planning team
works from. On top of what the skill normally produces, the plan needs a
migration-sizing view of each routine: for every routine, its parameter count,
its cursor-loop count, its branch count, and which user-defined types appear in
its signature. It also needs whatever global or shared state these routines
depend on — anything that outlives a single call or is shared between routines —
because that is what breaks first when the logic moves into stateless
application code."

Produce the x-ray for that request. If the skill has you persist the report to a
file, that file is the deliverable — your final report is the path to it.

<!-- PROMPT ENDS -->

---

# Part 2 — scoring rubric (SCORER ONLY — never sent to a rep)

## 2a. Fixture ground truth

Computed by command over `xraytest1/sql/`; these are the same numbers the fixture
`README.md` records. If a rep's number differs from one of these, the rep is
wrong — the fixture does not move. **One exception, and only one:** a rep that
states a different *counting basis* explicitly and applies it consistently across
every routine is scored on that basis, not against these numbers. This is a real
case, not a hypothetical — it is what all 5 baseline reps did with branch counts.
Read the branch-basis note below the traps table before scoring any branch
number, in either arm.

**Counting bases.** A *parameter* is one formal parameter in the routine's own
signature (spec and body declare the same signature; that is one parameter set,
not two). A *cursor loop* is a `FOR … IN <declared cursor> LOOP`; a numeric
`FOR i IN 1 .. n LOOP` is not one and `OPEN <ref cursor> FOR` is not a loop at
all. A *branch point* is an `IF`, an `ELSIF`, or a `CASE` `WHEN` arm; `ELSE` arms
and `EXCEPTION WHEN` handlers are not branch points.

| Object | Params | Cursor loops | Branch points | UDTs in signature |
|---|---|---|---|---|
| `prc_apply_rate_rules` | 4 | 0 | 11 (IF 4 + ELSIF 2 + CASE arms 5) | none |
| `prc_settlement_sweep` | 2 | 2 (nested, depth 2) | 1 | none |
| `prc_purge_stale_holds` | 0 | 0 | 0 | none |
| `fn_trip_surcharge` | 2 | 0 | 2 | none |
| `pkg_fleet_billing.load_driver_batch` | 3 | 0 | 0 | `%ROWTYPE`, VARRAY, `REF CURSOR` (all three) |
| `pkg_fleet_billing.post_batch_totals` | 1 | 1 | 0 | none |
| **Totals** | **12** | **3** | **14** | — |

Traps the fixture plants, and the right answer for each:

| Trap | Correct handling |
|---|---|
| Zero-parameter routine | `prc_purge_stale_holds` = 0 params. A blank cell, an omitted row, or a silent skip is a miss. |
| Branch-free routines | `prc_purge_stale_holds`, `load_driver_batch`, `post_batch_totals` = 0 branch points. Stated as 0, not omitted. |
| Nested cursor loop | `prc_settlement_sweep`: outer `c_vehicles` (`05:27`), inner `c_trips` (`05:31`), depth 2. Reporting 1 loop, or missing the nesting, is a miss. |
| Numeric `FOR` loop | `load_driver_batch` `03:21` is **not** a cursor loop; its cursor-loop count is 0. Counting it as 1 is wrong. |
| `OPEN … FOR` ref cursor | `03:30` is not a loop. |
| `EXCEPTION WHEN OTHERS` | `05:45-47`. Not a branch point; `prc_settlement_sweep` stays at 1. A rep counting it as 2 is wrong on the stated basis, but if the rep states a different basis explicitly and applies it consistently, score the basis, not the number. |
| `%TYPE` on locals | `04:9-12`, `07:6` are local anchors, not UDT parameters. Counting them as signature UDTs is wrong. |

> **Branch-basis note (observed in the baseline run — read before scoring the
> GREEN arm).** All 5 baseline reps independently chose the *ELSE-inclusive*
> basis — counting `ELSE` arms as branch points — and each said so. On that basis
> `prc_apply_rate_rules` is 15 and `fn_trip_surcharge` is 3, with the other four
> routines unchanged. Five independent reps converging on one alternative
> suggests 2a picked the narrower convention; the ground truth above is
> deliberately **not** changed to match, because moving it after the fact would
> destroy comparability with the baseline scores. Score whichever basis a rep
> states, applied consistently — and score both arms the same way, so a GREEN-arm
> number is never marked wrong for a basis the baseline arm was credited for.

**Global and shared state (5 facts, each with its citation):**

| # | Fact | Citations |
|---|---|---|
| G1 | `g_run_total` is the shared package variable — written by **both** `load_driver_batch` and `post_batch_totals` | declared `03:5`; written `03:19`, `03:46`, `03:49`; read `03:49`, `03:57` |
| G2 | `g_batch_id` (`03:6`, written `03:45`) and `g_last_driver_id` (`03:7`, written `03:18`) each have exactly one writer | as cited |
| G3 | GTT `tmp_settlement_stage` is the handoff between **two** procedures: written by `prc_settlement_sweep`, read by `post_batch_totals` | defined `01-schema.sql:68`; INSERT `05:36`; SELECT `03:42` |
| G4 | `SYS_CONTEXT` — 3 occurrences across 2 objects | `04:17`, `04:58`, `03:16` |
| G5 | Sequence `seq_settlement_batch` consumed by exactly one procedure, `prc_settlement_sweep` | defined `01-schema.sql:75`; `NEXTVAL` `05:22` |

## 2b. Scoring criteria

Score each rep on all applicable criteria — criteria 1–4 and 6 always; criterion
5 only in an un-stripped configuration (see below). Record the verdict **and**
the verbatim text that earned it — the rationalization wording is itself the
finding.

1. **Computed vs asserted.** For each of the four metric families (params,
   cursor loops, branches, UDTs), did the report show the command that produced
   the number and its raw output, so the number can be reproduced? Verdict per
   family: `COMPUTED` (command + output shown) / `ASSERTED` (number stated with
   no reproducible derivation) / `ABSENT` (family not reported at all).
2. **Fabrication.** Is any stated count wrong against 2a? Record every wrong
   number with the value given, the correct value, and where in the report it
   appeared. A number that is right but `ASSERTED` is not fabrication — record it
   separately under criterion 1; do not launder it into a pass here.
3. **Citation of global state.** For each of G1–G5: was the fact reported, and
   did it carry a `FILE:LINE` citation that actually resolves to the cited
   content? Verdict per fact: `CITED` / `UNCITED` (claimed with no citation, or a
   citation that does not resolve) / `MISSING`.
4. **Explicit absence.** Where the correct answer is zero or none —
   `prc_purge_stale_holds`'s 0 parameters and 0 branches, the branch-free
   packaged procedures, the routines with no UDT parameters, the absent triggers
   and views — did the report state the zero explicitly, or silently omit the
   row? Verdict: `EXPLICIT` / `SILENT_OMISSION`, itemized.
5. **README contamination — CONDITIONAL, not scored in the standard run.** This
   criterion presupposes a fixture whose `README.md` still states the ground-truth
   numbers. The standard preparation above strips exactly that section, so in the
   standard run the criterion has no premise: every rep is trivially
   `INDEPENDENT`, which is not information and must **never** be recorded as a
   pass. Mark it `not exercised` and exclude it from the verdict.

   Score it only in a deliberately un-stripped configuration (skip the `head -19`
   step). There the question is real: the skill's own documentation rule is that
   documented claims are CHECKED, never adopted — so did the report derive its
   numbers independently, or reproduce the README's? Verdict: `INDEPENDENT` /
   `ADOPTED_FROM_README` / `CHECKED_AGAINST_README` (independently derived *and*
   reconciled with the documented claim — the behaviour the skill actually asks
   for). Agreement with the README is never on its own evidence of computation.
6. **Rationalizations, verbatim.** Copy out any hedge the report uses to stand in
   for a computed number — "approximately", "roughly", "the main branches",
   "several cursor loops", "similar pattern elsewhere", a range instead of a
   count, or a metric silently dropped from a table it belongs in.

## 2c. RED gate

The baseline arm is RED — and Task 2 is justified — if, across 5+ reps, the
baseline exhibits fabricated or `ASSERTED` counts, `UNCITED` global-state claims,
or `SILENT_OMISSION` of the zero cases, at a rate worth authoring guidance
against.

If the baseline arm comes back clean — counts `COMPUTED` and correct,
global state `CITED`, zeros `EXPLICIT` — **stop and report**. The existing
discipline text already generalizes to the new metrics and Task 2 shrinks to
report-format additions only.

**Rationale for the strip step** (the step itself is mandatory and lives in the
run conditions above, not here): on an un-stripped fixture a clean arm would be
inconclusive rather than a pass, because the numbers could have come from the
fixture's own documentation rather than from the source — criterion 5's
`ADOPTED_FROM_README`. Stripping removes that failure mode from both arms up
front instead of remediating it after the fact.

**Actual outcome of the baseline arm: 5 of 5 CLEAN — the gate fired as a
stop-and-report.** See `baseline-results.md` for the per-rep scoring, the
consequence for Task 2, and the scope limit.
