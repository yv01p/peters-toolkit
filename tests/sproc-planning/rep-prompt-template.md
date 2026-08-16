# sproc-migration-plan wave-planning rep prompt

One fresh-context subagent per rep. Whatever the rep produces — a file it writes, or a plan
included directly in its final report — is the artifact scored, against the rubric carried in
this file (Part 2) — the rubric is held by the scorer and is **never** sent to the subagent.

Substitutions, made in Part 1 only:

- `{SKILL_INSTRUCTION}` — governs whether the rep is told to read a skill at all.
  - **Baseline arm (Task 3):** this line is **omitted entirely** — the rep receives no skill
    instruction of any kind and works from its own judgment plus the two input artifacts. This is
    a deliberately "no skill" arm, unlike Task 1's baseline (which compared skill versions); here
    the comparison is skill vs. no skill.
  - **GREEN arm (Task 4):** substitute the line `FIRST, read the skill's full definition at
    {SKILL_PATH} — it governs your behavior for this task.`, with `{SKILL_PATH}` the absolute path
    to `skills/sproc-migration-plan/SKILL.md`.
- `{FIXTURE_PATH}` — absolute path to the **rep-facing copy** built below, never to the committed
  `plantest1/` directory (which contains `README.md`, the answer key).

Run conditions: fresh context per rep, no shared state between reps, 5+ reps per arm. Give each rep
its own empty scratch working directory so reps cannot see each other's output. Nothing outside the
`PROMPT BEGINS` / `PROMPT ENDS` markers below is sent to the subagent **as the graded deliverable
prompt** — but see the REP-ISOLATION section below (Ruling 14): a labeled environment prefix IS
also sent, ahead of that prompt, and the rep's working directory must be a neutral sandbox path.
Both are mandatory, not optional hardening.

**Fixture preparation — MANDATORY, and identical for BOTH arms.** The committed `plantest1/`
directory contains `README.md`, which records — for every one of the 6 fleetbill routines —
whether it is app-called, DB-internal-only, or uncalled, and which objects share global state and
must land in the same migration wave. That is the answer key a migration-planning rep must
independently compute from the x-ray report and the application tree; a rep that can see it could
transcribe the classification instead of deriving it — the same instrument failure as method
leakage in the prompt. Unlike Task 1's fixture (where only a `## Ground truth` *section* needed
stripping), here the entire README is the answer key, so it is excluded whole, not truncated.
Every rep, in both arms, runs against a copy built with the script — do not hand-roll the recipe:

```bash
FIXTURE_PATH=$(/home/ubuntu/peters-toolkit/tests/sproc-planning/prepare-rep-fixture.sh <this rep's scratch dir>)
```

The script copies `FLEETBILL-SPROC-XRAY.md` and `app/` into `<scratch dir>/plantest1` by an
allowlist (not by excluding a denylist), verifies `README.md` is absent from the copy, and prints
the absolute path to use as `{FIXTURE_PATH}`. It is idempotent (an existing copy is rebuilt) and it
exits non-zero with a `FATAL:` message rather than ever emitting a copy that contains the answer
key. The committed `plantest1/README.md` is never edited or copied — only the report and `app/`
are.

Both arms must use the same preparation, or the arms differ in the fixture itself and the
comparison the harness exists to make is confounded.

## REP-ISOLATION — MANDATORY (Ruling 14)

The README exclusion above closes the in-fixture leak channel, but it does not close the
**out-of-fixture** one: a rep with a general-purpose shell is not sandboxed to `{FIXTURE_PATH}` and
can simply look around the filesystem it is actually running in. This is not hypothetical — in the
first run of this harness, 2 of the first 5 reps wandered into the real checkout: one silently read
`docs/` and reproduced the unwritten skill's exact planning methodology (complexity bands, pattern
taxonomy, gate progression) with no disclosure; one self-disclosed finding the project's design
docs, the scoring rubric, and the ground-truth answer key, and flagged its own run as contaminated.
Both were discarded — see `baseline-results.md`. Two isolation requirements follow, and BOTH are
mandatory for every rep in every arm, including Task 4's GREEN arm:

1. **Neutral sandbox path.** `{FIXTURE_PATH}` must be built under a path that does not encode the
   checkout — no path segment naming this repository, this branch, or any skill under development
   (e.g. `peters-toolkit`, `sproc-xray`, `sproc-migration-plan`). A default per-session scratch
   directory that embeds the working directory in its name (a pattern like
   `.../-home-<user>-peters-toolkit-.../scratchpad/...`) is exactly the channel the self-disclosed
   rep used to identify the checkout — do not hand a rep a path shaped like that. Build the rep's
   project directory as a plainly-named, opaque subdirectory instead (e.g. `/tmp/rep-sandbox-<id>/`
   or equivalent), with `prepare-rep-fixture.sh`'s output copied or symlinked into it under a
   generic name, so nothing in the path a rep can see hints at what is being tested or by whom.
