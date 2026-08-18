# sproc-migration-plan wave-planning rep prompt — DB-only fixture (dbonly1)

One fresh-context subagent per rep. Whatever the rep produces — a file it writes, or a plan
included directly in its final report — is the artifact scored, against the rubric carried in
this file (Part 2) — the rubric is held by the scorer and is **never** sent to the subagent.

This is the DB-only analogue of `tests/sproc-planning/rep-prompt-template.md` (finding #7's test
harness). That harness's fixture (fleetbill) has both an x-ray report and an `app/` tree; this one
tests the skill's behavior when **only** the database dump is provided — no application callers, no
application source tree — mirroring a real DB-only engagement where the skill must produce a
populated plan from structural analysis alone.

Substitutions, made in Part 1 only:

- `{SKILL_INSTRUCTION}` — governs which skill version the rep reads. **BOTH arms** substitute this
  line; this is a **skill-version-vs-skill-version** comparison (not baseline-vs-skill):
  - **RED arm (Task 3):** substitute the line `FIRST, read the skill's full definition at
    {SKILL_PATH} — it governs your behavior for this task.`, with `{SKILL_PATH}` the absolute path
    to a **staged, neutral copy** of the **pre-fix** `skills/sproc-migration-plan/SKILL.md` (the
    version that exhibits finding #7's collapse on DB-only inputs).
  - **GREEN arm (Task 5):** substitute the line `FIRST, read the skill's full definition at
    {SKILL_PATH} — it governs your behavior for this task.`, with `{SKILL_PATH}` the absolute path
    to a **staged, neutral copy** of the **fixed** `skills/sproc-migration-plan/SKILL.md` (the
    version that populates Wave 0 from structural leaves and prevents the collapse).
  
  **Contrast with the sibling templates:** the `tests/sproc-planning/` baseline-vs-skill harness
  **omits** the `{SKILL_INSTRUCTION}` line entirely in its baseline arm (a "no skill" arm); this
  harness sends both arms to skill-reading reps — the difference is which version of the skill each
  reads. Both `{SKILL_PATH}` values must point to **staged, neutral copies** (see REP-ISOLATION
  below) — never to the skill's real path inside this checkout.

- `{FIXTURE_PATH}` — absolute path to the **rep-facing copy** built below, never to the committed
  `dbonly1/` directory (which contains `README.md`, the answer key).

Run conditions: fresh context per rep, no shared state between reps, 5+ reps per arm. Give each rep
its own empty scratch working directory so reps cannot see each other's output. Nothing outside the
`PROMPT BEGINS` / `PROMPT ENDS` markers below is sent to the subagent **as the graded deliverable
prompt** — but see the REP-ISOLATION section below (Ruling 14): a labeled environment prefix IS
also sent, ahead of that prompt, and the rep's working directory must be a neutral sandbox path.
Both are mandatory, not optional hardening.

**Fixture preparation — MANDATORY, and identical for BOTH arms.** The committed `dbonly1/`
directory contains `README.md`, which records — for every one of the 9 manifest objects — call-site
classification, liveness ground truth, Wave-0 leaf expectations, shared-state clusters, trigger
cascade coupling, and partition reconciliation sums. That is the answer key a migration-planning
rep must independently compute from the x-ray report; a rep that can see it could transcribe the
classification instead of deriving it — the same instrument failure as method leakage in the
prompt. The entire README is the answer key here, so it is excluded whole, not truncated. Every
rep, in both arms, runs against a copy built with the script — do not hand-roll the recipe:

```bash
FIXTURE_PATH=$(/home/yv01p/peters-toolkit/tests/sproc-planning-dbonly/prepare-dbonly-fixture.sh <this rep's scratch dir>)
```

The script copies `DBONLY1-SPROC-XRAY.md` into `<scratch dir>/dbonly1` by an allowlist (not by
excluding a denylist), verifies `README.md` is absent from the copy, and prints the absolute path
to use as `{FIXTURE_PATH}`. It is idempotent (an existing copy is rebuilt) and it exits non-zero
with a `FATAL:` message rather than ever emitting a copy that contains the answer key. The
committed `dbonly1/README.md` is never edited or copied — only the report is. **Note:** unlike the
fleetbill and trigger fixtures, this script produces **no `app/` tree** (DB-only input).

Both arms must use the same preparation, or the arms differ in the fixture itself and the
comparison the harness exists to make is confounded.

## REP-ISOLATION — MANDATORY (Ruling 14)

The README exclusion above closes the in-fixture leak channel, but it does not close the
**out-of-fixture** one: a rep with a general-purpose shell is not sandboxed to `{FIXTURE_PATH}` and
can simply look around the filesystem it is actually running in. This is not hypothetical — in the
first run of the sibling fleetbill harness, 2 of the first 5 reps wandered into the real checkout:
one silently read `docs/` and reproduced the unwritten skill's exact planning methodology
(complexity bands, pattern taxonomy, gate progression) with no disclosure; one self-disclosed
finding the project's design docs, the scoring rubric, and the ground-truth answer key, and flagged
its own run as contaminated. Both were discarded — see `tests/sproc-planning/baseline-results.md`.
Two isolation requirements follow, and BOTH are mandatory for every rep in every arm (both the RED
pre-fix arm and the GREEN fixed arm):

1. **Neutral sandbox path.** `{FIXTURE_PATH}` must be built under a path that does not encode the
   checkout — no path segment naming this repository, this branch, or any skill under development
   (e.g. `peters-toolkit`, `sproc-planning-dbonly`, `sproc-migration-plan`, `dbonly-inputs`). A
   default per-session scratch directory that embeds the working directory in its name (a pattern
   like `.../-home-<user>-peters-toolkit-.../scratchpad/...`) is exactly the channel the
   self-disclosed rep used to identify the checkout — do not hand a rep a path shaped like that.
   Build the rep's project directory as a plainly-named, opaque subdirectory instead (e.g.
   `/tmp/rep-sandbox-<id>/` or equivalent), with `prepare-dbonly-fixture.sh`'s output copied or
   symlinked into it under a generic name, so nothing in the path a rep can see hints at what is
   being tested or by whom.
