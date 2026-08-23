# Round-completion paired-arm harness — GREEN results (Task 6)

Task 6 of the `888l#96` round-completion-implementation-plan. Wires the
deterministic guard into `tests/run-tests.sh`, runs the GREEN arm (working
tree, post Tasks 3–5) for all three fixtures, completes the RED arms to
matching n per the controller's carry-forward rulings, and records
everything here plus the RED top-up in `baseline-results.md`.

Rep dispatch throughout: fresh-context `general-purpose` subagents
(model: sonnet), scoped exactly per `rep-prompt-template.md` (popclosure /
propagation) and per the controller's auditor-arm instructions (ruling 2,
task brief). Each rep's final answer was recovered verbatim from its
completion notification; nothing summarized or paraphrased before scoring.

---

## 1. Guard against the working tree (Step 1)

Command: `bash tests/round-completion/check-round-completion.sh`

Exit code: **0** (pass — expected/GREEN).

```
-- assertion 1: shared file carries the Population closure section --
-- assertion 2: CDR + CIR reference population closure, enclosing-surface bound gone --
-- assertion 3: shared file carries per-direction grammar + class-tag vocabulary --
-- assertion 4: UDD + UIP carry the Propagation: slot + three-sweep enumeration --
-- assertion 5: CDR + CIR carry the amendment-hunk clause + both anchor forms --
-- assertion 6: CDR + CIR carry the fresh-context dispatch note + slot-grammar audit step --
round-completion OK (population closure, slot grammar, propagation, amendment anchoring, slot-grammar audit all present)
```

**No literal mismatch.** All 6 assertion classes, every sub-literal, matched
the working tree cleanly on the first run — Tasks 3–5's landed wording is
byte-consistent with what the guard (written in Task 2, before Tasks 3–5
existed) expects. No edit to `check-round-completion.sh` was needed or made.

---

## 2. Wiring into `run-tests.sh` (Step 2)

Added, verbatim per the brief, immediately after the `evidence-slot` line:

```bash
echo "== round-completion =="; bash "$ROOT/round-completion/check-round-completion.sh" || fail=1
```

`bash tests/run-tests.sh` output tail:

```
== round-completion ==
-- assertion 1: shared file carries the Population closure section --
-- assertion 2: CDR + CIR reference population closure, enclosing-surface bound gone --
-- assertion 3: shared file carries per-direction grammar + class-tag vocabulary --
-- assertion 4: UDD + UIP carry the Propagation: slot + three-sweep enumeration --
-- assertion 5: CDR + CIR carry the amendment-hunk clause + both anchor forms --
-- assertion 6: CDR + CIR carry the fresh-context dispatch note + slot-grammar audit step --
round-completion OK (population closure, slot grammar, propagation, amendment anchoring, slot-grammar audit all present)
== sproc-xray-scratch ==
sproc-xray scratch-isolation OK
== sproc-xray-loc-contract ==
sproc-xray/plan LOC-contract OK
== bugfix status ==
...(5 passing)...
== tracker-adapter ==
...(4 passing)...
ALL TESTS PASSED
```

`ALL TESTS PASSED` — confirmed, full run, nothing else regressed.

---

## 3. popclosure — GREEN-arm reps (`critical-design-review`, working tree)

Rubric (`rep-prompt-template.md`): **CAUGHT** = the produced §0 rows
enumerate the full matrix and surface both planted cells (`WalletHandler` in
`HANDLER_ROSTER`; `c_writeoff_amt` in `LedgerValidator`). **MISSED** = the
rep stops at the 2 given findings, or extends only partially.

| Rep | Verdict | Decisive quote |
|---|---|---|
| popclosure-GREEN-rep1 | **CAUGHT** | "`WalletHandler.process`... `[totality]` **FAIL, no `clamp_to_max()` call anywhere in this method → §2.3`**" and "`c_writeoff_amt`... `[totality]` **FAIL, listed in `CONSTRAINTS` (line 17) but the clamping loop above only iterates the other three; this field is assigned raw, uncalled `clamp_to_max` → §2.4`**" — both cells named directly as instances of "the roster a rule iterates over is itself a governed population" / "the constraint set of a validator gating a spec-permitted branch," quoting the shared file's own vocabulary. |
| popclosure-GREEN-rep2 | **CAUGHT** | "**Recurrence/family sweep triggered.** The two confirmed §2.1/§2.2 findings... oblige a recurrence sweep across every other population Rule R governs, per the population-closure discipline" — then per-cell, both directions: `WalletHandler.process`... "under: [absence] **FAIL** — `_persist_to_ledger(amount)`; `amount` never passed through `clamp_to_max()`... → §2.3" and `c_writeoff_amt`... "under: [absence] **FAIL**... → §2.4". Also produced the **over**-direction row for both populations explicitly (`[totality] ok — no non-amount operand is ever routed through clamp_to_max()`), going beyond the minimum bar. |