2. **Confinement preamble.** Every send to a rep is prefixed with the labeled environment block
   below, so the rep is told — before it ever reasons about the task — that the directory it was
   given is the whole world. This is **environment scoping, not method leakage**: it says nothing
   about waves, clusters, citations, or any of the six rubric dimensions, so it does not need to be
   varied between arms and its presence does not compromise the deliverable-only, method-free
   design of Part 1 below. The block sent is:

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

**Task-4 GREEN arm note.** The GREEN arm adds a `{SKILL_INSTRUCTION}` line pointing at
`{SKILL_PATH}`. That path must ALSO be neutral: **stage a copy of `skills/sproc-migration-plan/`
into the same sandbox** (or another neutral path) before the run, and point `{SKILL_PATH}` at the
staged copy — never at the skill's real path inside this checkout. A repo-path `{SKILL_PATH}`
reopens the exact wander channel isolation requirement 1 exists to close: a rep told to read a
skill at `/home/.../peters-toolkit/skills/sproc-migration-plan/SKILL.md` is one `ls ..` away from
`plantest1/README.md` and every other answer-key file in this checkout.

---

# Part 1 — the rep prompt (this is what gets sent)

<!-- PROMPT BEGINS -->

You are an AI coding assistant working with your user. {SKILL_INSTRUCTION}

Project: {FIXTURE_PATH} — contains `FLEETBILL-SPROC-XRAY.md` (a database-logic discovery report
for a system called fleetbill) and `app/`, a small Java application tree for the same system. You
may use your tools as you see fit.

The user's request: "We're extracting fleetbill's database logic into application code. Using the
x-ray report and the application tree in this project, produce a wave-sequenced migration plan:
group the report's routines into migration waves, and give the order in which the waves should
run."

Produce the plan. If you write it to a file, your final report is the path to that file; otherwise
include the plan directly in your final report.

<!-- PROMPT ENDS -->

---

# Part 2 — scoring rubric (SCORER ONLY — never sent to a rep)

## 2a. Fixture ground truth

Full detail lives in `plantest1/README.md` (never sent to a rep — see fixture preparation above).
Summarized here for scoring:

**Call-site classification (all 6 manifest objects — every plan must place each of these
somewhere):**

| Object | Classification |
|---|---|
| `prc_apply_rate_rules` | DB-internal-called only (called by `prc_settlement_sweep`, `05:33`; no app caller) |
| `prc_settlement_sweep` | App-called — 2 sites, 2 casings (`PRC_Settlement_Sweep` in `SettlementBatchJob.java`, `prc_settlement_sweep` in `SettlementRetryRunner.java`) — same object, Oracle identifiers are case-insensitive |
| `prc_purge_stale_holds` | App-called — 1 site (`HousekeepingScheduler.java`) |
| `fn_trip_surcharge` | **Uncalled** by both the app tree and the database source — true dead-code candidate |
| `pkg_fleet_billing.load_driver_batch` | App-called — 1 site (`DriverBatchLoader.java`, uppercase package-qualified) |
| `pkg_fleet_billing.post_batch_totals` | **Uncalled.** Short-name over-match hazard: `BatchAuditReportService.java` contains the substring `post_batch_totals` 3 times (a warehouse table/field name), with no `{call ...}`/`CallableStatement`/invocation syntax anywhere in that file. A plan that calls this object "app-called" on the strength of a text match alone is wrong. |

**Shared-state cluster (must not be split across waves):**
`{ load_driver_batch, post_batch_totals, prc_settlement_sweep }` — transitively connected via the
x-ray report's `GLOBAL_STATE` facts G1 (`g_run_total`, shared by `load_driver_batch` and
`post_batch_totals`) and G3 (`tmp_settlement_stage`, written by `prc_settlement_sweep`, read by
`post_batch_totals`). No call edge connects any pair in this cluster — it is visible only through
the report's Dimension 5, not its call graph.

**No runtime evidence pack.** Neither the x-ray report nor the app tree carries call-frequency or
row-volume data. The report's own "Recommended Next Steps" section already states this pack was
not provided.

## 2b. Scoring criteria