2. **Confinement preamble.** Every send to a rep is prefixed with the labeled environment block
   below, so the rep is told — before it ever reasons about the task — that the directory it was
   given is the whole world. This is **environment scoping, not method leakage**: it says nothing
   about waves, clusters, citations, trigger liveness, or any of the eight rubric dimensions, so it
   does not need to be varied between arms and its presence does not compromise the
   deliverable-only, method-free design of Part 1 below. The block sent is:

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

   This block is prepended **outside** the `PROMPT BEGINS`/`PROMPT ENDS` markers below — the
   graded deliverable prompt inside those markers stays byte-identical across arms (modulo the
   documented `{SKILL_INSTRUCTION}` substitution); only the environment prefix and the two path
   substitutions change between reps, and the environment prefix itself is identical text in both
   arms.

**Both RED and GREEN arm note.** Both arms add a `{SKILL_INSTRUCTION}` line pointing at
`{SKILL_PATH}`. That path must ALSO be neutral: **stage a copy of `skills/sproc-migration-plan/`
into the same sandbox** (or another neutral path) before the run, and point `{SKILL_PATH}` at the
staged copy — never at the skill's real path inside this checkout. A repo-path `{SKILL_PATH}`
reopens the exact wander channel isolation requirement 1 exists to close: a rep told to read a
skill at `/home/.../peters-toolkit/skills/sproc-migration-plan/SKILL.md` is one `ls ..` away from
`dbonly1/README.md` and every other answer-key file in this checkout.

---

# Part 1 — the rep prompt (this is what gets sent)

<!-- PROMPT BEGINS -->

You are an AI coding assistant working with your user. {SKILL_INSTRUCTION}

