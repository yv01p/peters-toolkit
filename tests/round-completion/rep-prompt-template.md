# Round-completion paired-arm rep prompts

Adapted from `tests/evidence-slot/rep-prompt-template.md`. One fresh-context
subagent per rep, dispatched with tool access (Read/Grep/Bash, read-only,
scoped to the named paths); its final report is scored manually against the
per-fixture rubric below (spec `888l#96`, brief `task-2-brief.md` Step 4).

`{SKILL_PATH}` — baseline arm = `git show v2.5.0:skills/<skill>/SKILL.md`
(the pre-Task-3/4/5 text — no population closure, no `Propagation:` slot, no
amendment anchoring, no slot-grammar audit); for CDR/CIR reviewer reps, also
`git show v2.5.0:skills/critical-design-review/shared-review-discipline.md`
(the shared file both reviewers must read first). GREEN arm = the
working-tree amended file(s) at `skills/<skill>/SKILL.md` (and
`skills/critical-design-review/shared-review-discipline.md` for reviewers),
post the Task 3/4/5 commits.

Rep-integrity notes (apply to every rep, both arms):
- Instruct the rep to stay within the fixture directory and the named skill
  file(s) — no repo-wide exploration.
- Recover each rep's final answer verbatim before scoring; if a live
  notification is ambiguous, ask the rep to restate its final answer
  verbatim rather than scoring from a partial read.
- Fixture docstrings and prose state facts neutrally — never hint at what's
  present/absent or planted. A fixture that editorializes about its own
  defects invalidates the arm.

---

## popclosure (`critical-design-review` — reviewer path)

- SKILL_NAME: `critical-design-review`
- FIXTURE_PATH: `tests/round-completion/popclosure`
- SPEC_PATH: `tests/round-completion/popclosure/design-spec.md`
- Baseline SKILL_PATH: output of `git show v2.5.0:skills/critical-design-review/SKILL.md`
- Baseline SHARED_PATH: output of `git show v2.5.0:skills/critical-design-review/shared-review-discipline.md`
- GREEN SKILL_PATH: `skills/critical-design-review/SKILL.md` (working tree)
- GREEN SHARED_PATH: `skills/critical-design-review/shared-review-discipline.md` (working tree)

### Prompt sent to each rep

```
You are an AI coding assistant executing the `critical-design-review` skill
with your user. FIRST, read the skill's full definition at {SKILL_PATH}, and
read the shared review discipline file at {SHARED_PATH} (per the skill's own
"Shared discipline (read first)" instruction) — both govern your behavior
for this task.

You are reviewing the design spec at {SPEC_PATH}. Its "§0 sweep so far"
section (a coverage-enumeration sweep against §2.3's four record types) is
already complete and given verbatim inside the spec itself — treat those
rows as already produced; do not redo them. You are now continuing the §0
coverage-enumeration sweep for the rest of the spec, exactly as {SKILL_PATH}
directs — including whatever it says about a recurrence/family sweep once a
finding is confirmed. Any source file the spec cites lives under
{FIXTURE_PATH}/src/ — read it with your tools as you see fit, but stay
within {FIXTURE_PATH}; do not explore the rest of the repository.

Produce: (a) the remaining §0 rows needed to complete this round's coverage
enumeration, in the shape {SKILL_PATH} specifies, and (b) any resulting §2
findings. Your final report must be ONLY that — the completed §0 rows plus
any §2 findings. Do not produce §1/§3/§4/§5 or the terminal summary; stop
once the enumeration and its findings are written.
```

### Scoring rubric

- **CAUGHT** — the produced §0 rows enumerate the full matrix and surface
  BOTH planted cells: `WalletHandler` (in `HANDLER_ROSTER`, §4.1) failing to
  clamp, and `c_writeoff_amt` (in `LedgerValidator`, §5.2) failing to clamp
  in the manual-override sign-off path.
- **MISSED** — the rep stops at the 2 findable instances already given
  (`Refund`, `Adjustment`), or extends only partially (finds one planted
  cell but not the other, or asserts §4.1/§5.2 are "out of scope"/"not
  part of this round" without producing rows for them).

---

## propagation (`update-implementation-plan` — applier path)

- SKILL_NAME: `update-implementation-plan`
- FIXTURE_PATH: `tests/round-completion/propagation`
- PLAN_PATH: `tests/round-completion/propagation/impl-plan.md`
- REVIEW_PATH: `tests/round-completion/propagation/review.md`
- Baseline SKILL_PATH: output of `git show v2.5.0:skills/update-implementation-plan/SKILL.md`
- GREEN SKILL_PATH: `skills/update-implementation-plan/SKILL.md` (working tree)

### Prompt sent to each rep

```
You are an AI coding assistant executing the `update-implementation-plan`
skill with your user. FIRST, read the skill's full definition at
{SKILL_PATH} — it governs your behavior for this task.

You are mid-way through the skill's process. Earlier steps are already
done: the review at {REVIEW_PATH} was read and accepted (it carries the
required `**Plan:**` header and a `## 2. Literal-wrongness findings`
section), its finding was extracted, the plan at {PLAN_PATH} was read once,
and there is no forced-decisions gate to resolve (this review has no §3
items). You are now at the process step that processes remaining findings —
the review's single §2 finding. Quote the applicable step's fix-proposal
shape from whichever skill version {SKILL_PATH} points at, and follow it
exactly, including whatever it says about propagating the fix's dependent
mentions through the plan artifact.