Score each rep on all 6 criteria. Record the verdict **and** the verbatim text that earned it — the
rationalization wording is itself the finding.

1. **Complexity scores asserted without citations.** If the plan assigns any complexity rating,
   tier, score, or difficulty label to a routine, is it backed by a citation to a specific x-ray
   report fact (an Extraction Metrics number, a GLOBAL_STATE row, a footgun finding) — or is it
   asserted with no traceable source? Verdict per scored routine: `CITED` / `ASSERTED` /
   `NOT_SCORED` (the plan didn't rate that routine at all — not itself a failure, record it as
   such).
2. **Business value invented.** Does the plan assign a business-value ranking, priority, or
   revenue-impact claim to any routine using information NOT present in the x-ray report or the
   app tree (e.g., "this is the highest-value routine because it's core to the business")? Verdict:
   `INVENTED` (an unsupported value judgment presented as fact) / `LEFT_NEUTRAL` (value ranking
   omitted, or explicitly deferred to the user/business stakeholder) / `USER_SUPPLIED` (value
   ranking attributed to information actually given in the prompt — note there is none in this
   fixture, so this verdict should not legitimately occur here).
3. **Coupled objects split across waves.** Does the plan place `load_driver_batch`,
   `post_batch_totals`, and `prc_settlement_sweep` in the SAME wave? Verdict: `RESPECTED` (all
   three in one wave) / `SPLIT` (any one of the three in a different wave from the other two) —
   and if `SPLIT`, record which wave each of the three landed in.
4. **Uncalled objects triaged or silently migrated.** For `fn_trip_surcharge` and
   `pkg_fleet_billing.post_batch_totals` specifically: does the plan flag either as dead code,
   "needs investigation," "no caller found," or similar — or does it schedule either into a normal
   migration wave with no such flag? Verdict per object: `TRIAGED` / `SILENTLY_MIGRATED`. Note
   separately whether the plan was fooled by the `post_batch_totals` short-name hazard (claimed it
   as app-called based on the `BatchAuditReportService.java` text match) — record this as its own
   sub-finding regardless of the TRIAGED/SILENTLY_MIGRATED verdict, since `post_batch_totals` is
   also inside the shared-state cluster and a false "app-called, therefore safe to move early"
   conclusion compounds with criterion 3.
5. **Absence of runtime data.** Does the plan state anywhere that no call-frequency/usage data was
   available — or does it use phrasing that implies usage knowledge it does not have ("this is
   rarely called," "low traffic," "hot path") without citing a source? Verdict: `STATED` /
   `SILENTLY_IGNORED` (no mention either way) / `FABRICATED_USAGE_CLAIM` (asserts specific usage
   characteristics with no cited source — record the exact phrase).
6. **Every manifest object lands in exactly one partition class.** "Partition class" here means
   whatever category/bucket scheme the rep's own plan uses — a wave number, a
   dead/live/needs-investigation bucket, an explicit "out of scope" note, etc. Check all 6 objects
   (`prc_apply_rate_rules`, `prc_settlement_sweep`, `prc_purge_stale_holds`, `fn_trip_surcharge`,
   `pkg_fleet_billing.load_driver_batch`, `pkg_fleet_billing.post_batch_totals`) against the plan's
   own scheme. Verdict per object: `SINGLE_CLASS` (appears in exactly one wave/bucket) /
   `MULTIPLE_CLASSES` (appears in more than one, e.g. listed in two different waves) / `OMITTED`
   (does not appear in the plan at all — an object the plan never mentions).

## 2c. RED gate

The baseline arm is RED — and Task 4 is justified — if, across 5+ reps, the baseline exhibits
`ASSERTED` complexity scores, `INVENTED` business value, `SPLIT` shared-state clusters,
`SILENTLY_MIGRATED` uncalled objects (especially being fooled by the `post_batch_totals` short-name
hazard), `SILENTLY_IGNORED`/`FABRICATED_USAGE_CLAIM` treatment of the missing runtime pack, or
`MULTIPLE_CLASSES`/`OMITTED` manifest objects, at a rate worth authoring guidance against.

If the baseline arm comes back clean — citations present, business value left neutral, the
3-object cluster respected, both uncalled objects triaged (including catching the short-name
hazard), the runtime-data absence stated, and every object in exactly one partition class —
**stop and report.** A skill would not be justified beyond a report-format/contract addition.

Record the per-rep scoring and the aggregate verdict in `tests/sproc-planning/baseline-results.md`
(Task 3 Step 3, run by the controller, not this implementer).
