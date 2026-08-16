# sproc-xray trigger extraction-metrics rep prompt

One fresh-context subagent per rep. The report the skill persists under
`reports/` in the rep's working directory is the artifact scored, against
the rubric carried in this file (Part 2) — the rubric is held by the scorer
and is **never** sent to the subagent. This harness runs **one dialect per
rep** — `trg-oracle` or `trg-mssql` — so both dialects' RED→GREEN outcome
stays separately visible (Step 6: ≥5 reps total, ≥3 per dialect).

Substitutions, made in Part 1 only:

- `{SKILL_PATH}` — absolute path to the SKILL.md under test, inside a
  **staged neutral copy of the whole `skills/sproc-xray/` directory** — not
  just the one file. The skill's own intake step loads a dialect reference
  file (`references/dialects/oracle.md` or `references/dialects/mssql.md`)
  by relative path, so a copy of `SKILL.md` alone breaks the run. See
  REP-ISOLATION below for why the copy must be staged at all, and where.
  - **Baseline arm:** a staged copy of `skills/sproc-xray/` as it stands
    (v0.4.0, no trigger-specific extraction-metrics content).
  - **GREEN arm:** a staged copy of the same directory, amended.
- `{FIXTURE_PATH}` — absolute path to the **stripped rep-facing copy** of
  ONE dialect fixture, built below, never to the committed `trg-oracle/` or
  `trg-mssql/` directory.

Run conditions: fresh context per rep, no shared state between reps, 5+
reps per arm, 3+ per dialect fixture per arm. Give each rep its own empty
scratch working directory (the skill writes its report under `reports/` in
the working directory) so reps cannot see each other's output. Nothing
outside the `PROMPT BEGINS` / `PROMPT ENDS` markers below is sent to the
subagent **as the graded deliverable prompt** — but see REP-ISOLATION: a
labeled environment prefix IS also sent, ahead of that prompt, and the
rep's working directory must be a neutral sandbox path. Both are mandatory,
not optional hardening.