Fixture: {FIXTURE_PATH} (read the plan and the review file; read any source
file the finding or your drafted fix cites, using your tools as you see
fit, but stay within {FIXTURE_PATH} — do not explore the rest of the
repository).

Now produce the exact message you would send to the user for this §2
finding — the Finding / Fix / Evidence / Propagation / Gate proposal (or,
if {SKILL_PATH} points at a skill version with no `Propagation:` slot,
whatever proposal shape THAT version actually specifies — reproduce its
shape, not a newer one). Your final report must be ONLY that message,
verbatim. Do not perform the "on approve" tracking step or any step after
it — stop at producing and returning the proposal message; the user has not
yet responded to the gate.
```

### Scoring rubric

- **CAUGHT** — the produced proposal (its `Propagation:` line, or
  equivalent proposal text in the baseline arm, which has no such line)
  disposes BOTH planted sites: Task 4's paraphrase ("numeric grade
  alongside a bucket label" — the same score/tier rule in other words, no
  shared key terms with `score`/`tier`/`reason_code`/`rank_candidate`) AND
  Task 6's embedded `_stub_result()` code block (`impl-plan.md`, returns the
  OLD 2-tuple shape `(0.82, "gold")` — embedded directly in the plan
  artifact's own text, since `update-implementation-plan` modifies the plan
  only; `src/test_dashboard.py` is background realism, not the scored site).
  Each site gets an explicit `edited` / `unaffected — <why>` disposition, or
  is otherwise named as needing a consistent update.
- **MISSED** — either site is absent from the proposal (not named, not
  dispositioned) — most likely under the baseline arm's grep-only Propagate
  bullet, which has no vocabulary in common with either planted site.

  **Fixture history:** the fixture originally (Task 2) planted the
  shape-bound site only in `src/test_dashboard.py`, a file cited by but
  external to the plan artifact. Task 6's first paired-arm run showed 0/5
  CAUGHT on both the GREEN and RED arms against that version — every rep
  read "artifact site" as scoped to the plan document's own text and never
  dispositioned the externally-cited file, even when they opened and read
  it. The controller ruled this a fixture defect (contradicts the plan's
  own required design: "the artifact holding one paraphrased restatement +
  one shape-bound site") and directed embedding the mock in the plan text
  itself (Task 6 of `impl-plan.md`), fixed in the "fix round" commit. See
  `green-results.md` and `baseline-results.md` for both the original
  (defective-fixture) and corrected-fixture results, both kept.

---

## auditor (`critical-design-review` / `critical-implementation-review` — slot-grammar audit path)

- FIXTURE_PATH: `tests/round-completion/auditor`
- REVIEW_PATH: `tests/round-completion/auditor/review.md`
- Baseline SKILL_PATH: N/A at this stage — `git show v2.5.0:` CDR/CIR carry
  no "Slot-grammar audit" section at all (it is new in Task 4), so there is
  no baseline arm to run against this fixture yet. Per `task-2-brief.md`
  Step 6, this fixture is built now but not rep-tested until Task 6, once
  the audit step exists in the (post-edit) skill text.
- GREEN SKILL_PATH: `skills/critical-design-review/SKILL.md` (working tree,
  post Task 4 — the "Slot-grammar audit" section is identical in CIR).

### Prompt to send each rep (Task 6)

```
You are the fresh-context slot-grammar audit agent described in
{SKILL_PATH}'s "Slot-grammar audit" section. Your only input is the review
file at {REVIEW_PATH} — no codebase access, no other files.

Read {SKILL_PATH}'s "Slot-grammar audit" section for the exact checklist,
then apply it to {REVIEW_PATH}:
- every confirmed rule-vs-population mismatch has its matrix fully
  dispositioned (population closure);
- every load-bearing `ok` and every `Evidence:` line opens with a class tag
  whose shown evidence matches that class's tier;
- every rule-like row shows both failure directions;
- no `UNVERIFIED` row is dropped from §3 flow;
- the anchor header is present in one of its two forms.

Report PASS or FAIL per checklist item, citing the specific row/line for
any FAIL. Your final report must be ONLY that checklist verdict.
```

### Scoring rubric

- **CAUGHT** — the audit flags BOTH planted violations: the undispositioned
  `CacheMiddleware` cell in the §3.1 middleware-roster matrix (population
  closure incomplete), and item 4's untagged load-bearing `ok` rows (all
  three §4.2 override-validator per-constraint dispositions — `c_blocklist_check`,
  `c_rate_check`, `c_ip_check` — have no leading class tag; one defect
  class, three cells).
- **MISSED** — either violation survives the audit as a PASS, or the audit
  additionally flags something that is NOT one of these two planted
  defects (the fixture is otherwise valid — an audit that flags anything
  else is scored against the fixture, not the audit).

  **Fixture history:** item 4 originally (Task 2) gave the §4.2 validator's
  3 named constraints a single aggregate over/under pair rather than a
  disposition per constituent, unlike every other multi-member population
  in the fixture (§2's 4 endpoint handlers, §3.1's 5-member middleware
  roster). 1 of 3 reps in Task 6's first run flagged this as a genuine
  population-closure gap under the shared file's own "disposition per cell"
  text — a real fixture defect per the controller's ruling, not audit
  over-reach. Fixed in the "fix round" commit: item 4 now gives each of the
  3 constraints its own over/under bullet, still with no class tag (the
  missing tag remains the sole planted defect there).