**Aggregate: 2/2 CAUGHT, 0/2 MISSED.** Both reps independently reach full
matrix closure, quoting the shared file's own "roster iterated over" /
"validator constraint set" population-closure vocabulary by name, and both
attach correct per-direction, class-tagged dispositions. This is the clean
target behavior the amendment was written to produce.

---

## 4. propagation — GREEN-arm reps, DEFECTIVE FIXTURE (`update-implementation-plan`, working tree)

**Status note (added in the fix round, not a retroactive edit):** the
controller ruled the fixture used in this §4 run was itself defective — the
plan's fixture spec required "the artifact holding one paraphrased
restatement + one shape-bound site (a mock helper returning the old
shape)," and the shape-bound site was incorrectly planted in
`src/test_dashboard.py`, a file the plan only *cites*, rather than embedded
in the plan artifact's own text. §4 below is preserved verbatim as the
historical record of what was actually run and found against that
defective fixture — it is real evidence that every rep's Propagation sweep
scoped "artifact site" to the plan document's own text (a defensible,
in fact correct, reading once the fixture is understood to be broken this
way). **§4a below is the corrected-fixture re-run — the authoritative
current propagation GREEN result.**

Rubric: **CAUGHT** = the proposal's `Propagation:` line disposes BOTH
planted sites — Task 4's paraphrase AND `src/test_dashboard.py`'s
`_stub_result()` mock — each with an explicit `edited` / `unaffected — <why>`
disposition or otherwise named as needing a consistent update. **MISSED** =
either site absent, or dismissed on grounds that don't engage with the shape
match.

n was expanded from the brief's minimum of 2 to 5 after rep 1 and rep 2 both
produced a clean, unambiguous MISS on site 2 — a directionally decisive
(not merely noisy) result worth confirming rather than resting on n=2.

| Rep | Verdict | Decisive quote |
|---|---|---|
| propagation-GREEN-rep1 | **MISSED** (site 2 absent) | Propagation section disposes Task 3 (edited), the assumptions row, Tasks 1/2/5, and Task 4 ("unaffected — restates only two of the tuple's fields... doesn't contradict this description"). Mechanism/contract sweep: "`destructures` appears exactly once in `impl-plan.md`, inside Task 3 itself — **no other destructuring or arity-assertion site exists elsewhere in the plan artifact to update.**" `src/test_dashboard.py` is never named anywhere in the Propagation section. |
| propagation-GREEN-rep2 | **MISSED** (site 2 absent) | Mechanism/contract sweep: "the only plan-text site that constructs, returns, or asserts this tuple shape is Task 3 itself... **no other plan-text pseudocode, mock-helper reference, or arity assertion exists in the plan document.**" `src/test_dashboard.py` is never opened or cited anywhere in the answer. |
| propagation-GREEN-rep3 | **MISSED** (site 2 read, not dispositioned) | Evidence section explicitly reads the file: "Read `src/test_dashboard.py:1-16` — the only downstream consumer of `rank_candidate`'s output present in this fixture: `_stub_result()` returns `(0.82, "gold")`..." — but the Propagation list disposes only Task 3, Task 4 (edited), the assumptions row, and Tasks 1/2/5. `src/test_dashboard.py`/`_stub_result()` receives no `edited` or `unaffected` line of its own — read for evidence, never entered as a swept site. |
| propagation-GREEN-rep4 | **MISSED** (site 2 absent) | Propagation list: Task 3 body (edited), Task 4 (edited), assumptions row (unaffected), Task 1/2/5 (unaffected), Overview (unaffected). No Evidence line and no Propagation line ever names `src/test_dashboard.py`. |
| propagation-GREEN-rep5 | **MISSED** (site 2 explicitly excluded) | Mechanism/contract sweep note: "`src/test_dashboard.py`'s `_stub_result()` helper returns a 2-tuple mirroring the old contract, and would need updating in the real codebase — **but that's source code, not plan prose, and this skill modifies the plan only, so it isn't a swept site here.**" — the rep identifies the exact planted defect, correctly recognizes it needs updating, and then rules it out of scope by an artifact/plan-prose-vs-codebase distinction it introduces itself. |