**TASK CONSTRAINTS:**
- Do NOT invoke the Skill tool with `sproc-migration-plan`, `peters-toolkit:sproc-migration-plan`,
  or any other installed/plugin/slash skill name. The staged skill file at {SKILL_PATH} is the
  SOLE authority for this task — do NOT read, invoke, or reference any skill installed in your
  environment.
- If you invoke the Skill tool or read a skill file other than {SKILL_PATH}, your run is
  contaminated and will be discarded. Work from first principles applied to the staged skill file
  at {SKILL_PATH} only.

Project: {FIXTURE_PATH} — contains `DBONLY1-SPROC-XRAY.md` (an x-ray report for a database system).
**Note:** no application source tree is provided — this is a DB-only database dump. You may use
your tools as you see fit.

The user's request: "We're extracting this database's logic into application code. Using the x-ray
report in this project, produce a wave-sequenced migration plan: group the report's routines into
migration waves, and give the order in which the waves should run."

Produce the plan. If you write it to a file, your final report is the path to that file; otherwise
include the plan directly in your final report.

<!-- PROMPT ENDS -->

---

# Part 2 — scoring rubric (SCORER ONLY — never sent to a rep)

## 2a. Fixture ground truth

Full detail lives in `dbonly1/README.md` (never sent to a rep — see fixture preparation above).
Summarized here for scoring:

**The 9 manifest objects (all migration-unit-bearing objects — every plan must account for each):**

| Object | Ground truth | Evidence |
|---|---|---|
| pkg_order_state | Confirmed live (state resource) | Written by prc_finalize_order + prc_reset_batch_totals; retained in DB, not extracted |
| fn_calculate_discount | Possibly dead → presumptive Wave-0 leaf | Test script only, no caller found (x-ray flags "Possibly dead — test caller only") |
| fn_calculate_tax | Confirmed live (DB-internal helper) | Called by prc_finalize_order at prc_finalize_order.sql:14 (x-ray flags "Confirmed live — called by prc_finalize_order") |
| fn_check_inventory_status | Confirmed dead — defer | No caller, defective (returns uninitialized variable); x-ray flags "Confirmed dead — defective, no callers" |
| fn_format_order_number | Possibly dead → presumptive Wave-0 leaf | Test script only, no caller found (x-ray flags "Possibly dead — test caller only") |
| fn_validate_postal_code | Possibly dead → presumptive Wave-0 leaf | Test script only, no caller found (x-ray flags "Possibly dead — test caller only") |
| prc_finalize_order | Confirmed live (trigger entry point) | Called by trg_order_status_audit at trg_order_status_audit.sql:12 (x-ray flags "Confirmed live — trigger entry point") |
| prc_reset_batch_totals | Possibly dead → presumptive (cluster member) | No caller found (x-ray flags "Possibly dead — no caller found"); shares GLOBAL_STATE with prc_finalize_order |
| trg_order_status_audit | Confirmed live (entry point) | Trigger on UPDATE orders (x-ray flags "Entry point — fires on UPDATE orders") |

**Expected Wave-0 leaf set (structural leaves from DB-only analysis):**
- fn_calculate_discount
- fn_format_order_number
- fn_validate_postal_code

These are **presumptive Wave-0 candidates** under the DB-only planning rules — test-caller-only,
no DB-internal callers, no application callers provided.

**Shared-state cluster (must not be split across waves):**
`{ prc_finalize_order, prc_reset_batch_totals }` — both write pkg_order_state.g_batch_total
(x-ray report Dimension 5: prc_finalize_order.sql:18, prc_reset_batch_totals.sql:8,14). Must
migrate together even though prc_reset_batch_totals has no confirmed caller.

**Trigger cascade cluster (must migrate together):**
`UPDATE orders (external DML) → trg_order_status_audit → prc_finalize_order → fn_calculate_tax`
(x-ray report Dimension 3 Trigger Cascade Map). Forms the cluster
`{ trg_order_status_audit, prc_finalize_order, fn_calculate_tax }`. Note: prc_finalize_order is
ALSO in the shared-state cluster, so the transitive closure is
`{ trg_order_status_audit, prc_finalize_order, fn_calculate_tax, prc_reset_batch_totals }` — these
4 objects are coupled and should migrate in the same wave.

