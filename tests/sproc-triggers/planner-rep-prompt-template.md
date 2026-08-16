# sproc-migration-plan wave-planning rep prompt — trigger fixture (trgplan1)

One fresh-context subagent per rep. Whatever the rep produces — a file it writes, or a plan
included directly in its final report — is the artifact scored, against the rubric carried in
this file (Part 2) — the rubric is held by the scorer and is **never** sent to the subagent.

This is the trigger analogue of `tests/sproc-planning/rep-prompt-template.md`. That harness's
fixture (fleetbill) has no trigger at all; this one exercises Component B specifically — whether an
unguided planner counts, classifies, and sequences a trigger correctly when the trigger is a live
DB-internal entry point with no app caller.

Substitutions, made in Part 1 only:

- `{SKILL_INSTRUCTION}` — governs whether the rep is told to read a skill at all.
  - **Baseline arm (Task 3):** this line is **omitted entirely** — the rep receives no skill
    instruction of any kind and works from its own judgment plus the two input artifacts. This is
    a deliberately "no skill" arm, unlike Task 1's baseline (which compared skill versions); here
    the comparison is skill vs. no skill.
  - **GREEN arm (Task 4):** substitute the line `FIRST, read the skill's full definition at
    {SKILL_PATH} — it governs your behavior for this task.`, with `{SKILL_PATH}` the absolute path
    to a **staged, neutral copy** of `skills/sproc-migration-plan/SKILL.md` (never the real
    in-checkout path — see the Task-4 GREEN arm note under REP-ISOLATION below).
- `{FIXTURE_PATH}` — absolute path to the **rep-facing copy** built below, never to the committed
  `trgplan1/` directory (which contains `README.md`, the answer key).

Run conditions: fresh context per rep, no shared state between reps, 5+ reps per arm. Give each rep
its own empty scratch working directory so reps cannot see each other's output. Nothing outside the
`PROMPT BEGINS` / `PROMPT ENDS` markers below is sent to the subagent **as the graded deliverable
prompt** — but see the REP-ISOLATION section below (Ruling 14): a labeled environment prefix IS
also sent, ahead of that prompt, and the rep's working directory must be a neutral sandbox path.
Both are mandatory, not optional hardening.

**Fixture preparation — MANDATORY, and identical for BOTH arms.** The committed `trgplan1/`
directory contains `README.md`, which records — for both of the corpus's 2 logic units
(`prc_log_status_change`, `trg_account_status_sync`) — whether it is app-called, DB-internal-called,
or a live DB-internal entry point with no app caller, and the Dimension-3 cascade binding the two
together. That is the answer key a migration-planning rep must independently compute from the x-ray
report and the application tree; a rep that can see it could transcribe the classification instead
of deriving it — the same instrument failure as method leakage in the prompt. As with the fleetbill
fixture, the entire README is the answer key here, so it is excluded whole, not truncated. Every
rep, in both arms, runs against a copy built with the script — do not hand-roll the recipe:

```bash
FIXTURE_PATH=$(/home/ubuntu/peters-toolkit/tests/sproc-triggers/prepare-planner-fixture.sh <this rep's scratch dir>)
```

The script copies `TRIGGER-SPROC-XRAY-baseline.md` and `app/` into `<scratch dir>/trgplan1` by an
allowlist (not by excluding a denylist), verifies `README.md` is absent from the copy, and prints
the absolute path to use as `{FIXTURE_PATH}`. It is idempotent (an existing copy is rebuilt) and it
exits non-zero with a `FATAL:` message rather than ever emitting a copy that contains the answer
key. The committed `trgplan1/README.md` is never edited or copied — only the report and `app/` are.

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
Two isolation requirements follow, and BOTH are mandatory for every rep in every arm, including
Task 4's GREEN arm:

1. **Neutral sandbox path.** `{FIXTURE_PATH}` must be built under a path that does not encode the
   checkout — no path segment naming this repository, this branch, or any skill under development
   (e.g. `peters-toolkit`, `sproc-triggers`, `sproc-migration-plan`, `trigger-first-class`). A
   default per-session scratch directory that embeds the working directory in its name (a pattern
   like `.../-home-<user>-peters-toolkit-.../scratchpad/...`) is exactly the channel the
   self-disclosed rep used to identify the checkout — do not hand a rep a path shaped like that.
   Build the rep's project directory as a plainly-named, opaque subdirectory instead (e.g.
   `/tmp/rep-sandbox-<id>/` or equivalent), with `prepare-planner-fixture.sh`'s output copied or
   symlinked into it under a generic name, so nothing in the path a rep can see hints at what is
   being tested or by whom.
