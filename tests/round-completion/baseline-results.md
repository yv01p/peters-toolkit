# Round-completion paired-arm harness — BASELINE (RED) results

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
