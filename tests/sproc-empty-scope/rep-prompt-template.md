# sproc-duet empty-scope rep prompts

Finding B tests two skills against the empty-scope case (design spec
`docs/specs/2026-08-18-sproc-duet-empty-scope-design.md`). This file carries
**two** rep prompts, run over **four** fixture cells total:

| Prompt | Skill under test | Fixture cell (`prepare-empty-scope-fixture.sh` arg) | Corpus | Expected post-fix behavior (§) |
|---|---|---|---|---|
| (a) x-ray-side | `sproc-xray` | `empty` | `empty1` | short-circuit fires (§2.1) |
| (a) x-ray-side | `sproc-xray` | `viewlogic` | `viewlogic1` | short-circuit does NOT fire (§2.1) |
| (b) migration-plan-side | `sproc-migration-plan` | `planning-empty` | `EMPTY1-SPROC-XRAY.md` + `empty1/app` | empty backlog (§2.2) |
| (b) migration-plan-side | `sproc-migration-plan` | `planning-binary` | `BINONLY1-SPROC-XRAY.md` + `binonly1` | binary deferral, not empty backlog (§2.2) |

One fresh-context subagent per rep, per cell — the four cells exercise
different behaviors and are scored separately. Whatever the rep produces — a
report/plan file it writes, or content included directly in its final report
— is the artifact scored, against the ground truth carried in each corpus's
own `README.md` (never sent to a rep) and the RED/GREEN gate criteria in Part
2 below (also never sent to a rep).

**Task-1 scope note.** Only the `empty`, `planning-empty`, and
`planning-binary` cells are part of Task 1's RED baseline (brief Step 5); the
`viewlogic` cell is an over-fire guard exercised in Task 3 against the
post-fix skill, not a RED→GREEN cell — the pre-fix skill has no short-circuit
to over-fire yet, so a pre-fix run of `viewlogic` is not informative for the
RED gate.

Substitutions, made in Part 1 only:

- `{SKILL_PATH}` — absolute path to the SKILL.md under test.
  - **x-ray-side (a):** `/home/ubuntu/peters-toolkit/skills/sproc-xray/SKILL.md`.
    Baseline (RED) arm: as it stands at v0.5.0, no empty-scope short-circuit.
    GREEN arm (Task 3): the same absolute path, amended per the design spec.
  - **migration-plan-side (b):** governed by `{SKILL_INSTRUCTION}`, not a bare
    `{SKILL_PATH}` substitution — see that prompt's own substitution note
    below. It mirrors `tests/sproc-planning/rep-prompt-template.md`'s
    skill-vs-no-skill baseline design, not a version-vs-version one.
- `{FIXTURE_PATH}` — absolute path to the **rep-facing copy** built below,
  never to any committed fixture directory (`empty1/`, `viewlogic1/`,
  `empty-report/`, `binary-report/`, or `tests/sproc-xray-binary/binonly1/` —
  every one of which carries a `README.md` answer key that must never reach a
  rep).

Run conditions: fresh context per rep, no shared state between reps, 3+ reps
per cell (this suite's documented deviation from the rubric's "5+ per arm" —
see finding A precedent and the SDD ledger's rep-count ruling; restate the
deviation in the evidence files). Give each rep its own empty scratch working
directory (the x-ray skill writes its report under `reports/` in the working
directory) so reps cannot see each other's output.

**Fixture preparation — MANDATORY, and identical for every rep in every
cell.** Every committed fixture directory's `README.md` is the answer key for
that fixture — see the file header comment in `prepare-empty-scope-fixture.sh`
for the full rationale (mirrors `tests/sproc-planning/prepare-rep-fixture.sh`
Ruling 14 and `tests/sproc-xray-binary/prepare-binary-fixture.sh`). Build
every rep's fixture with the script — do not hand-roll the copy:

```bash
# x-ray-side (a), empty1:
FIXTURE_PATH=$(/home/ubuntu/peters-toolkit/tests/sproc-empty-scope/prepare-empty-scope-fixture.sh empty <this rep's scratch dir>)
# x-ray-side (a), viewlogic1:
FIXTURE_PATH=$(/home/ubuntu/peters-toolkit/tests/sproc-empty-scope/prepare-empty-scope-fixture.sh viewlogic <this rep's scratch dir>)
# migration-plan-side (b), empty-report + empty1/app:
FIXTURE_PATH=$(/home/ubuntu/peters-toolkit/tests/sproc-empty-scope/prepare-empty-scope-fixture.sh planning-empty <this rep's scratch dir>)
# migration-plan-side (b), binary-report + binonly1:
FIXTURE_PATH=$(/home/ubuntu/peters-toolkit/tests/sproc-empty-scope/prepare-empty-scope-fixture.sh planning-binary <this rep's scratch dir>)
```

The script copies only the rep-safe artifacts for the chosen cell (an
allowlist, not a denylist), excludes every `README.md` wholesale, verifies the
copy is README-free, and prints the absolute path to use as `{FIXTURE_PATH}`.
It is idempotent (an existing copy is rebuilt) and it exits non-zero with a
`FATAL:` message rather than ever emitting a copy that leaks an answer key.
The committed fixtures (including their `README.md` files) are never edited —
only the copy is built and rebuilt.

Every cell, in every arm, must use this same preparation, or the arms differ
in the fixture itself and the comparison the harness exists to make is
confounded.

---

# Part 1a — the x-ray-side rep prompt (sproc-xray)

<!-- PROMPT BEGINS -->

You are an AI coding assistant working with your user. FIRST, read the
skill's full definition at {SKILL_PATH} — it governs your behavior for this
task.

Project: {FIXTURE_PATH} (a SQL Server / T-SQL source tree; you may use your
tools as you see fit).

The user's request: "We're scoping the extraction of this system's database
logic out of the database and into application code. Give me the x-ray of
what's actually DB-resident here — I need to know exactly what we'd be
extracting before we plan anything."

Produce the x-ray for that request. If the skill has you persist the report
to a file, that file is the deliverable — your final report is the path to
it.

<!-- PROMPT ENDS -->

Run this prompt once against the `empty` cell and once against the
`viewlogic` cell (same prompt text, different `{FIXTURE_PATH}`) — they are
scored separately (Part 2a below).

---

# Part 1b — the migration-plan-side rep prompt (sproc-migration-plan)

Mirrors `tests/sproc-planning/rep-prompt-template.md`'s design: baseline vs.
GREEN is a **skill vs. no-skill** comparison here, not a version-vs-version
one (the pre-fix skill has no empty-backlog or binary-deferral rule to
version against).

Substitution for this prompt only:

- `{SKILL_INSTRUCTION}`:
  - **Baseline arm (Task 1):** this line is **omitted entirely** — the rep
    receives no skill instruction of any kind and works from its own
    judgment plus the two input artifacts.
  - **GREEN arm (Task 3):** substitute the line `FIRST, read the skill's full
    definition at {SKILL_PATH} — it governs your behavior for this task.`,
    with `{SKILL_PATH}` the absolute path to
    `skills/sproc-migration-plan/SKILL.md`, amended per the design spec.

## REP-ISOLATION — MANDATORY (mirrors Ruling 14, `tests/sproc-planning/rep-prompt-template.md`)

A rep with a general-purpose shell is not sandboxed to `{FIXTURE_PATH}` and
can look around the filesystem it is actually running in. `tests/sproc-planning`'s
harness measured this directly: 2 of its first 5 reps wandered into the real
checkout. Both isolation requirements are mandatory here too:

1. **Neutral sandbox path.** `{FIXTURE_PATH}` must be built under a path that
   does not encode the checkout — no segment naming this repository, this
   branch, or either skill under development. Do not hand a rep the default
   per-session scratch directory (it embeds the working directory's name);
   build the rep's project directory as a plainly-named, opaque subdirectory
   instead (e.g. `/tmp/rep-sandbox-<id>/`), with `prepare-empty-scope-fixture.sh`'s
   output copied or symlinked into it under a generic name.
2. **Confinement preamble.** Every send to a rep is prefixed with the labeled
   environment block below, sent **outside** the `PROMPT BEGINS`/`PROMPT
   ENDS` markers — it is environment scoping, not method leakage, so it does
   not vary between arms:

   ```
   --- ENVIRONMENT (prepended by the harness; not part of the user's request) ---
   You are working inside a sandboxed project directory: {FIXTURE_PATH}. Treat this directory as
   the ENTIRE project — it is self-contained and has everything you need. Do NOT read, list,
   search, or navigate to any path outside {FIXTURE_PATH} (no `..`, no absolute paths elsewhere,
   no repository root, no filesystem search beyond this directory). If you believe you need
   something outside this directory to complete the task, say so in your final report instead of
   looking for it.
   --- END ENVIRONMENT ---
   ```

**Task-3 GREEN arm note.** When `{SKILL_INSTRUCTION}` is substituted in, its
`{SKILL_PATH}` must ALSO be neutral: stage a copy of
`skills/sproc-migration-plan/` into the same sandbox before the run, and
point `{SKILL_PATH}` at the staged copy — never at the skill's real path
inside this checkout.

<!-- PROMPT BEGINS -->

You are an AI coding assistant working with your user. {SKILL_INSTRUCTION}

Project: {FIXTURE_PATH} — contains an x-ray report (a database-logic
discovery report) and the application tree it was produced against. You may
use your tools as you see fit.

The user's request: "We're extracting this system's database logic into
application code. Using the x-ray report and the application tree in this
project, give me the migration backlog: what needs to move, grouped into
waves if there's anything to sequence."

Produce the plan. If you write it to a file, your final report is the path
to that file; otherwise include the plan directly in your final report.

<!-- PROMPT ENDS -->

Run this prompt once against the `planning-empty` cell and once against the
`planning-binary` cell (same prompt text, different `{FIXTURE_PATH}`) — they
are scored separately (Part 2b below).

---

# Part 2 — scoring criteria (SCORER ONLY — never sent to a rep)

Ground truth for every cell lives in the corpus `README.md` files, held by
the scorer and never sent to a rep:
`empty1/README.md`, `viewlogic1/README.md`. The `empty-report/README.md` and
`binary-report/README.md` fixtures (generated in Task 1 Step 2, not by this
implementer) record the provenance of the two x-ray reports the
migration-plan cells consume.

## 2a. x-ray-side (`empty`, `viewlogic`)

**`empty` cell** — scored against design spec §2.1 and `empty1/README.md`:

1. **Report shape.** `COMPACT` (matches the short-circuit skeleton: headline
   `0 DB-resident routines` with proof block, `### Extraction Metrics`
   heading with an explicit empty body, the two unique dimension headings
   each `None — 0 routines`, `## Coverage Declaration`, terminal STOP with a
   charter-boundary note) / `BALLOONED` (full five-dimension report).
2. **App-layer CRUD matrix.** `ABSENT` / `PRESENT` (a form→table matrix built
   from the C# repositories — out-of-charter per §2.1's "Drops" list).
3. **Injection-site enumeration reframed as app-layer analogue.** `ABSENT` /
   `PRESENT`.
4. **Recommended-Next-Steps pointing at an app-layer refactor** (parameterize
   SQL, introduce a DAL, etc.). `ABSENT` / `PRESENT`.
5. **Headline states `0 DB-resident routines` with a proof block.**
   `STATED_WITH_PROOF` / `STATED_NO_PROOF` / `ABSENT`.
6. **Terminal STOP with charter-boundary note.** `PRESENT` / `ABSENT`.

**`viewlogic` cell** — scored against design spec §2.1 (over-fire guard) and
`viewlogic1/README.md`:

1. **Short-circuit correctly withheld.** `CORRECT_NO_SHORTCIRCUIT` (fuller
   report, view + `CONSTRAINT_LOGIC` findings present) /
   `INCORRECTLY_SHORTCIRCUITED` (collapsed to the compact "0 DB-resident
   routines" skeleton, missing the view/constraint findings).
2. **View logic captured.** Both `CASE` arms of `vw_CustomerOrderSummary`
   (`DiscountedTotal`, `AgingBucket`), cited to `sql/02-views.sql`.
   `COMPLETE` / `PARTIAL` / `ABSENT`.
3. **`CONSTRAINT_LOGIC` findings captured.** All 3 CHECK constraints and both
   logic-bearing DEFAULT clauses (`sql/01-schema.sql`), cited. `COMPLETE` /
   `PARTIAL` / `ABSENT`.
4. **No app-layer ballooning regardless.** `ABSENT` / `PRESENT` (this corpus
   has no `app/` tree, so ballooning here would have to invent one — flag if
   it happens).

## 2b. migration-plan-side (`planning-empty`, `planning-binary`)

**`planning-empty` cell** — scored against design spec §2.2:

1. **Empty backlog with partition reconciliation.** States `0 routines = 0
   wave-assigned + 0 deletion + 0 retained + 0 deferred` (or the equivalent).
   `STATED` / `ABSENT`.
2. **Inverse app-layer refactor content** (parameterize SQL, introduce a DAL,
   re-establish an Oracle/SQL-Server schema, numbered Waves 0–N of app-layer
   work) — the target RED failure. `ABSENT` / `PRESENT`.
3. **Terminal STOP, no further waves proposed.** `PRESENT` / `ABSENT`.

**`planning-binary` cell** — scored against design spec §2.2's binary-DB
gate:

1. **Binary signal detected.** Does the plan read the x-ray report's
   Context-Intake binary row and/or its `## Confidence & Coverage
   Declaration` binary line before concluding? `DETECTED` / `MISSED`.
2. **Binary deferral, not empty backlog.** `DEFERRED` (states something to
   the effect of "extraction backlog cannot be sized: logic likely resides in
   an unparsed binary; export DDL and re-run") / `IMPROVISED_EMPTY` (treats
   the empty `### Extraction Metrics` table as a genuine 0-routine backlog,
   same as `planning-empty`) / `IMPROVISED_OTHER` (some other plan not
   grounded in the binary signal).

## 2c. RED gate

Per design spec §4 (finding-B's implementation discipline) and the brief's
Step 5 RED gate: the x-ray long-report half is skill-mandated (the
full-template rule forces length at every routine count including zero), so
it is expected to reproduce robustly. The app-layer *filler* on the `empty`
cell, and the migration-plan improvisation on both `planning-*` cells, may
appear as **variance** across reps rather than uniformly — that variance is
itself the finding-B inconsistency. Score each cell independently; do not
average across cells.

The baseline is RED — and the corresponding fix text is justified — for a
cell if, across 3+ reps of that cell, the baseline exhibits: on `empty`,
`BALLOONED` shape and/or `PRESENT` app-layer filler at a rate worth authoring
guidance against; on `planning-empty`, `PRESENT` inverse-refactor content;
on `planning-binary`, anything other than `DEFERRED`.

If a cell comes back clean — `empty` produces a terse in-charter compact
report unaided, `planning-empty` produces an empty backlog unaided,
`planning-binary` defers unaided — **stop and report** for that cell rather
than recording a RED that did not occur (brief Step 5's RED gate,
mirroring finding A). The corresponding fix text is then unnecessary or must
be re-scoped to whatever gap the reps actually show. Record per-cell
findings and the aggregate verdict in
`tests/sproc-empty-scope/baseline-results.md` (Task 1 Step 5, run by the
controller with fresh, blind rep subagents — not by this implementer).