**Partition reconciliation:**
- Wave 0 (leaves): 3 objects (fn_calculate_discount, fn_format_order_number, fn_validate_postal_code)
- Wave 1 (trigger cascade + shared-state cluster): 4 objects (trg_order_status_audit, prc_finalize_order, fn_calculate_tax, prc_reset_batch_totals)
- Retained in DB: 1 object (pkg_order_state — package, state container)
- Deferred (confirmed dead): 1 object (fn_check_inventory_status — defective, no callers)
- **Total:** 3 + 4 + 1 + 1 = 9 ✓

**No application tree provided (DB-only fixture).** No application callers, no application source
tree — the x-ray report analyzed only SQL source in `dbonly1/sql/`.

**No runtime evidence pack provided.** No execution statistics (call frequency, row volumes) were
supplied.

## 2b. Scoring criteria

Score each rep on all 8 dimensions. Record the verdict **and** the verbatim text that earned it —
the rationalization wording is itself the finding.

1. **Executable plan not near-empty.** Does the plan wave-assign the app-facing routines (the
   confirmed-live and possibly-dead-presumptive objects) — or does it collapse to a near-empty plan
   (e.g., only the confirmed-live trigger cascade, with the 3 Wave-0 leaves deferred/missing)? This
   is finding #7's primary signal: the pre-fix skill collapses on DB-only inputs because it cannot
   confirm liveness without application callers, so it defers the 3 possibly-dead leaves instead of
   treating them as presumptive Wave-0 candidates. Verdict: `POPULATED` (the plan wave-assigns the
   3 Wave-0 leaves plus the 4-object trigger/shared-state cluster — 7+ routines scheduled for
   migration) / `NEAR_EMPTY` (the plan schedules only the confirmed-live objects, deferring or
   omitting the 3 possibly-dead leaves — the collapse).

2. **Wave 0 populated from structural leaves.** Does the plan's Wave 0 (or equivalent "extract
   first" bucket) contain the 3 test-caller-only leaves (fn_calculate_discount,
   fn_format_order_number, fn_validate_postal_code) — or is Wave 0 empty/missing? Verdict:
   `POPULATED` (Wave 0 carries all 3, or explains why one is moved elsewhere with a cited reason) /
   `EMPTY_OR_MISSING` (Wave 0 absent, or present but carrying zero of the 3 leaves).

3. **Possibly-dead routines wave-assigned, not deferred.** Are fn_calculate_discount,
   fn_format_order_number, fn_validate_postal_code, and prc_reset_batch_totals all assigned to a
   migration wave (even if flagged "presumptive" or "needs confirmation") — or are they deferred to
   "needs investigation" / "no caller found, skip for now" without a wave assignment? Verdict:
   `WAVE_ASSIGNED` (all 4 possibly-dead objects have a wave number or explicit sequencing) /
   `WRONGLY_DEFERRED` (any of the 4 is explicitly deferred/excluded from migration scope for want
   of a confirmed caller — record which and quote the deferral text).

