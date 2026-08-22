# Propagation-contract micro-test — prompts

Task 1 (spec `888l#96` R-b / R-b'). Tests the wording of Task 5's three-sweep
`Propagate.` bullet (verbatim, from
`.superpowers/sdd/2026-08-22-review-round-completion-implementation-plan/task-5-brief.md`,
Step 1 blockquote) against the current single-sweep control (the `Propagate.`
bullet at `skills/update-design-doc/SKILL.md:108-115`, grep-the-key-terms only).

Each arm's block below is the complete, self-contained text sent verbatim to a
fresh-context rep (no file access; artifact excerpt fully embedded). Reps see
ONLY their arm's block — never both.

**Round 1 (original scenario below this note) did not discriminate: 5/5 Arm A AND
5/5 Arm B reps disposed both planted sites.** Root cause, found on reading the
transcripts: the shared scenario labeled the mock helper "`_stub_result()` stands
in for `rank_candidate()`'s output" — a direct callout that hands sweep 3's target
to any reader regardless of which arm's clause they received — and the artifact
was small enough (4 real sections) to read in full trivially, defeating the
literal "grep only" framing Arm B's control text relies on. Per Step 3's failure
rule, the scenario (not the clause text, which converged cleanly for Arm A) was
revised: the callout was removed, the artifact was bulked out with legitimate
decoy sections so a grep-only sweep has real room to miss the two planted sites,
and shape-matching cues (a second literal 2-tuple in the same test file) replace
the explicit label. **Round 2, below the original, is the scenario actually used
for the pass/fail convergence call.** Round 1 is kept for the record — see
`microtest-results.md` for both rounds' per-rep verdicts.

## Round 1 scenario (superseded — see note above)

```
You are the "applier" in a design-doc update workflow: a reviewer's finding
required changing a design spec's ranking-output contract. You have drafted the
fix. Before finalizing, you must find every other place in the spec that also
needs updating.

**The finding:** `rank_candidate(candidate)` (design spec §2.4) needs to report
WHY a candidate got its tier, not just the score and tier — the review found no
visibility into ranking rationale.

**The fix you drafted, already applied at §2.4 only:**

Old §2.4 text: "`rank_candidate(candidate)` returns `(score: float, tier: str)` —
a 2-tuple. Downstream code destructures `score, tier = rank_candidate(c)`."

New §2.4 text (your fix, already applied): "`rank_candidate(candidate)` returns
`(score: float, tier: str, reason_code: str)` — a 3-tuple. Downstream code
destructures `score, tier, reason_code = rank_candidate(c)`."

**The rest of the spec, unedited — this is the artifact you must sweep for other
sites that also need updating:**

§1 Overview, §3 Data model, §4 API endpoints, §6 Rollout plan — none of these
mention scoring, tiers, or ranking output shape.

§5.1 Executive summary: "The ranking engine returns a numeric grade alongside a
bucket label for each candidate, letting the dashboard sort and group results in
one pass."

§7.3 Test fixtures:
```python
def _stub_result():
    return (0.82, "gold")

def test_dashboard_groups_by_bucket():
    grade, bucket = _stub_result()
    assert bucket == "gold"
```
(`_stub_result()` stands in for `rank_candidate()`'s output in dashboard tests;
several tests in this section call it and destructure two values from it.)

That is the entire spec. There are no other sections.
```

## Round 2 scenario (revised — this is the scenario used for the convergence call)

Same underlying facts as Round 1 (same finding, same fix, same two planted
sites), bulked with legitimate decoy sections and stripped of the explicit
"`_stub_result()` stands in for `rank_candidate()`'s output" callout — recognizing
that the mock's shape matches the changed contract is now left entirely to
whichever clause the rep receives.

```
You are the "applier" in a design-doc update workflow: a reviewer's finding
required changing a design spec's ranking-output contract. You have drafted the
fix. Before finalizing, you must find every other place in the spec that also
needs updating.

**The finding:** `rank_candidate(candidate)` (design spec §2.4) needs to report
WHY a candidate got its tier, not just the score and tier — the review found no
visibility into ranking rationale.

**The fix you drafted, already applied at §2.4 only:**

Old §2.4 text: "`rank_candidate(candidate)` returns `(score: float, tier: str)` —
a 2-tuple. Downstream code destructures `score, tier = rank_candidate(c)`."

New §2.4 text (your fix, already applied): "`rank_candidate(candidate)` returns
`(score: float, tier: str, reason_code: str)` — a 3-tuple. Downstream code
destructures `score, tier, reason_code = rank_candidate(c)`."

**The rest of the spec, unedited — this is the artifact you must sweep for other
sites that also need updating:**

§1 Overview: "This service ranks inbound candidates for the review queue and
hands the ranked list to the dashboard and the alerting pipeline."

§2.1 Candidate intake: describes how a `Candidate` object is constructed from the
upstream event stream; no scoring or tier logic.

§2.2 Queue admission: a candidate is admitted to the queue once its intake fields
pass a completeness check; no scoring or tier logic.

§2.3 Alerting hook: `alert_if_urgent(candidate)` checks a separate `urgency` field
set by the intake pipeline; unrelated to ranking.

§3 Data model: table definitions for `Candidate`, `QueueEntry`, `AlertLog`; no
ranking-output fields represented.

§4 API endpoints: `GET /queue`, `POST /candidates`, `GET /alerts`; none of the
response schemas mention scoring, tiers, or ranking output.

§5.1 Executive summary: "The ranking engine returns a numeric grade alongside a
bucket label for each candidate, letting the dashboard sort and group results in
one pass."

§6 Rollout plan: three-phase rollout description; no scoring or tier content.

§7.1 Fixture setup: shared `pytest` fixtures for constructing `Candidate` objects;
no ranking-output content.

§7.2 Queue admission tests: tests for §2.2's completeness check; no
ranking-output content.

§7.3 Dashboard tests:
```python
def _stub_result():
    return (0.82, "gold")

def test_dashboard_groups_by_bucket():
    grade, bucket = _stub_result()
    assert bucket == "gold"

def test_dashboard_sorts_descending():
    a = _stub_result()
    b = (0.55, "silver")
    assert a[0] > b[0]
```

That is the entire spec.
```

## Arm A — clause (Task 5 three-sweep `Propagate.` bullet, verbatim)

Question sent to Arm A reps: **"Produce the `Propagation:` line for this fix."**

Full text sent to Arm A reps (Round 2; Round 1 used the Round 1 scenario above):

```
This is a self-contained reasoning exercise. Do not use any tools — do not read,
write, or search for files, do not run commands, do not look anything up.
Everything you need is given below. Reason through it and give your final answer
as the text of your final report; that final message is your only graded output.

<Round 2 scenario, embedded verbatim as above>

Your project's review discipline includes the following binding rule. Apply it
exactly as written:

> - **Propagate.** After drafting the fix, run three sweeps over the artifact,
>   each yielding per-site dispositions:
>   1. **Literal:** grep the artifact for the changed text's key terms.
>   2. **Semantic restatements:** enumerate the sections that restate the changed
>      rule *in other words* — goals, summaries, limits, ADR echoes, and
>      ground-truth/roster lists are standing targets — checked by reading, not
>      grep.
>   3. **Mechanism/contract:** when the fix parameterizes a mechanism (adds an
>      argument, context, or mode) or changes a value contract (arity, tuple
>      shape, key set, grain), enumerate every artifact site that invokes,
>      constructs, returns, or asserts that mechanism or shape — discovered by
>      shape as well as symbol name (mock helpers that return the tuple, arity
>      assertions — sites a "call site" sweep cannot reach).
>
>   Each enumerated site either receives a consistent tracked edit — part of the
>   same proposal, under the same approval gate — or is dispositioned
>   `unaffected — <why>`. A fix that rewrites one section's rule while a later
>   section still records the replaced quantities ships an internally
>   inconsistent artifact.

Produce the `Propagation:` line for this fix.
```

## Arm B — control (current UDD:108-115 `Propagate.` bullet, verbatim, grep-the-key-terms only)

Question sent to Arm B reps: **"State which other artifact sites your fix must also touch."**

Full text sent to Arm B reps (Round 2; Round 1 used the Round 1 scenario above):

```
This is a self-contained reasoning exercise. Do not use any tools — do not read,
write, or search for files, do not run commands, do not look anything up.
Everything you need is given below. Reason through it and give your final answer
as the text of your final report; that final message is your only graded output.

<Round 2 scenario, embedded verbatim as above>

Your project's review discipline includes the following binding rule. Apply it
exactly as written:

> - **Propagate.** After drafting the fix, search the artifact for other
>   statements of the quantity, rule, or mechanism the fix changes (grep
>   the artifact for the changed text's key terms). Each dependent mention
>   either receives a consistent tracked edit — part of the same proposal,
>   under the same approval gate — or an explicit note in the proposal that
>   it is unaffected and why. A fix that rewrites one section's rule while
>   a later section still records the replaced quantities ships an
>   internally inconsistent artifact.

State which other artifact sites your fix must also touch.
```

## Round 3 — tool-mediated (controller-directed, on-disk fixtures)

Controller ruling: Round 2's diagnosis (no grep restriction is possible inside a
no-tool, fully-embedded prompt) was accepted, and Round 3 removes that ceiling.
Same underlying facts as Round 2 — not re-tuned — relocated to real files:
- `round3-fixture/propagation/spec.md` (the plan-artifact under review, §2.4's
  fix already applied, containing the §5.1 paraphrase site)