**Aggregate: 0/5 CAUGHT, 5/5 MISSED.**

### Concern — reported honestly, not softened (this is the load-bearing finding of Task 6)

This is a clean, reproducible, non-ambiguous negative result, not sampling
noise: every one of 5 independent fresh-context reps, running the actual
landed `update-implementation-plan` SKILL.md text against the actual fixture
built for this purpose, failed to disposition the second planted site
(`src/test_dashboard.py`'s `_stub_result()` mock) as its own `edited` /
`unaffected — <why>` Propagation entry — even the 3 reps (rep3, and,
functionally, the RED-arm top-up reps below) that opened the file and used
its contents as supporting evidence for editing Task 4's prose never treated
the mock file itself as a swept site. **Per the RED-arm top-up below
(§2 of `baseline-results.md`), the pre-amendment (v2.5.0) text produces the
exact same 5/5 miss on this fixture.** Propagation shows **zero measurable
discrimination** between the pre- and post-Task-5 skill text on this
fixture — the opposite of what Task 6 set out to demonstrate.

**Root-cause diagnosis (found by comparing this fixture to Task 1's
microtest fixture, which validated the identical clause wording at 15/15
HIT):** Task 1's `round3-fixture/propagation/spec.md` is a **design spec**
under `update-design-doc`'s clause, and its planted mock
(`_stub_result()`) lives in a `§7.3 Dashboard tests` section **embedded
directly inside the same spec.md file** being swept — one document, one
read, no boundary to cross. Task 6's actual fixture instead targets
`update-implementation-plan`, and its plan document (`impl-plan.md`) only
**cites** `src/test_dashboard.py` from within Task 4's prose ("see
`src/test_dashboard.py` for its test coverage") — the mock itself lives in
a separate, real source file outside the plan artifact's own text. This is
a materially different, and arguably more realistic, structure than Task
1's microtest ever tested. The landed clause text says "enumerate every
**artifact** site" and gives "mock helpers that return the tuple" as an
example — but every real rep here, with full read access to
`src/test_dashboard.py` and explicit permission to use it, converged
independently on reading "artifact" as scoped to the plan document's own
text, not to codebase files the plan merely cites. Rep5's explicit
rationale ("that's source code, not plan prose... isn't a swept site
here") states this reading outright.

**This is flagged to the controller as a real, unresolved gap**, not
something this task is authorized to fix (no `skills/` edits, no fixture
edits permitted under Task 6's scope) or something to paper over by
re-rolling for a different result: Task 5's landed `Propagation:` /
three-sweep wording, as actually written, does not reliably close the
888l#96 propagation gap when the dependent mention lives in a cited
codebase file rather than inside the artifact text itself — a structure
Task 1's validation never exercised and this fixture's design (built in
Task 2, before this gap was known) happens to hit directly. Whether the
right fix is a further wording amendment (e.g., explicitly naming
"including files the artifact cites" in the mechanism/contract sweep
bullet), a fixture redesign, or accepting this as a known limitation is a
call for the controller, not for this task.

---

## 4a. propagation — GREEN-arm reps, CORRECTED FIXTURE (`update-implementation-plan`, working tree)

**Fixture fix (controller-directed, `impl-plan.md`):** added a new `## Task
6: Dashboard test coverage` to `tests/round-completion/propagation/impl-plan.md`,
embedding the shape-bound mock directly in the plan artifact's own text:

```python
def _stub_result():
    return (0.82, "gold")

def test_dashboard_groups_by_bucket():
    grade, bucket = _stub_result()
    assert bucket == "gold"
```

Shares no literal key terms with the changed contract (`score`, `tier`,
`reason_code`, `rank_candidate`, `2-tuple`/`3-tuple`/`tuple` all absent),
matching Task 4's `grade`/`bucket` paraphrase vocabulary — findable only by
shape, not by sweep-1 grep. Task 4 (the paraphrase site) is untouched, byte
-identical to before. `src/test_dashboard.py` is left in place unedited, as
background realism (per the controller's explicit discretion) — it is no
longer the scored site. **Site 2, for scoring purposes from here on, is
Task 6's embedded code block.**

Same rubric as §4 (site 2 redefined per above), same dispatch method
(fresh-context `general-purpose`/sonnet, scoped to the fixture directory
and the working-tree `update-implementation-plan/SKILL.md`), 5 fresh reps
(not a re-run of the same reps — independent dispatch).

| Rep | Verdict | Decisive quote |
|---|---|---|
| propagation-GREEN-corrected-rep1 | **CAUGHT** | Propagation: "Task 6 (dashboard test stub) — **edited** — `_stub_result()` returns `(0.82, "gold")` and is destructured `grade, bucket = _stub_result()`, a mock helper mirroring `rank_candidate`'s exact return shape 'until the real service integration lands'; left as a 2-tuple it goes stale against the new 3-tuple contract." Task 4: "unaffected — restates score/tier in dashboard-display terms... doesn't assert an exhaustive 2-field contract." |
| propagation-GREEN-corrected-rep2 | **CAUGHT** | Propagation: "Task 6 'Dashboard test coverage' stub (lines 44–53) — **edited.** The stub is explicitly described as standing in for 'the ranking output... until the real service integration lands,' and its code mirrors `rank_candidate`'s exact tuple shape." Task 4: "unaffected — describes the dashboard's UI output (grade + bucket label), not `rank_candidate`'s return-value arity." |
| propagation-GREEN-corrected-rep3 | **CAUGHT** | Propagation: "Task 6 (dashboard test-coverage code block) — **edited.** This is a mock helper that constructs and destructures the exact value contract Task 3 defines (**the case the mechanism/contract sweep calls out by name: 'mock helpers that return the tuple, arity assertions'**)." Explicitly notes `src/ranking.py`/`src/test_dashboard.py` are "out of scope, not edited: this skill modifies the plan only" — correct scoping, and still catches the in-plan site. |
| propagation-GREEN-corrected-rep4 | **CAUGHT** | Propagation: "Task 6 'Dashboard test coverage' stub (lines 44–53) — **edited.** ... **so it gets a consistent tracked edit rather than a skip**." Updated block shown with 3-tuple `_stub_result()` and matching destructure. |
| propagation-GREEN-corrected-rep5 | **CAUGHT** | Propagation: "Task 6, dashboard test-coverage stub... is a mock helper that constructs and destructures a tuple mirroring `rank_candidate`'s old 2-element shape — **edited**, to stay consistent with Task 3's new 3-tuple contract." Diff-style edit shown, both `_stub_result()` and the destructure line updated. |

**Aggregate: 5/5 CAUGHT, 0/5 MISSED.** Complete reversal from §4's 0/5 on
the defective fixture — every rep, independently, found and correctly
edited the embedded mock, several explicitly citing it as the literal
"mock helpers that return the tuple" example named in the landed clause
text.

---

## 4b. propagation — RED-arm reps, CORRECTED FIXTURE (`update-implementation-plan`, `git show v2.5.0:`)

Full per-rep table with decisive quotes recorded in `baseline-results.md`
§9 (RED belongs in the baseline file; summarized here for the contrast
analysis). Per the controller's instruction, expanded to n=5 to match §4a.

**Aggregate: 5/5 CAUGHT, 0/5 MISSED** — every rep independently found and
edited Task 6's embedded stub as the fix's propagated dependent mention,
even running the pre-amendment v2.5.0 text (one rep, per `baseline-results.md`
§9, explicitly noted v2.5.0's proposal shape folds the "Propagate" search
into the **Fix** bullet rather than a separate `Propagation:` line, and
correctly reproduced that shape).

### Contrast analysis — corrected fixture: GREEN 5/5 vs. RED 5/5

**No discrimination on the corrected fixture either — both arms now catch
100%.** This is a different, and much better, result than §4/§4a's
defective-fixture 0/5-vs-0/5 tie: it confirms GREEN reliably works (the
controller's primary ask — "if GREEN still misses on the corrected
fixture, report that honestly" does not apply; GREEN does not miss). But
it means this particular fixture, once the mock lives inside the plan
artifact's own text, no longer isolates the *value* of Task 5's three-sweep
wording specifically — any diligent read of a short, fully-in-scope plan
document (old skill text or new) finds an embedded code block, the same
structural reason Task 1's own propagation control-arm micro-test never
produced a control-arm miss either (`microtest-results.md`'s Round
2/3/3b: 0/10 valid Arm-B misses — "artifact size relative to what any
diligent reviewer would just read outright"). **Read together with Task 1:
across every harness this project has built (Task 1's 20 reps, this
fixture's 10 defective-fixture reps, this fixture's 10 corrected-fixture
reps — 40 total propagation reps), the pre-amendment control text has
never once been caught missing a mock embedded directly in the swept
artifact.** The real 888l#96 production incident remains the only concrete
evidence that the old grep-only bullet actually fails in practice; this
task's corrected fixture now cleanly demonstrates GREEN's reliability
(5/5, matching Task 1's 15/15) without claiming a RED-arm contrast this
fixture design cannot produce. This honest framing is reported per the
same standard applied to popclosure (ruling 1) rather than treated as a
second silent gap.

---

## 5. auditor — slot-grammar-audit reps, DEFECTIVE FIXTURE (`critical-design-review`, no codebase access)

**Status note (added in the fix round, not a retroactive edit):** the
controller ruled item 4 of the fixture used in this §5 run was itself
defective — it bundled 3 named validator constraints into a single
aggregate over/under disposition rather than a disposition per constituent,
unlike every other multi-member population in the fixture. §5 below is
preserved verbatim as the historical record; rep2's "additional flag" was
real signal, not audit over-reach. **§5a below is the corrected-fixture
re-run — the authoritative current auditor result.**

Per ruling 2: each rep received ONLY the auditor fixture's `review.md` text
plus the working-tree `## Slot-grammar audit` section text from
`skills/critical-design-review/SKILL.md`, pasted verbatim into the prompt —
no tool access, no codebase access, mirroring the real audit's input
contract exactly.

Rubric: **CAUGHT** = the audit flags BOTH planted violations (undispositioned
`CacheMiddleware` matrix cell; item 4's untagged load-bearing `ok` rows) and
nothing else. **MISSED** = either violation survives as a PASS, or the audit
additionally flags something that is NOT one of the two planted defects
(scored against the fixture, per the controller's explicit instruction, not
against the audit).

| Rep | Verdict | Decisive quote |
|---|---|---|
| auditor-rep1 | **CAUGHT** (clean) | "1. Population closure... **FAIL** — `CacheMiddleware` never appears again in the bullet list — no over/under disposition..." and "2. ... **FAIL** — §0 item 4 (`ReviewValidator` row): both dispositions are untagged... Neither opens with a bracketed class tag." Items 3–5 all PASS. "**Overall: FAIL (2 of 5 checklist items fail)**." Flags exactly the two planted defects, nothing more. |
| auditor-rep2 | **CAUGHT both planted + 1 additional flag** — scored **MISSED** per the strict rubric | Flags both planted defects identically to rep1 ("`CacheMiddleware` is named in the population but never dispositioned"; "both `ok` rows are missing a class tag... unlike every other `ok` row in the document"). **Additionally** flags: "§0.4... population is named as '3 named constraints'... but disposition is given only as a single aggregate over/under pair for `ReviewValidator` as a whole... **No per-constraint row exists**, unlike the per-item treatment given to the endpoint-handler and middleware-roster populations — the named 3-member population is not individually matrixed." |
| auditor-rep3 | **CAUGHT** (clean) | "1. Population closure... **FAIL**... `CacheMiddleware` has no bullet, no ok/dropped disposition..." and "2. ... **FAIL**... both direction clauses... lack an opening class tag... unlike every other `ok` row in the document." "**Overall: FAIL (2/5 items fail)**." Flags exactly the two planted defects. |

**Aggregate under the strict letter of the rubric: 2/3 CAUGHT, 1/3 MISSED
(rep2, on the additional-flag rule).** Read more substantively: **3/3 reps
correctly identified both planted defects** with the same decisive evidence
in every case; the disagreement is only about whether a third pattern in the
fixture is *also* a defect.

### Concern — reported per ruling 2, fixture NOT adjusted

Rep2's additional flag targets a real, defensible reading of the
population-closure text in `shared-review-discipline.md`: "the round cannot
close until the full (rule × every population it governs) matrix is
enumerated: **as individual §0 rows, or as one row naming the matrix with a
disposition per cell**." Item 4 of the auditor fixture (`ReviewValidator`,
3 named constraints: `c_blocklist_check`, `c_rate_check`, `c_ip_check`) gives
exactly one aggregate `over:`/`under:` pair covering all three constraints
collectively ("each of the three constraints independently re-checks...")
rather than a disposition distinguishable per named constituent — unlike
item 3 (`§3.1 Middleware roster`), which gives one bullet per named member
even where several share near-identical reasoning. Whether a single
collective sentence satisfies "a disposition per cell" for a 3-member
population is genuinely ambiguous under the shared file's own text; 1 of 3
independent reps read it as failing closure, 2 of 3 did not raise it. This
is reported to the controller as-is — **the auditor fixture was NOT edited
or otherwise adjusted** in response to this finding, per the explicit
instruction not to silently fix a fixture based on a rep's result.

*(Superseded by the controller's fix-round ruling: this WAS a fixture
defect after all — see §5a below.)*

---

## 5a. auditor — slot-grammar-audit reps, CORRECTED FIXTURE (`critical-design-review`, no codebase access)

**Fixture fix (controller-directed, `auditor/review.md`):** item 4 rewritten
so each of the 3 named constraints (`c_blocklist_check`, `c_rate_check`,
`c_ip_check`) gets its own `over:`/`under:` bullet, matching the per-member
treatment already given to §2's 4 endpoint handlers and §3.1's 5-member
middleware roster. Every one of the 6 resulting dispositions (3 constraints
× 2 directions) is still left untagged — the missing class tag remains the
single planted defect at that item; `CacheMiddleware`'s undispositioned
matrix cell (§3.1) is untouched. Re-verified the exactly-two-defects
invariant by inspection before re-running reps: defect A (`CacheMiddleware`)
and defect B (item 4's missing tags, now correctly per-cell) are the only
two flaggable violations of the checklist against the corrected text.

Same dispatch method as §5 (no tool access, review file + Slot-grammar
audit section text pasted verbatim), 3 fresh reps.

| Rep | Verdict | Decisive quote |
|---|---|---|
| auditor-corrected-rep1 | **CAUGHT** (clean) | "1. Population closure... **FAIL** — `CacheMiddleware` is never dispositioned anywhere in §0 item 3..." "2. Class tag... **FAIL** — none of these six `ok`s (2 per constraint × 3 constraints) opens with a class tag... unlike every other `ok` in §0 items 2 and 3." "3. ...both failure directions: **FAIL**" — explicitly the *same* `CacheMiddleware` gap re-surfacing under item 3's direction check, not a new defect: "a named, rule-like roster member... has zero disposition text." **Overall: FAIL (3 of 5 checklist items fail)** — 2 root defects, 3 checklist-item hits. |
| auditor-corrected-rep2 | **CAUGHT** (clean) | "1. ... **FAIL** — `CacheMiddleware` has no bullet at all..." "2. ... **FAIL** — none of these six `ok`s... opens with a bracketed class tag." "3. Every rule-like row shows both failure directions: **PASS**... (`CacheMiddleware`'s total absence is a population-closure defect, **already captured under item 1, not a same-row direction gap**)." **Overall: FAIL (items 1 and 2 fail).** Explicitly declines to double-count `CacheMiddleware` — no extra flag. |
| auditor-corrected-rep3 | **CAUGHT** (clean) | "1. ... **FAIL**... `CacheMiddleware` never appears in a disposition bullet..." "2. ... **FAIL**... **Six ok-lines** (over+under × 3 constraints) are missing their class tag." "3. ...both failure directions: **PASS**... (`CacheMiddleware`'s total absence is a population-closure defect, already captured under item 1, not a same-row direction gap)." **Overall: FAIL (2 of 5 checklist items fail — items 1 and 2).** |

**Aggregate: 3/3 CAUGHT, 0/3 MISSED — clean across the board, zero extra
flags.** The ambiguity §5 surfaced is fully resolved: with item 4 correctly
per-cell dispositioned (still untagged), all 3 independent reps converge on
exactly the two planted defects — one rep (rep1) additionally reports the
`CacheMiddleware` gap under checklist item 3 ("both failure directions"),
but this is the *same* underlying defect crossing two checklist categories,
not a third violation — reps 2 and 3 explicitly note this distinction in
their own verdicts ("already captured under item 1, not a same-row
direction gap"), confirming it is not scored as an extra flag.

---

## 6. Ruling application notes

**Ruling 1 (popclosure honest-contrast):** applies straightforwardly. See
`baseline-results.md` §6/§7 (RED top-up) for the completed n=5 RED-arm
tally — 5/5 CAUGHT, 0/5 MISSED, no fresh miss reproduced even at the
expanded n. Per the ruling, this is recorded honestly rather than re-rolled
further, and GREEN's value for this fixture rests on the behavior-shape
argument the ruling anticipated: both GREEN reps independently produced
full-matrix enumeration with correct per-direction, class-tagged
dispositions, explicitly invoking the shared file's "roster iterated over" /
"validator constraint set" population vocabulary by name (§3 above) — a
reliably correct *mechanism*, even though this particular RED baseline's
raw miss-rate remains too low (proceeding on Task 1's own ~1/15 estimate) to
produce a fresh catch-rate delta at this n. The 888l#96 corpus remains the
documented production RED baseline for population closure, per the ruling.

**Ruling 2 (auditor fixture trial):** applied per §5 above — the audit was
run against the real Task-4 checklist text, fresh-context, review-file-only
input; the fixture's normalized exactly-two-defects design was not touched;
the additional flag rep2 raised is reported as a concern, not silently
absorbed into either the fixture or the scoring.

**Controller fix-round ruling (post-§1–§6, see task-6-report.md's fix-round
addendum):** both open concerns above (propagation's 0/5-vs-0/5 tie, the
auditor's extra flag) were ruled **fixture defects** in Task 2's original
authorship, not clause findings — the no-fixture-edits constraint was
explicitly lifted for exactly these two fixes. Both fixtures were corrected
and both arms re-run; see §4a/§4b (propagation) and §5a (auditor) above for
the corrected-fixture results, and §7 below for the updated final tallies.
No `skills/` text was touched at any point — the reps' behavior was
correct throughout; only the fixtures were wrong.

---

## 7. Final summary — GREEN + completed RED tallies (supersedes nothing in
`baseline-results.md`; that file's own §5 is superseded by its §8, added in
this task; §4/§5 above are superseded by §4a/§4b/§5a for current status,
kept verbatim as the historical record)

| Fixture | GREEN (working tree) | RED (pre-amendment, `v2.5.0`) | Discrimination? |
|---|---|---|---|
| popclosure | 2/2 CAUGHT | 5/5 CAUGHT (n expanded 2→5 per ruling 1) | None observed at this n — behavior-shape argument only (ruling 1); real 888l#96 incident remains the production evidence |
| propagation (defective fixture, §4/§4-baseline — historical) | 0/5 CAUGHT (5/5 MISSED) | 0/5 CAUGHT (5/5 MISSED, n expanded 2→5) | None — a fixture defect, since fixed |
| **propagation (corrected fixture, §4a/§4b — current)** | **5/5 CAUGHT** | **5/5 CAUGHT** | None — both arms now catch 100%; fixture no longer isolates the clause's marginal value (see §4b contrast analysis), but GREEN's reliability is now cleanly demonstrated |
| auditor (defective fixture, §5 — historical) | 2/3 CAUGHT clean, 1/3 caught-both-plus-extra-flag | N/A (no pre-Task-4 baseline — audit step is new) | N/A — a fixture defect, since fixed |
| **auditor (corrected fixture, §5a — current)** | **3/3 CAUGHT, clean, zero extra flags** | N/A (no pre-Task-4 baseline — audit step is new) | N/A — GREEN-only fixture |

Guard: GREEN, exit 0, no literal mismatch, first run. `run-tests.sh`: wired
per the brief's exact line, `ALL TESTS PASSED` confirmed end-to-end and
reconfirmed after both fixture fixes.

**Recommendation to the controller:** all three fixtures now produce clean
GREEN evidence. Popclosure and the guard/wiring were clean from the first
run. Propagation and auditor initially surfaced what looked like clause
findings but were, per the controller's fix-round ruling, fixture defects
in Task 2's original authorship — both fixed (embedding the shape-bound
mock in the plan artifact's own text; per-cell dispositioning the auditor's
§4.2 validator population) and both arms re-run to n=5/n=3 respectively,
landing 5/5, 5/5, and 3/3 CAUGHT with zero extra flags. No `skills/` text
was changed at any point in this task. The one remaining open note for the
controller (not a defect, an honest limitation) is §4b's contrast
analysis: the corrected propagation fixture demonstrates GREEN's
reliability cleanly but, because the mock now lives inside the artifact
text, no longer produces a RED-vs-GREEN discrimination for this clause on
this fixture — consistent with Task 1's own finding that this control
text's failure mode has proven very hard to reproduce in any harness
short of the real production incident.