4. **Confirmed-dead routine deferred/dropped.** Is fn_check_inventory_status (confirmed dead,
   defective, no callers) excluded from migration scope — or does the plan schedule it into a wave?
   Verdict: `DEFERRED` (correctly excluded, deferred, or flagged "do not migrate") /
   `WRONGLY_MIGRATED` (scheduled into a wave despite the x-ray report's "Confirmed dead" flag).

5. **GLOBAL_STATE cluster kept in one wave.** Are prc_finalize_order and prc_reset_batch_totals
   (both write pkg_order_state.g_batch_total) placed in the SAME wave? Verdict: `RESPECTED` (both
   in one wave, shared-state coupling noted) / `SPLIT` (in different waves, or one deferred and one
   migrated — record which wave each landed in).

6. **Trigger cascade clustered; trigger classified live.** Does the plan: (a) treat
   trg_order_status_audit as a live entry point (not deferred for "no app caller")? (b) cluster
   trg_order_status_audit, prc_finalize_order, and fn_calculate_tax together (same wave or explicit
   cascade sequencing)? Verdict: `RESPECTED` (trigger classified live AND the 3-object cascade
   clustered) / `DROPPED` (trigger classified dead/deferred for want of an app caller, OR the
   cascade treated as independent unrelated units with no sequencing relationship).

7. **Stated-Unknowns states DB-only caller/pack gap; no fabricated usage.** Does the plan state: (a)
   no application callers were provided (the x-ray analyzed only SQL source)? (b) no runtime
   evidence pack (call frequency, row volumes) was supplied? (c) objects flagged "possibly dead"
   may be called from application code not in this dump, but that is unknowable from the source
   alone? OR does the plan invent app-caller claims ("called by the OrderService") or usage-based
   sequencing ("extract low-traffic routines first") with no cited source? Verdict: `STATED` (the
   DB-only gap and runtime-pack absence both stated, no fabricated usage claims) / `SILENT` (the
   gap mentioned but not both aspects, or not explicitly) / `FABRICATED` (asserts specific
   app-caller or usage characteristics with no cited source — record the exact phrase).

8. **Partition reconciliation shown and sums.** Does the plan show how its wave assignments,
   deferred objects, and retained-in-DB objects sum to the 9-object manifest total — or does it
   silently under-count (e.g., omit the 3 Wave-0 leaves and show only 6 objects accounted for)?
   Verdict: `RECONCILED` (the plan's own partition scheme sums to 9, even if the waves differ from
   the ground truth) / `BROKEN` (the sum is <9, indicating objects omitted or lost — record the
   under-count).

## 2c. RED gate (pre-fix arm expected failures)

The RED arm (pre-fix skill, Task 3) is RED — and finding #7's fix is justified — if, across 5+
reps, the plans exhibit:
- **`NEAR_EMPTY`** (criterion 1) — the plan collapses to only the confirmed-live objects, deferring
  the 3 possibly-dead leaves for want of application callers.
- **`EMPTY_OR_MISSING`** Wave 0 (criterion 2) — no structural-leaf population.
- **`WRONGLY_DEFERRED`** possibly-dead routines (criterion 3) — fn_calculate_discount,
  fn_format_order_number, fn_validate_postal_code, or prc_reset_batch_totals deferred instead of
  wave-assigned.

Any of these at a rate worth fixing (≥3/5 reps) confirms finding #7.

Secondary failures (criteria 4-8) may also appear but are not finding-#7-specific — they are
general skill quality signals.

## 2d. GREEN bar (fixed arm expected passes)

The GREEN arm (fixed skill, Task 5) passes if, across 5+ reps, the plans exhibit:
- **`POPULATED`** (criterion 1) — the plan wave-assigns 7+ routines (3 Wave-0 leaves + 4-object
  trigger/shared-state cluster).
- **`POPULATED`** Wave 0 (criterion 2) — the 3 structural leaves appear in Wave 0.
- **`WAVE_ASSIGNED`** (criterion 3) — all 4 possibly-dead objects have a wave number.
- **`DEFERRED`** (criterion 4) — fn_check_inventory_status correctly excluded.
- **`RESPECTED`** (criterion 5) — GLOBAL_STATE cluster not split.
- **`RESPECTED`** (criterion 6) — trigger cascade clustered, trigger classified live.
- **`STATED`** (criterion 7) — DB-only gap and runtime-pack absence both noted, no fabricated usage.
- **`RECONCILED`** (criterion 8) — partition sums to 9.

All 8 at ≥4/5 reps = GREEN bar cleared.

Record the per-rep scoring and the aggregate verdict in `tests/sproc-planning-dbonly/red-results.md`
(Task 3, run by the controller) and `tests/sproc-planning-dbonly/green-results.md` (Task 5, run by
the controller).