- `round3-fixture/propagation/test_dashboard.py` (real test source: the §7.3
  shape-matched mock site)
- `round3-fixture/propagation/review_finding.md` (the review fix text: the
  finding, old §2.4 text, new §2.4 text)

Reps get file paths instead of embedded text, and are explicitly told they may
use Read/Grep/Bash (read-only) as they see fit. Questions and both arms' clause
texts are byte-identical to Round 2.

Full text sent to Arm A reps (Round 3):

```
You are the "applier" in a design-doc update workflow: a reviewer's finding
required changing a design spec's ranking-output contract. The fix has already
been drafted and applied to the spec. Before finalizing, you must find every
other place in the spec that also needs updating.

The design spec (with the fix already applied at §2.4), a test file it
references, and the review finding text are on disk at:
- <repo>/tests/round-completion/microtest/round3-fixture/propagation/spec.md
- <repo>/tests/round-completion/microtest/round3-fixture/propagation/test_dashboard.py
- <repo>/tests/round-completion/microtest/round3-fixture/propagation/review_finding.md

You may use Read and Grep on these files as needed to investigate. This is a
read-only investigation — do not edit any files anywhere. Start by reading
review_finding.md, then spec.md, then investigate further as your review
discipline (below) directs.

Your project's review discipline includes the following binding rule. Apply it
exactly as written:

> - **Propagate.** [same three-sweep clause text as Round 1/2, above —
>   verbatim, unchanged]

This is a single-shot exercise: investigate the fixture files as you see fit,
then give one final answer.

Before your final answer, list every tool call you made (tool name + target
file/query), in the order you made them.

Then answer: Produce the `Propagation:` line for this fix.
```

Full text sent to Arm B reps (Round 3) is identical except the clause block is
replaced with the verbatim current UDD:108-115 control text (same as Round 1/2,
above), unchanged, and the closing question is "State which other artifact
sites your fix must also touch."

## Target behavior (scoring rubric)

- **Arm A (target: HIT):** disposes both planted sites — §5.1's paraphrase
  ("numeric grade" / "bucket label" is the same score/tier rule in other words,
  caught by the semantic-restatement sweep) AND §7.3's `_stub_result()` mock
  (returns the OLD 2-tuple shape, caught by the mechanism/contract sweep's
  shape-based discovery, not by grepping "rank_candidate"/"score"/"tier"). Each
  gets an `edited` or `unaffected — <why>` disposition, or the `Propagation:` line
  otherwise names both sites explicitly.
- **Arm B (target: MISS):** literal key-term grep for "score" / "tier" /
  "reason_code" / "rank_candidate" (the changed text's terms) matches neither
  §5.1 (different vocabulary entirely) nor §7.3 (`_stub_result`, `grade`,
  `bucket` — no shared terms) — a rep following only this control text is
  expected to report no other sites need touching, or to name unrelated/no
  sites.