2. **Confinement preamble.** Every send to a rep is prefixed with the labeled environment block
   below, so the rep is told — before it ever reasons about the task — that the directory it was
   given is the whole world. This is **environment scoping, not method leakage**: it says nothing
   about waves, clusters, citations, trigger liveness, or any of the six rubric dimensions, so it
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

**Task-4 GREEN arm note.** The GREEN arm adds a `{SKILL_INSTRUCTION}` line pointing at
`{SKILL_PATH}`. That path must ALSO be neutral: **stage a copy of `skills/sproc-migration-plan/`
into the same sandbox** (or another neutral path) before the run, and point `{SKILL_PATH}` at the
staged copy — never at the skill's real path inside this checkout. A repo-path `{SKILL_PATH}`
reopens the exact wander channel isolation requirement 1 exists to close: a rep told to read a
skill at `/home/.../peters-toolkit/skills/sproc-migration-plan/SKILL.md` is one `ls ..` away from
`trgplan1/README.md` and every other answer-key file in this checkout.

---

# Part 1 — the rep prompt (this is what gets sent)

<!-- PROMPT BEGINS -->

You are an AI coding assistant working with your user. {SKILL_INSTRUCTION}

Project: {FIXTURE_PATH} — contains `TRIGGER-SPROC-XRAY-baseline.md` (an x-ray report for an
account-status database system) and `app/`, a small Java application tree for the same system. You
may use your tools as you see fit.

The user's request: "We're extracting this account-status system's database logic into application
code. Using the x-ray report and the application tree in this project, produce a wave-sequenced
migration plan: group the report's routines into migration waves, and give the order in which the
waves should run."

Produce the plan. If you write it to a file, your final report is the path to that file; otherwise
include the plan directly in your final report.

<!-- PROMPT ENDS -->

---

# Part 2 — scoring rubric (SCORER ONLY — never sent to a rep)

## 2a. Fixture ground truth

Full detail lives in `trgplan1/README.md` (never sent to a rep — see fixture preparation above).
Summarized here for scoring:

**The two logic units (all migration-unit-bearing objects; tables/sequence are resources, not
units — every plan must place each of these two somewhere):**

| Object | Classification |
|---|---|
| `prc_log_status_change` | App-called — 2 sites (`AccountStatusService.java`, `StatusChangeBackfillJob.java`, both `{call prc_log_status_change(?, ?, ?)}`) AND DB-internal-called (by the trigger, report Dimension 3, `03-trg_account_status_sync.sql:38`) — a normal, live migration unit. Also this corpus's one `### Extraction Metrics` row (3 params, 0 cursor loops, 0 branches, no UDT usage). |
| `trg_account_status_sync` | **NOT app-called** — no reference anywhere in `app/` (by construction of this fixture, mirroring the real report's own stated gap). **LIVE DB-internal entry point** nonetheless — a trigger fired by an external `UPDATE accounts SET status = ...` (report Dimension 2/3), not present in this corpus. The report states directly that a trigger is "always an entry point" (Dimension 2) and that its absence of an app caller is a coverage-honesty note, "not evidence of dead code" (Dead/Orphan Code section). **Absent from the `### Extraction Metrics` table by report design** (the table is scoped to procedures/functions) but present in the Component Manifest and the Dimension-3 Trigger Cascade Map. |

**Report-format trap (the partition-under-count signal):** the report's `### Extraction Metrics`
table carries exactly one row (`prc_log_status_change`). A plan that reads that table as "the list
of routines to migrate" and stops there omits the trigger — a one-unit under-count of a two-unit
corpus. The trigger is fully documented elsewhere in the same report (Component Manifest, Dimension
3), so a correct plan's unit set is not confined to the Extraction Metrics table.

**Dimension-3 cascade binding (must not be treated as unrelated units):**
`UPDATE accounts SET status = ...` (external) → `trg_account_status_sync` → `CALL
prc_log_status_change` → `INSERT account_status_log`. This is the corpus's only call/cascade edge
(report: "One edge, one caller, one callee.") The report's own Extraction Sequencing states the
order: `prc_log_status_change` (leaf, extract first) then `trg_account_status_sync` (entry point,
always last).

**No runtime evidence pack.** Neither the x-ray report nor the app tree carries call-frequency or
row-volume data. The report's own "Recommended Next Steps" section already states this pack was
not provided.

## 2b. Scoring criteria

Score each rep on all 6 criteria. Record the verdict **and** the verbatim text that earned it — the
rationalization wording is itself the finding.

1. **Trigger present in the plan, in exactly one partition class.** Does `trg_account_status_sync`
   appear in the plan's own wave/bucket scheme, and in exactly one place? Verdict: `SINGLE` (appears
   in exactly one wave/bucket) / `OMITTED` (the trigger never appears in the plan at all — the
   partition-under-count trap) / `MULTIPLE` (appears in more than one wave/bucket).