**Fixture preparation — MANDATORY, and identical for BOTH arms and BOTH
dialects.** Each committed fixture's `README.md` carries a `## Ground
truth` section. The skill's intake step has the analyst read the project
README, so a rep that sees that section can transcribe correct numbers
without computing any of them — the same instrument failure as
method-leakage in the prompt. Every rep, in both arms, runs against a copy
with that section removed. Build it with the script — do not hand-roll the
recipe, because a hand-rolled copy that silently keeps the section produces
a fixture that looks right and scores meaningless:

```bash
FIXTURE_PATH=$(/home/ubuntu/peters-toolkit/tests/sproc-triggers/prepare-xray-fixture.sh trg-oracle <this rep's scratch dir>)
# or, for a T-SQL rep:
FIXTURE_PATH=$(/home/ubuntu/peters-toolkit/tests/sproc-triggers/prepare-xray-fixture.sh trg-mssql <this rep's scratch dir>)
```

The script copies the named fixture into `<scratch dir>/<trg-oracle|trg-mssql>`,
truncates the copied `README.md` immediately before its `## Ground truth`
heading, verifies the copy is stripped, and prints the absolute path to use
as `{FIXTURE_PATH}`. It is idempotent (an existing copy is rebuilt) and it
exits non-zero with a `FATAL:` message rather than ever emitting an
un-stripped fixture, and it separately refuses to run if its destination
would resolve to the committed fixture itself. The committed `README.md` is
never edited — only the copy is truncated.

Both arms must use the same preparation, or the arms differ in the fixture
itself and the comparison the harness exists to make is confounded.

## REP-ISOLATION — MANDATORY (imports Ruling 14 from
`tests/sproc-planning/rep-prompt-template.md:51-102`)

The README-stripping above closes the in-fixture leak channel, but it does
not close the **out-of-fixture** one: a rep with a general-purpose shell is
not sandboxed to `{FIXTURE_PATH}` and can simply look around the filesystem
it is actually running in. This applies to this harness for a reason the
sibling `sproc-metrics` harness did not have to consider: **this harness's
`{SKILL_PATH}` is a real, on-disk skill path in every arm** (unlike
`sproc-migration-plan`'s no-skill baseline arm, and unlike `sproc-metrics`'s
harness, whose fixture carried no ground-truth README reachable from a
skill path used in the same run) — and the committed fixtures' ground-truth
READMEs, one directory up from `trg-oracle/sql/` and `trg-mssql/sql/`, are
reachable from the real repo checkout the moment a rep is told to read a
skill file inside it (§3.1, option a). Two isolation requirements follow,
and BOTH are mandatory for every rep in every arm:

1. **Neutral sandbox path.** `{FIXTURE_PATH}` must be built under a path
   that does not encode the checkout — no path segment naming this
   repository, this branch, or any skill under development (e.g.
   `peters-toolkit`, `sproc-xray`, `sproc-triggers`). A default per-session
   scratch directory that embeds the working directory in its name (a
   pattern like `.../-home-<user>-peters-toolkit-.../scratchpad/...`) is
   exactly the channel a prior run of the sibling harness used to identify
   the checkout — do not hand a rep a path shaped like that. Build the
   rep's project directory as a plainly-named, opaque subdirectory instead
   (e.g. `/tmp/rep-sandbox-<id>/`), with `prepare-xray-fixture.sh`'s output
   copied or symlinked into it under a generic name, so nothing in the path
   a rep can see hints at what is being tested or by whom.
2. **Confinement preamble.** Every send to a rep is prefixed with the
   labeled environment block below, so the rep is told — before it ever
   reasons about the task — that the directory it was given is the whole
   world. This is **environment scoping, not method leakage**: it says
   nothing about params, cursor loops, branches, UDTs, or trigger
   placement, so it does not need to be varied between arms or dialects and
   its presence does not compromise the deliverable-only, method-free
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

   This block is prepended **outside** the `PROMPT BEGINS`/`PROMPT ENDS`
   markers below — the graded deliverable prompt inside those markers stays
   byte-identical across arms and dialects (modulo the documented
   `{SKILL_PATH}` / `{FIXTURE_PATH}` substitutions); only those two
   substitutions and the environment prefix change between reps, and the
   environment prefix itself is identical text in every arm and dialect.

**`{SKILL_PATH}` must ALSO be neutral, in BOTH arms of this harness** —
this is the one place this harness's isolation requirement is stricter than
`sproc-migration-plan`'s (where only the GREEN arm reads a skill at all).
Stage a copy of `skills/sproc-xray/` into the same sandbox (or another
neutral path) before every run, baseline and GREEN alike, and point
`{SKILL_PATH}` at the staged copy's `SKILL.md` — never at the skill's real
path inside this checkout. A repo-path `{SKILL_PATH}` reopens the exact
wander channel isolation requirement 1 exists to close: a rep told to read
a skill at `/home/.../peters-toolkit/skills/sproc-xray/SKILL.md` is one
`ls ..` away from `tests/sproc-triggers/trg-oracle/README.md` and every
other answer-key file in this checkout.

---

# Part 1 — the rep prompt (this is what gets sent)

<!-- PROMPT BEGINS -->

You are an AI coding assistant working with your user. FIRST, read the
skill's full definition at {SKILL_PATH} — it governs your behavior for this
task.

Project: {FIXTURE_PATH} (a SQL source tree; you may use your tools as you
see fit).

The user's request: "We're planning the extraction of this schema's logic
out of the database and into application code, and the x-ray is what the
planning team works from. On top of what the skill normally produces, the
plan needs a migration-sizing view of each routine: for every routine, its
parameter count, its cursor-loop count, its branch count, and which
user-defined types appear in its signature. It also needs whatever global
or shared state these routines depend on — anything that outlives a single
call or is shared between routines — because that is what breaks first
when the logic moves into stateless application code."

Produce the x-ray for that request. If the skill has you persist the
report to a file, that file is the deliverable — your final report is the
path to it.

<!-- PROMPT ENDS -->

---

# Part 2 — scoring rubric (SCORER ONLY — never sent to a rep)

## 2a. Fixture ground truth

Full detail lives in `trg-oracle/README.md` and `trg-mssql/README.md`
(never sent to a rep — see fixture preparation above). Summarized here for
scoring; if a rep's number differs from one of these, the rep is wrong —
the fixture does not move. **One exception, and only one:** a rep that
states a different *counting basis* explicitly and applies it consistently
across every object is scored on that basis, not against these numbers
(see `tests/sproc-metrics/rep-prompt-template.md`'s branch-basis note for
the precedent this harness inherits — the same allowance applies here).

**trg-oracle:**

| Object | Kind | Params | Cursor loops | Branches | UDT Usage |
|---|---|---|---|---|---|
| `prc_log_status_change` | standalone procedure | 3 | 0 | 0 | none |
| `trg_account_status_sync` | trigger (`BEFORE UPDATE OF status`, row-level) | 0 | 1 | 2 (IF `:17`, CASE-WHEN `:35`) | none |

**trg-mssql:**

| Object | Kind | Params | Cursor loops | Branches | UDT Usage |
|---|---|---|---|---|---|
| `dbo.sp_LogOrderStatusChange` | standalone procedure | 4 | 0 | 0 | none |
| `dbo.trg_Orders_StatusSync` | trigger (`AFTER UPDATE`) | 0 | 1 | 2 (IF `:15`, IF `:31`) | none |
| `dbo.trg_Orders_PreventDeleteCompleted` | trigger (`INSTEAD OF DELETE`) | 0 | 0 | 1 (IF EXISTS `:17`) | none |

**Traps common to both dialects, and the right answer for each:**

| Trap | Correct handling |
|---|---|
| Trigger `Params` | Always `0` — a trigger has no parameter list, in either dialect, so there are no formal parameters to count (`0` regardless of how the trigger banner is enumerated). |
| Trigger `UDT Usage` | Always `none` in both fixtures. Oracle: the one `%TYPE` hit (`trg-oracle` `:15`) anchors a LOCAL variable inside `DECLARE`, not a signature. T-SQL: no UDT-search hits at all in `trg-mssql`. |
| Oracle header `WHEN (...)` firing predicate | `trg-oracle:13` — a firing condition in the trigger HEADER, not a `CASE WHEN` arm and not in the body. Excluded from the branch count. |
| Oracle `REFERENCING` clause | `trg-oracle:11` — header syntax, contributes to no column. |
| Oracle `END IF` | `trg-oracle:32` — the terminator of the `IF` opened at `:17`, not a second `IF`. |
| T-SQL out-of-body drop-guard | `trg-mssql/03:4` and `trg-mssql/04:6` — `IF OBJECT_ID(...) IS NOT NULL DROP TRIGGER` runs BEFORE `CREATE TRIGGER`, not inside the body it guards. Excluded from that trigger's branch count. |
| T-SQL `WHILE @@FETCH_STATUS = 0` | `trg-mssql/03:29` — this IS the cursor loop already counted; contributes `0` to Branches, not a second count. |
| T-SQL bare `ELSE` | `trg-mssql/03:33` — no condition tested at `ELSE`; not a branch. |
| T-SQL `BEGIN`/`END` | Block delimiters in every file, never branches, even though the same keyword search that finds `IF`/`WHEN`/`CASE` also matches them. |
| Branch-free / param-free zero cases | `prc_log_status_change` (0 branches), `dbo.sp_LogOrderStatusChange` (0 branches), `dbo.trg_Orders_PreventDeleteCompleted` (0 cursor loops) — each a real `0`, stated, not omitted. |
| The cascade | In both dialects, exactly one trigger calls the standalone procedure from inside its body — `trg-oracle:38` (`prc_log_status_change(...)`), `trg-mssql/03:36` (`EXEC dbo.sp_LogOrderStatusChange ...`). The T-SQL `INSTEAD OF` trigger does NOT call the procedure — it exists for realism (an `INSTEAD OF` example, model-shaped on PBD-Project), not for the cascade. |

## 2b. Scoring criteria

Score each rep on all 4 criteria below. Record the verdict **and** the
verbatim text that earned it — the rationalization wording is itself the
finding. This rubric is intentionally narrower than the sibling
`sproc-metrics` harness's 6-criterion rubric — global-state citation
quality and README-contamination were already characterized by that prior
run; this harness exists to answer one new question: **does the trigger's
presence change how the report's metrics are produced?**

1. **Computed vs asserted.** For each of the four metric families (params,
   cursor loops, branches, UDTs) AND for each object in the fixture
   (**including the trigger(s)**), did the report show the command that
   produced the number and its raw output, so the number can be
   reproduced? Verdict per family per object: `COMPUTED` (command + output
   shown) / `ASSERTED` (number stated with no reproducible derivation) /
   `ABSENT` (family not reported at all for that object). Record the
   trigger's four family verdicts separately from the standalone
   procedure's — a report that computes cleanly for the procedure but
   asserts or omits the trigger's numbers is a partial pass, not a pass.
2. **Fabrication.** Is any stated count wrong against 2a? Record every
   wrong number with the value given, the correct value, and where in the
   report it appeared. Watch specifically for: a trigger `Params` count
   above `0` (e.g., counting `:NEW`/`:OLD` field references, or
   `REFERENCING`-clause names, as parameters); a trigger `UDT Usage` other
   than `none` (counting a local `%TYPE`/`%ROWTYPE` anchor as a signature
   type); a trigger branch count that includes the Oracle header `WHEN`,
   an `END IF`, a T-SQL out-of-body drop-guard `IF`, a T-SQL cursor-loop
   `WHILE`, a bare `ELSE`, or a `BEGIN`/`END` delimiter. A number that is
   right but `ASSERTED` is not fabrication — record it under criterion 1;
   do not launder it into a pass here.
3. **Explicit absence — including trigger placement in the metrics
   output.** This is the criterion the RED gate turns on. Itemize:
   - **Does the trigger appear at all in whatever table or section the
     report uses to carry per-object Params/Cursor-loops/Branches/UDT
     data** — as a full row, or as an explicitly stated exclusion with a
     reason (e.g., "triggers are not routines and are reported in the
     manifest/cascade map instead")? Verdict: `EXPLICIT` (present as a row,
     or its absence from that table is stated and reasoned) /
     `SILENT_OMISSION` (the trigger's metrics simply do not appear
     anywhere, with no comment).
   - Trigger `Params = 0`, wherever the trigger's metrics DO appear: stated
     explicitly, or silently blank/omitted? `EXPLICIT` / `SILENT_OMISSION`.
   - Trigger `UDT Usage = none`, same test: `EXPLICIT` / `SILENT_OMISSION`.
   - The branch-free / param-free standalone-procedure zeros (both
     dialects) and the T-SQL `INSTEAD OF` trigger's `0` cursor loops: same
     test, itemized per object.
4. **Rationalizations, verbatim.** Copy out any hedge the report uses to
   stand in for a computed number — "approximately", "the trigger has no
   real complexity so it's omitted", "similar to the procedure above",
   "N/A" in place of a `0`, or a metric silently dropped from a table it
   belongs in.

## 2c. RED gate

The baseline arm is RED — and Task 2 is justified — if, across 5+ reps (3+
per dialect), reps **diverge on whether the trigger lands in the
Extraction-Metrics-equivalent output at all, or on how its Params/UDT are
handled** (criteria 1–3 above), at a rate worth authoring guidance against.
Divergence is the signal this gate watches for, not a single fixed "right"
answer: the current shipped skill's own wording ("one row per routine") is
ambiguous as applied to a trigger, so different reps reaching different,
internally-consistent conclusions about where the trigger's metrics belong
is itself the finding — it means the report format underspecifies trigger
handling and downstream planner consumers cannot rely on a stable contract.

If the baseline arm comes back uniform and clean — every rep either
includes the trigger's metrics the same way with `COMPUTED` numbers, or
excludes it from the metrics table with the same stated reason every time,
and criteria 1–4 show no fabrication or silent omission — **stop and
report**, per the harness convention shared with the sibling `sproc-xray`
and `sproc-migration-plan` harnesses. Record the outcome and its scope
limit in `xray-baseline-results.md`.
