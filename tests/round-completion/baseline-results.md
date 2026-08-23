# Round-completion paired-arm harness — BASELINE (RED) results

**Status note (added by Task 6, not a Task 2 edit):** §1–§5 below are Task
2's original record, preserved verbatim — at the time they were written the
guard was genuinely unwired and Tasks 3–5 hadn't landed. Task 6 has since
wired the guard into `tests/run-tests.sh` (now passing, `ALL TESTS PASSED`)
and expanded the RED arms to n=5 for both popclosure and propagation (§6–§8
below). A controller-directed fix round then corrected a fixture defect in
the propagation fixture (§9–§10) — **§10 is the current, authoritative
propagation tally.** See `green-results.md` for the GREEN-arm (working
tree, post Tasks 3–5) results this baseline is paired against, and its
§4a/§4b/§5a for the corrected-fixture GREEN + auditor results.

Task 2 of the `888l#96` round-completion-implementation-plan. Records RED
evidence against the CURRENT (pre-Task-3/4/5-edit) working tree: the
deterministic guard's failure output, plus baseline-arm (`git show v2.5.0:`)
rep results for the popclosure and propagation fixtures (n=2 each, per
`task-2-brief.md` Step 6's "n=2 per fixture minimum at this stage"). The
auditor fixture is built (`tests/round-completion/auditor/review.md`) but
NOT rep-tested here — the "Slot-grammar audit" step it exercises doesn't
exist at all in v2.5.0 (it's new in Task 4), so there is no baseline arm to
run against it yet; per the brief, its rep testing happens in Task 6 once
the audit step exists in the (post-edit) skill text.

The guard (`check-round-completion.sh`) is NOT wired into
`tests/run-tests.sh` — confirmed unwired below, and `bash tests/run-tests.sh`
still passes end-to-end.

---

## 1. Guard RED output

Command: `bash tests/round-completion/check-round-completion.sh`

Exit code: **1** (failure — expected/RED).

```
-- assertion 1: shared file carries the Population closure section --
MISSING population-closure section header in skills/critical-design-review/shared-review-discipline.md: [## Population closure]
-- assertion 2: CDR + CIR reference population closure, enclosing-surface bound gone --
MISSING population-closure family reference in skills/critical-design-review/SKILL.md: [per the population-closure section in `shared-review-discipline.md`]
STALE 'bounded to the enclosing surface' still present in skills/critical-design-review/SKILL.md: [bounded to the enclosing surface]
MISSING population-closure family reference in skills/critical-implementation-review/SKILL.md: [per the population-closure section in `shared-review-discipline.md`]
STALE 'bounded to the enclosing surface' still present in skills/critical-implementation-review/SKILL.md: [bounded to the enclosing surface]
-- assertion 3: shared file carries per-direction grammar + class-tag vocabulary --
MISSING per-direction/class-tag slot grammar in skills/critical-design-review/shared-review-discipline.md: [over: ok — <probe> / under: → §2.1]
MISSING per-direction/class-tag slot grammar in skills/critical-design-review/shared-review-discipline.md: [[totality]]
MISSING per-direction/class-tag slot grammar in skills/critical-design-review/shared-review-discipline.md: [[existence]]
-- assertion 4: UDD + UIP carry the Propagation: slot + three-sweep enumeration --
MISSING Propagation slot / three-sweep enumeration in skills/update-design-doc/SKILL.md: [**Propagation** — the enumerated sites from the three sweeps]
MISSING Propagation slot / three-sweep enumeration in skills/update-design-doc/SKILL.md: [1. **Literal:**]
MISSING Propagation slot / three-sweep enumeration in skills/update-design-doc/SKILL.md: [2. **Semantic restatements:**]
MISSING Propagation slot / three-sweep enumeration in skills/update-design-doc/SKILL.md: [3. **Mechanism/contract:**]
MISSING Propagation slot / three-sweep enumeration in skills/update-implementation-plan/SKILL.md: [**Propagation** — the enumerated sites from the three sweeps]
MISSING Propagation slot / three-sweep enumeration in skills/update-implementation-plan/SKILL.md: [1. **Literal:**]
MISSING Propagation slot / three-sweep enumeration in skills/update-implementation-plan/SKILL.md: [2. **Semantic restatements:**]
MISSING Propagation slot / three-sweep enumeration in skills/update-implementation-plan/SKILL.md: [3. **Mechanism/contract:**]
-- assertion 5: CDR + CIR carry the amendment-hunk clause + both anchor forms --
MISSING amendment-hunk clause / anchor form in skills/critical-design-review/SKILL.md: [reviewed at fix-equivalent rigor]
MISSING amendment-hunk clause / anchor form in skills/critical-design-review/SKILL.md: [**Artifact HEAD at review:**]
MISSING amendment-hunk clause / anchor form in skills/critical-design-review/SKILL.md: [**Artifact anchor at review:** content:]
MISSING amendment-hunk clause / anchor form in skills/critical-implementation-review/SKILL.md: [reviewed at fix-equivalent rigor]
MISSING amendment-hunk clause / anchor form in skills/critical-implementation-review/SKILL.md: [**Artifact HEAD at review:**]
MISSING amendment-hunk clause / anchor form in skills/critical-implementation-review/SKILL.md: [**Artifact anchor at review:** content:]
-- assertion 6: CDR + CIR carry the fresh-context dispatch note + slot-grammar audit step --
MISSING fresh-context dispatch note / slot-grammar audit step in skills/critical-design-review/SKILL.md: [Run the review as a fresh-context agent whose context is this skill]
MISSING fresh-context dispatch note / slot-grammar audit step in skills/critical-design-review/SKILL.md: [Slot audit:]
MISSING fresh-context dispatch note / slot-grammar audit step in skills/critical-implementation-review/SKILL.md: [Run the review as a fresh-context agent whose context is this skill]
MISSING fresh-context dispatch note / slot-grammar audit step in skills/critical-implementation-review/SKILL.md: [Slot audit:]
ROUND-COMPLETION CHECKS FAILED
```

**Every one of the 6 assertion classes fails**, every sub-literal within
each class is individually reported missing (or, for assertion 2's absence
check, individually reported STALE-still-present) — 26 individual failure
lines across the 6 classes. This is the expected RED baseline: none of
Task 3/4/5's amendments have landed yet.

**Confirmed unwired:**

```
$ grep -n "round-completion" tests/run-tests.sh || echo "NOT WIRED"
NOT WIRED
```

**Confirmed the rest of the suite is unaffected:**

```
$ bash tests/run-tests.sh
...
ALL TESTS PASSED
```

---

## 2. Ground truth

### popclosure fixture

`tests/round-completion/popclosure/design-spec.md` + `src/handler_roster.py`
+ `src/ledger_validator.py`. Rule R ("clamp to `MAX_AMOUNT` before persist")
is already confirmed failing on 2 record types (`Refund`, `Adjustment`,
given in the spec's own "§0 sweep so far"). Two further populations Rule R
also governs, neither part of any §0 row yet:

- **§4.1 `HANDLER_ROSTER`** (an iterated roster member): `WalletHandler.process()`
  (`handler_roster.py:31-32`) calls `_persist_to_ledger(amount)` with no
  `clamp_to_max()` — confirmed by reading the source; the other 4 handlers
  (`StripeHandler`, `AchHandler`, `WireHandler`, `ManualHandler`) all clamp.
- **§5.2 `LedgerValidator`** (a permitted-branch validator constraint):
  `sign_off()` (`ledger_validator.py:20-24`) clamps `c_refund_amt`,
  `c_fee_amt`, `c_tax_amt` in a loop but assigns `c_writeoff_amt` straight
  from `field_values` with no `clamp_to_max()` call, despite `c_writeoff_amt`
  being listed in `CONSTRAINTS` alongside the three clamped fields.

CAUGHT = the review's completed §0 enumeration surfaces both of these.
MISSED = the review stops at the 2 already-given record-type findings (or
extends only within the enclosing file/section span of those two).

### propagation fixture

`tests/round-completion/propagation/impl-plan.md` + `review.md` +
`src/ranking.py` + `src/test_dashboard.py`. The review's single §2 finding
proposes changing Task 3's `rank_candidate()` contract from a 2-tuple
`(score, tier)` to a 3-tuple `(score, tier, reason_code)`. Two planted sites
in the plan artifact also state or embody the old shape, with no shared key
terms to a literal grep:

- **Task 4** (paraphrase, no shared key terms): "The dashboard's summary
  panel reports a numeric grade alongside a bucket label for each
  candidate" — semantically restates score/tier without using the words
  "score", "tier", "rank_candidate", or "2-tuple".
- **`src/test_dashboard.py`'s `_stub_result()`** (shape-matched mock):
  `return (0.82, "gold")`, destructured `grade, bucket = _stub_result()` —
  matches the OLD 2-tuple shape, discoverable by shape (not by grepping the
  changed text's key terms).

CAUGHT = the proposal disposes both sites (names them and gives each a
consistent update, or a reasoned `unaffected` call that engages with the
shape/rule match). MISSED = a site is absent from the proposal entirely, or
dismissed on `call-site`-only grounds that don't engage with the shape
match (see rep1's note below — a genuine, if partial, defect surfaced).

---

## 3. popclosure — baseline-arm reps (`critical-design-review`, `git show v2.5.0:`)

Rep dispatch: fresh-context `general-purpose` subagents (model: sonnet),
each given `git show v2.5.0:skills/critical-design-review/SKILL.md`,
`git show v2.5.0:skills/critical-design-review/shared-review-discipline.md`,
and the fixture (`design-spec.md` + `src/`), instructed to continue the §0
coverage-enumeration sweep the spec's "§0 sweep so far" leaves off, and to
stay within the named files (no repo-wide exploration). Each rep's final
report was recovered verbatim (each ran a single, non-interactive turn to
completion; no ambiguous in-flight state to reconcile).

| Rep | Verdict | Decisive quote |
|---|---|---|
| popclosure-rep1 | **CAUGHT** | Both cells surfaced with disposition and evidence: `WalletHandler.process` → `_persist_to_ledger(amount)` (`handler_roster.py:32`) — "**FAIL, no `clamp_to_max()` call before persist.**" → §2.3; `c_writeoff_amt` → `clamped["c_writeoff_amt"] = field_values["c_writeoff_amt"]` (`ledger_validator.py:24`) — "**FAIL, no `clamp_to_max()` call; raw value passed straight through to sign-off**" → §2.4. Explicit "Recurrence/family check" paragraph: "Each new finding's enclosing surface (the 5-member `HANDLER_ROSTER`; the 4-member `CONSTRAINTS` tuple) was enumerated in full." |
| popclosure-rep2 | **CAUGHT** | Same two findings, independently reached: "`WalletHandler.process`: **FAIL** — `_persist_to_ledger(amount)`, no `clamp_to_max()` call (`handler_roster.py:32`). → §2.3" and "`c_writeoff_amt`: **FAIL** — listed in `CONSTRAINTS` (`ledger_validator.py:17`) but excluded from the clamp loop's tuple ... → §2.4." |

**Aggregate: 2/2 CAUGHT, 0/2 MISSED.**

**Concern, reported honestly per instructions (not re-rolled):** this n=2
sample did NOT reproduce a baseline miss. This is consistent with, not
contradictory to, Task 1's own documented finding for the population-closure
control arm: Task 1 found the current "And the family" text produces a
genuine literal-bound miss in only a minority of reps (1/5 in its Round 2,
0/5 in Round 3 and 3b — 1 miss across 15 valid control-arm reps total), with
most reps reaching full coverage via general diligence rather than the
clause's explicit population framing. At n=2 here, landing 0 misses is the
statistically expected outcome given that low observed baseline miss-rate,
not evidence the mechanism is illusory — Task 1 already demonstrated the gap
is real (one clean literal-bound miss) and reasoned at length about why the
clause's value is *reliability* (a sometimes-correct diligence pattern made
always-correct), not "the control arm always fails." Flagging for the
controller: if Task 6 wants a stronger baseline-miss demonstration for this
fixture specifically, a larger n or a more probe-expensive variant (per Task
1's Round 3 discussion of fixture size vs. tool-mediated diligence) may be
needed — this is a call for Task 6, not something addressed here.

---

## 4. propagation — baseline-arm reps (`update-implementation-plan`, `git show v2.5.0:`)

Rep dispatch: fresh-context `general-purpose` subagents (model: sonnet),
each given `git show v2.5.0:skills/update-implementation-plan/SKILL.md`,
the fixture's `review.md` (pre-accepted, single §2 finding) and
`impl-plan.md`, and `src/` on request; instructed to produce the exact
Finding/Fix/Evidence/Gate proposal message per the v2.5.0 process (no
`Propagation:` slot exists in that version — reps followed its actual
grep-only Propagate bullet), stopping before the approval gate. Stayed
within the named files (no repo-wide exploration). Each rep's final report
was recovered verbatim.

| Rep | Verdict | Decisive quote |
|---|---|---|
| propagation-rep1 | **MISSED** (site 2) — see note | Task 4 explicitly considered: "`grade`/`bucket` echo `score`/`tier` in different words, but `src/test_dashboard.py`'s `_stub_result()` returns a hardcoded `(0.82, "gold")` and is destructured as `grade, bucket = _stub_result()` — **independent of any call to `rank_candidate`, so it isn't coupled to the function's arity**." Concludes "checked, left unedited" for both sites. |
| propagation-rep2 | **MISSED** | `src/test_dashboard.py` never appears as a propagation-check item at all — it is cited only inside the "Evidence" section to re-confirm the reviewer's finding-evidence ("no rationale field exists in the downstream dashboard consumer either, matching the reviewer's... claim"), never dispositioned as a site needing `edited`/`unaffected`. Propagation check list has exactly 2 items (`Verified plan-level assumptions` row 1; Task 4), both "unaffected" — the mock is absent from the sweep entirely. |

**Aggregate: 0/2 CAUGHT, 2/2 MISSED — both reps ship a §2 proposal that
never widens `_stub_result()` to the new 3-tuple shape.**

**Concern, reported honestly (not re-rolled or softened):** rep1's miss is
worth flagging precisely because it is *not* a clean "never looked" miss —
rep1 explicitly read `_stub_result()`, correctly noticed its 2-tuple shape,
and then reasoned it away with the exact "call-site" logic Task 5's new
sweep-3 clause exists to override: *"independent of any call to
`rank_candidate`, so it isn't coupled to the function's arity."* That
sentence is a textbook illustration of the 888l#96/R-b' gap — a rep that read
the file and still concluded "unaffected" because nothing literally *calls*
`rank_candidate`, exactly the "sites a 'call site' sweep cannot reach" blind
spot the new clause's shape-based discovery language targets. Scored MISSED
here (the mock ships unedited either way, which is what "either site absent
[from the effective propagation]" is checking for in substance), but noting
explicitly that rep1's failure mode is richer than rep2's — this is good
evidence FOR the clause's necessity, not evidence the fixture failed to
discriminate. Also notable versus Task 1: Task 1 found **zero** baseline
misses for propagation across 15 valid control-arm reps in 3 rounds (embedded
and tool-mediated); this fixture, tool-mediated against the real skill text
end-to-end, reproduced 2/2 misses at n=2 — a stronger discriminating result
than Task 1's harness ever achieved for this clause.

---

## 5. Summary

| Fixture | Guard assertion classes RED | Baseline reps run | Baseline MISSED |
|---|---|---|---|
| (guard, all 6 classes) | 6/6 FAIL | n/a | n/a |
| popclosure | (covered by classes 1–3, applies post-edit) | 2 | 0/2 (see concern above) |
| propagation | (covered by class 4, applies post-edit) | 2 | 2/2 |
| auditor | (covered by classes 5–6, applies post-edit) | 0 (deferred to Task 6 — no baseline arm exists yet) | n/a |

Guard: unambiguous RED, every assertion class and every sub-literal fails
against the current tree, exactly as expected pre-Task-3/4/5. `run-tests.sh`
is unaffected (guard confirmed not wired in; full suite still passes).

Rep evidence: propagation's baseline arm cleanly demonstrates the targeted
gap (2/2 MISSED, one of them a rich "read the file, still miscategorized it
as a call-site-only concern" miss). Popclosure's baseline arm did not
reproduce a miss at n=2 — reported honestly above as a concern for Task 6,
consistent with Task 1's own finding that this control text's miss rate is
low but real, not zero.

---

## 6. Task 6 RED top-up — popclosure (reps 3–5, n expanded 2→5 per controller ruling 1)

Controller ruling (session ledger, carried forward to Task 6): §3's n=2
baseline-arm result (2/2 CAUGHT, no fresh miss) is expanded to n=5 total
before accepting the honest-contrast framing. Same dispatch method as §3:
fresh-context `general-purpose` subagents (model: sonnet), each running
`git -C <repo> show v2.5.0:skills/critical-design-review/SKILL.md` and the
matching `shared-review-discipline.md` themselves (rather than being handed
pre-fetched text), then applying that v2.5.0 text to the same
`design-spec.md` + `src/` fixture, scoped to the fixture directory and the
two `git show` commands only. Same rubric as §3 (CAUGHT = both §4.1
`WalletHandler` and §5.2 `c_writeoff_amt` surfaced; MISSED = the round stops
at the 2 given findings or extends only partially).

| Rep | Verdict | Decisive quote |
|---|---|---|
| popclosure-baseline-rep3 | **CAUGHT** | "`WalletHandler.process` (`:30-32`): `_persist_to_ledger(amount)` — **no call to `clamp_to_max()`** anywhere in its process method. **FAIL.** → §2.3" and "`c_writeoff_amt`: `sign_off()` passes `field_values["c_writeoff_amt"]` straight through at `:24` with **no `clamp_to_max()` call**... **FAIL.** → §2.4" |
| popclosure-baseline-rep4 | **CAUGHT** | "`WalletHandler.process`: **FAIL** — persists raw `amount` with no `clamp_to_max()` call: `_persist_to_ledger(amount)` (handler_roster.py:32), unlike its four siblings. → §2.3" and "`c_writeoff_amt`: **FAIL** — assigned straight from `field_values` with no `clamp_to_max()` call (ledger_validator.py:24)... → §2.4" |
| popclosure-baseline-rep5 | **CAUGHT** | "Row 9: `WalletHandler.process`... — `_persist_to_ledger(amount)`. **FAIL** — no `clamp_to_max()` call anywhere in this handler's persistence path... **→ §2.3**" and "Row 16: `c_writeoff_amt`... — `clamped["c_writeoff_amt"] = field_values["c_writeoff_amt"]`. **FAIL** — assigned directly from the input dict; not included in the... loop... **→ §2.4**" |

**Reps 3–5 aggregate: 3/3 CAUGHT, 0/3 MISSED. Combined with §3 (reps 1–2):
popclosure baseline-arm total is now 5/5 CAUGHT, 0/5 MISSED at n=5.**

**Honest result, not re-rolled further:** expanding to n=5 did not
reproduce a fresh literal-bound miss for this control text on this fixture.
This is the outcome flagged as possible in §3's original concern note, and
per the controller's ruling it is recorded honestly rather than treated as
grounds to keep expanding: Task 1's own documented finding (1 genuine miss
across 15 valid control-arm reps in three rounds, ~1/15 ≈ 6–7% observed
rate) predicts that 5 more reps landing 0 fresh misses is the statistically
expected outcome, not evidence the underlying gap is illusory. Per ruling 1,
GREEN's evidentiary value for this fixture rests on the *behavior-shape*
argument (mandatory full-matrix enumeration, correct per-cell dispositions,
explicit population-closure vocabulary) documented in `green-results.md`
§3/§6, not on a raw RED-vs-GREEN catch-rate delta — and the real 888l#96
incident remains the documented production baseline for this control's
value.

---

## 7. Task 6 RED top-up — propagation (reps 3–5, n expanded 2→5 to match the GREEN-arm expansion)

Task 6's GREEN-arm propagation reps (see `green-results.md` §4) produced a
clean, unambiguous 5/5 MISS after expansion — the opposite of the expected
result. Per the brief's instruction ("if you run GREEN propagation at n>2,
top up its RED arm to match"), the baseline arm here is expanded from n=2
(§4 above) to n=5 to match. Same dispatch method as §4: fresh-context
`general-purpose` subagents run `git -C <repo> show
v2.5.0:skills/update-implementation-plan/SKILL.md` themselves, then apply
that pre-amendment text (no `Propagation:` slot, no three-sweep contract) to
the same `impl-plan.md` + `review.md` + `src/` fixture, scoped to the
fixture directory and the one `git show` command only. Same rubric as §4.

| Rep | Verdict | Decisive quote |
|---|---|---|
| propagation-baseline-rep3 | **MISSED** (site 2 read, cited as justification, never itself dispositioned) | "Read `src/test_dashboard.py` — its stub `_stub_result()` returns `(0.82, "gold")` and both tests destructure only `grade, bucket`, confirming the same gap at Task 4's downstream consumer, **which is what makes it a dependent mention of the changed quantity**" — used solely to justify editing Task 4's *prose*; the Fix section proposes edits to Task 3 and Task 4 only. `src/test_dashboard.py` itself never receives its own `edited`/`unaffected` disposition — the mock ships unedited either way. |
| propagation-baseline-rep4 | **MISSED** (same pattern) | "Also read `src/test_dashboard.py:1-16`... confirming Task 4 is a genuine dependent mention of the mechanism the fix changes... **so it gets a consistent tracked edit rather than a skip**" — again the tracked edit is to Task 4's prose only; the mock file itself is read for evidence and never proposed as its own edit site. |
| propagation-baseline-rep5 | **MISSED** (same pattern) | "Also read `src/test_dashboard.py:4-16` — `_stub_result()` returns `(0.82, "gold")`... **confirming Task 4's dashboard is the plan's downstream consumer** of the same 2-field shape the fix replaces — which is what makes Task 4 a dependent mention requiring the propagated edit above **rather than a note that it's unaffected**." Same pattern: Task 4 prose edited, `_stub_result()` itself never dispositioned. |

**Reps 3–5 aggregate: 0/3 CAUGHT, 3/3 MISSED. Combined with §4 (reps 1–2):
propagation baseline-arm total is now 0/5 CAUGHT, 5/5 MISSED at n=5 —
identical to the GREEN arm's 0/5 CAUGHT, 5/5 MISSED (`green-results.md`
§4).**

**This is the central finding flagged to the controller in
`green-results.md` §4:** propagation shows **zero discrimination** between
pre- and post-Task-5 skill text on this fixture, at n=5 on both arms. Unlike
§4's original reps (which either never opened the mock file, or dismissed
it on "not coupled to arity" call-site-only grounds), all three top-up reps
here (and 3 of the 5 GREEN reps) DID read `src/test_dashboard.py` and
correctly recognized it as evidence of a real shape match — but every one
of them routed that recognition into editing Task 4's *prose* description
rather than treating the mock *file* as its own swept site needing a
consistent tracked edit. This is a more sophisticated engagement with the
shape match than a pure "never looked" miss, but the practical outcome is
identical: the mock ships unedited in every one of 10 total reps across
both arms. See `green-results.md` §4 for the root-cause diagnosis (this
fixture's mock lives in a codebase file only *cited* by the plan artifact,
not embedded in the artifact's own text — a structural difference from
Task 1's microtest fixture, which validated the same clause wording at
15/15 HIT with the mock embedded directly inside the swept document).

---

## 8. Updated summary (supersedes §5 above)

| Fixture | Guard assertion classes RED (pre-amendment) | Baseline reps run | Baseline CAUGHT | Baseline MISSED |
|---|---|---|---|---|
| (guard, all 6 classes) | 6/6 FAIL | n/a | n/a | n/a |
| popclosure | (covered by classes 1–3, applies post-edit) | 5 | 5/5 | 0/5 |
| propagation | (covered by class 4, applies post-edit) | 5 | 0/5 | 5/5 |
| auditor | (covered by classes 5–6, applies post-edit) | 0 (no pre-Task-4 baseline exists — audit step is new; GREEN-only per `green-results.md` §5) | n/a | n/a |

Popclosure: expanded to n=5 per controller ruling 1; no fresh miss
reproduced (consistent with Task 1's ~1/15 low-but-real baseline miss rate).
Propagation: expanded to n=5 to match the GREEN arm's expansion; produced
the same 5/5 miss as the GREEN arm — see §7's concern and
`green-results.md` §4 for the full analysis and the diagnosis flagged to
the controller. §5's original n=2 tallies and framing are preserved above
unedited, for the historical record of what Task 2 actually ran and
concluded at the time; this §8 is the authoritative, current tally as of
Task 6, **superseded in turn by §10 below once the fixture fix landed.**

---

## 9. Fix round — propagation RED-arm reps, CORRECTED FIXTURE (`update-implementation-plan`, `git show v2.5.0:`)

**Status note:** §4 and §7 above are preserved verbatim as the historical
record — at the time they ran, the propagation fixture was genuinely
defective (the shape-bound mock was planted in `src/test_dashboard.py`, a
file the plan only cites, rather than embedded in the plan artifact's own
text, contrary to the plan's own required fixture design). The controller
ruled this a Task 2 fixture defect and lifted the no-fixture-edits
constraint for exactly this fix. `impl-plan.md` now carries a new `## Task
6: Dashboard test coverage` embedding the mock directly (see
`green-results.md` §4a for the exact diff and the shape/vocabulary
rationale). This §9 is the re-run against that corrected fixture — n=5,
matching `green-results.md` §4a's GREEN-arm expansion. Same dispatch
method as §4/§7 (fresh-context reps run `git show
v2.5.0:skills/update-implementation-plan/SKILL.md` themselves, scoped to
the fixture directory and that one command).

| Rep | Verdict | Decisive quote |
|---|---|---|
| propagation-baseline-corrected-rep1 | **CAUGHT** | "Propagating this contract change to its one other dependent mention in the plan: **Task 6's stub mirrors `rank_candidate`'s return shape** for the dashboard's test coverage, so it must move to the same 3-tuple to stay consistent with Task 3." |
| propagation-baseline-corrected-rep2 | **CAUGHT** | "Propagated dependent mention — **Task 6's stub code mirrors the exact 2-tuple shape and destructuring pattern this fix changes**, and would go stale if left as-is." |
| propagation-baseline-corrected-rep3 | **CAUGHT** | "Propagated edit — **Task 6's embedded stub restates the same `rank_candidate` output shape** ('Stub the ranking output... until the real service integration lands') and would silently diverge from Task 3's new contract if left alone." This rep also correctly identified that v2.5.0's actual proposal shape (step 5's "Present the fix proposal in this shape" bullet) is **Finding / Fix / Evidence / Gate**, with no separate `Propagate:` line — the "Propagate" bullet is a drafting-time search-and-track action whose results fold into the **Fix** bullet — and reproduced that shape rather than inventing a `Propagation:` line the v2.5.0 text doesn't specify. |
| propagation-baseline-corrected-rep4 | **CAUGHT** | "Task 6 (propagated dependent mention — its stub encodes the old 2-tuple shape it's standing in for) — change:" `_stub_result()` and the destructure line both updated to the 3-tuple; `test_dashboard_sorts_descending` (which destructures only `a[0]`, not by arity) correctly left as-is. |
| propagation-baseline-corrected-rep5 | **CAUGHT** | "Propagated edit — **Task 6's stub records the same replaced quantity** (it mirrors `rank_candidate`'s old 2-value return shape for the dashboard's test coverage) and would otherwise ship an internally inconsistent plan." |

**Aggregate: 5/5 CAUGHT, 0/5 MISSED.** Complete reversal from §7's 0/5 on
the defective fixture — every rep, running the unmodified pre-amendment
skill text, independently found and edited the now-embedded mock. See
`green-results.md` §4b for the full contrast analysis against the matching
GREEN-arm 5/5: both arms now catch 100%, which confirms GREEN's
reliability but means this particular fixture no longer isolates the
marginal value of Task 5's three-sweep wording specifically (any diligent
read of a short, fully-in-scope plan document finds an embedded code
block, regardless of clause version) — reported honestly rather than
claimed as a clean RED-vs-GREEN discrimination this fixture design cannot
produce.

---

## 10. Updated summary (supersedes §8 above)

| Fixture | Baseline reps run | Baseline CAUGHT | Baseline MISSED |
|---|---|---|---|
| popclosure | 5 | 5/5 | 0/5 |
| propagation (defective fixture — historical, §4/§7) | 5 | 0/5 | 5/5 |
| **propagation (corrected fixture — current, §9)** | **5** | **5/5** | **0/5** |
| auditor | 0 (no pre-Task-4 baseline exists — audit step is new) | n/a | n/a |

Propagation's defective-fixture 5/5-MISSED result (§4/§7) is preserved
verbatim for the historical record — it was real evidence of a real
fixture defect (planting the shape-bound site outside the artifact text),
not evidence against the clause. §9's corrected-fixture 5/5-CAUGHT is the
current, authoritative baseline-arm result. This §10 supersedes §8; §8 in
turn superseded §5; none of the superseded sections were deleted or
edited, per the standing instruction to keep the historical record intact.