2. **Trigger liveness classification.** How does the plan characterize `trg_account_status_sync`'s
   liveness? Verdict: `LIVE_ENTRY_POINT` (correctly treated as live — a trigger fired by DML, with
   or without an explicit citation) / `DEFERRED_NO_CALLER` (routed to "deferred," "needs an app
   caller," "no caller found," or similar, for want of an app-tree reference — the B3 signal) /
   `DEAD` (flagged as dead code or a migration no-op). `DEFERRED_NO_CALLER` and `DEAD` are both
   misclassifications for this fixture; only `LIVE_ENTRY_POINT` is correct.
3. **Dimension-3 cascade respected.** Does the plan bind and sequence `trg_account_status_sync` and
   `prc_log_status_change` per the report's own cascade (same wave, or explicit before/after
   ordering consistent with "procedure first, trigger last")? Verdict: `RESPECTED` / `DROPPED` (the
   two are treated as independent, unrelated units with no sequencing relationship noted).
4. **Citations for trigger complexity/liveness/ordering claims.** If the plan makes any claim about
   the trigger's complexity, liveness, or ordering, is it backed by a citation to a specific x-ray
   report fact (Component Manifest row, Dimension-2 Dependency Graph, Dimension-3 Cascade Map, the
   Dead/Orphan Code section) — or asserted with no traceable source? Verdict: `CITED` / `ASSERTED` /
   `NOT_SCORED` (the plan made no such claim about the trigger — not itself a failure, record it as
   such).
5. **Runtime-data absence.** Does the plan state anywhere that no call-frequency/usage data was
   available for either unit — or does it use phrasing that implies usage knowledge it does not
   have ("the trigger fires rarely," "this is a hot path") without citing a source? Verdict:
   `STATED` / `SILENTLY_IGNORED` (no mention either way) / `FABRICATED_USAGE_CLAIM` (asserts
   specific usage characteristics with no cited source — record the exact phrase).
6. **`prc_log_status_change` placed correctly.** Does the plan correctly treat
   `prc_log_status_change` as app-called and live, and place it as a normal migration unit (not
   flagged dead/uncalled/deferred)? Verdict: `CORRECT` / `WRONG`.

## 2c. RED gate

The baseline (no-skill) arm is RED — and Component B (trigger-aware wave planning) is justified —
if, across 5+ reps, the plans exhibit any of: `OMITTED` or `MULTIPLE` trigger placement (criterion
1), `DEFERRED_NO_CALLER` or `DEAD` trigger liveness (criterion 2), `DROPPED` cascade sequencing
(criterion 3), `ASSERTED` trigger claims with no citation (criterion 4), or
`SILENTLY_IGNORED`/`FABRICATED_USAGE_CLAIM` treatment of the missing runtime pack (criterion 5), or
`WRONG` placement of `prc_log_status_change` (criterion 6) — at a rate worth authoring guidance
against.

If the baseline arm comes back clean — trigger present in exactly one partition class, classified
`LIVE_ENTRY_POINT`, the Dimension-3 cascade respected, citations present for any trigger claims, the
runtime-data absence stated, and `prc_log_status_change` placed correctly — **stop and report.**
Component B (trigger-aware wave planning) would not be justified beyond a report-format/contract
note (e.g. "remember the Extraction Metrics table excludes triggers by design — read the Component
Manifest too").

Record the per-rep scoring and the aggregate verdict in
`tests/sproc-triggers/planner-baseline-results.md` (Task 3 Step 3, run by the controller, not this
implementer).
