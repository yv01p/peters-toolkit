# Wording micro-tests — population closure + propagation contract

Task 1 (spec `888l#96` R-a, R-b/R-b'). 40 single-shot, fresh-context subagent reps
(20 per clause; 5 per arm per round, 2 rounds), scored manually by reading each
rep's returned answer against the target behavior. Prompts: `microtest/popclosure-prompt.md`,
`microtest/propagation-prompt.md`.

## Why two rounds

Round 1 used a scenario that leaked the answer into shared, arm-independent text
(clause vocabulary like "governed population" / "roster" baked into the facts, and
an explicit "`_stub_result()` stands in for `rank_candidate()`'s output" callout
for propagation). Both arms hit at ~100% regardless of which clause they
received — the test wasn't discriminating, so per Step 3's failure rule the
scenario (not the clause text, which is verbatim from Tasks 3/5 and unchanged
throughout) was revised to state the same facts neutrally, and all 4 arms were
re-run. **Round 2 is the round used for the pass/fail convergence call.** Round 1
is kept below for the record, since it's real evidence of the leak and of Arm A's
wording holding up even before the scenario was fixed.

Scoring key: **HIT** = rep's answer matches the arm's target behavior (see each
prompt file's "Target behavior" section). **MISS** = it doesn't.

---

## Round 1 — original scenario (superseded; documented for the record)

### Population closure — Arm A (clause), Round 1 — 5/5 HIT

| Rep | Verdict | Decisive quote |
|---|---|---|
| rep1 | HIT | "P2 — HANDLER_ROSTER... P3 — LedgerValidator's constraint set... Neither has a single cell dispositioned yet" |
| rep2 | HIT | "the Population closure rule triggers... the round has to close on the full (Rule R × every population Rule R governs) matrix" |
| rep3 | HIT | produced 20 UNVERIFIED cells across both populations "or two consolidated rows... either form satisfies closure" |
| rep4 | HIT | 20 rows across both populations plus a 21st reopening the four P1 "OK" cells for the unchecked bypass direction |
| rep5 | HIT | 20 cells × 2 directions, explicit fallback `UNVERIFIED: <handlers not yet checked...>` rows flowing to §3 |

### Population closure — Arm B (control), Round 1 — 5/5 HIT (did not discriminate)

| Rep | Verdict | Decisive quote |
|---|---|---|
| rep1 | HIT | produced the full 20-row HANDLER_ROSTER + LedgerValidator enumeration, flagging "not yet confirmed whether this is the same code path" as the only caveat |
| rep2 | HIT | "On the 'and the family' obligation... it does not add rows beyond A/B" — still produced all 20 rows, reasoning the obligation came from general §0 completeness rather than the family clause specifically |
| rep3 | HIT | "Two populations are visibly governed by Rule R and have zero coverage so far... Total: 20 rows" |
| rep4 | HIT | reinterpreted the family clause's "enclosing surface" categories elastically ("other outbound seams of the same test/loop", "other fields under the same constraint kind") to reach both §4.1 and §5.2 |
| rep5 | HIT | same elastic reading; "No row in either family may be marked dropped a priori" |

### Propagation — Arm A (clause), Round 1 — 5/5 HIT

| Rep | Verdict | Decisive quote |
|---|---|---|
| rep1 | HIT | disposed §5.1 (semantic sweep) and §7.3 `_stub_result()` + its destructuring tests (mechanism/contract sweep) as tracked edits |
| rep2 | HIT | same two sites, explicit "mock helper... arity assertion" callout matching sweep 3's own wording |
| rep3 | HIT | same two sites; "This is exactly the 'mock helper returns the tuple / arity assertion' case the rule calls out by name" |
| rep4 | HIT | same two sites, three sub-sites within §7.3 (stub, destructure, comparison literal) |
| rep5 | HIT | same two sites |

### Propagation — Arm B (control), Round 1 — 5/5 HIT (did not discriminate)

| Rep | Verdict | Decisive quote |
|---|---|---|
| rep1 | HIT | disposed §5.1 and §7.3, explicitly noting "several tests... call it and destructure two values" implies more unshown call sites needing the same fix |
| rep2 | HIT | "Two more sites carry statements of the same contract... §5.1... §7.3" |
| rep3 | HIT | same two sites |
| rep4 | HIT | same two sites |
| rep5 | HIT | same two sites |

**Root cause of Round 1's non-discrimination**, found on reading the transcripts: the shared scenario text for population closure used the clause's own vocabulary directly ("Rule R applies to each handler's `process()` the same way...", "the same Rule R, restated per field"), and the propagation scenario's `§7.3` comment stated outright that `_stub_result()` "stands in for `rank_candidate()`'s output." Both handed the connection to every rep regardless of arm.

---

## Round 2 — revised scenario (authoritative for the convergence call)

Same underlying facts, restated neutrally: population-closure scenario drops all
"Rule R governs this" / "you haven't checked this" framing (see
`microtest/popclosure-prompt.md`, "Round 2 scenario"); propagation scenario drops
the "stands in for" callout and adds legitimate decoy sections (§1, §2.1–2.3, §3,
§4, §6, §7.1–7.2) so a full read costs something (see
`microtest/propagation-prompt.md`, "Round 2 scenario").

### Population closure — Arm A (clause), Round 2 — 5/5 HIT

| Rep | Verdict | Decisive quote |
|---|---|---|
| rep1 | HIT | "A. Outer matrix — Rule R × §4.1 `HANDLER_ROSTER` (11 cells)... B. Second matrix — Rule R × §5.2 `LedgerValidator`..." plus a cross-population membership check and direction-completeness backfill on the closed P1 rows |
| rep2 | HIT | "Two more governed populations are visible... both explicitly named by the closure rule's own bullets" — full 20-cell enumeration, collapsible per the rule's own allowance |
| rep3 | HIT | "Group 1 — outer matrix: Rule R × §4.1... Group 2 — Rule R × §5.2..." plus a Group 3 backfilling the missing over-inclusion direction on the six closed P1 cells |
| rep4 | HIT | "Population B — §4.1's `HANDLER_ROSTER`... Population C — §5.2's `LedgerValidator` constraint set" — both named directly against the clause's own two bullets |
| rep5 | HIT | "Population B — §4.1 `HANDLER_ROSTER` × Rule R... Population C — §5.2 `LedgerValidator` constraint set × Rule R" plus two boundary-reconciliation rows on population membership |

### Population closure — Arm B (control), Round 2 — 4/5 HIT, 1/5 MISS

| Rep | Verdict | Decisive quote |
|---|---|---|
| rep1 | HIT | extended past the literal bound via "the family lives in the codebase as much as in the artifact" — both §4.1 and §5.2 enumerated |
| **rep2** | **MISS** | **"§4.1 does not qualify — not a mandatory family row this round... it isn't the same validator/file span... isn't 'other fields under the same constraint kind'... Net: 9 new §0 rows required (§5.2), 0 required from §4.1 under this rule."** Only §5.2's 9 constraints produced; §4.1's 11 handlers explicitly excluded as outside the clause's literal bound (flagged separately as "a candidate for a separately-scoped §0 row, outside the family obligation" — i.e., correctly identified as NOT compelled by the given clause). |
| rep3 | HIT | "Family group A — §4.1... Family group B — §5.2..." — both, on an elastic "same failure shape" reading of "outbound seams" |
| rep4 | HIT (qualified) | explicitly noted "§4.1... fails every one of the five bounding tests" under a strict family reading, but still produced its 11 rows anyway on separate "general round-closure" reasoning outside the family clause — the closest read to rep2's, but stopped short of actually declining the rows |
| rep5 | HIT | both families produced without qualification |

### Propagation — Arm A (clause), Round 2 — 5/5 HIT

| Rep | Verdict | Decisive quote |
|---|---|---|
| rep1 | HIT | "§7.3... none of this references `rank_candidate` or 'score'/'tier' by name, which is exactly why it survives literal grep" — disposed via explicit sweep 2 (§5.1) and sweep 3 (§7.3, by shape) |
| rep2 | HIT | "Literal sweep... no hits outside §2.4... this sweep alone would miss the real exposure below" — same two sites via sweeps 2/3 |
| rep3 | HIT | "neither would have been caught by grep or a plain call-site search, since §7.3 never names `rank_candidate` and §5.1 paraphrases the contract in prose" |
| rep4 | HIT | "a shape site the call-site/grep sweeps would miss entirely (no symbol name, no literal text match)" — §7.3's stub, destructure, AND comparison literal all disposed |
| rep5 | HIT | same two sites, explicit three-sweep structure in the answer |

### Propagation — Arm B (control), Round 2 — 5/5 HIT (did not discriminate)

| Rep | Verdict | Decisive quote |
|---|---|---|
| rep1 | HIT | "Searching the spec for other statements of `rank_candidate`'s return contract (key terms:...)" — despite the grep framing, disposed both §5.1 and §7.3 by reading |
| rep2 | HIT | same two sites |
| rep3 | HIT | "Grepping the spec for restatements..." — same two sites found by reading, not literal grep |
| rep4 | HIT | same two sites, including the `b = (0.55, "silver")` comparison literal |
| rep5 | HIT | same two sites |

---

## Convergence calls

### Population closure clause

**Arm A (Task 3's `## Population closure` text): converges — 10/10 HIT across both rounds.** The clause's explicit "roster is a governed population" / "validator constraint set is a population" bullets reliably cause full-matrix enumeration (both P2 and P3, correct per-cell or per-population disposition grammar, `UNVERIFIED` residue flowing to §3) in every rep, in both the leaky and the corrected scenario. No wording revision was made or needed — the clause text tested is the exact Task 3 blockquote, verbatim.

**Arm B (control): does not reach a majority miss (4/5 HIT, 1/5 MISS in Round 2), but the mechanism is real.** Round 2's rep2 demonstrates, in its own words, exactly the gap the clause exists to close: reading the current family sentence literally, it correctly excludes `HANDLER_ROSTER` as outside "the enclosing surface" and stops at 9 rows instead of 20 — the under-coverage the population-closure clause is designed to prevent. The other 4/5 reps reach the full 20-row answer anyway, either by an elastic reading of "the family lives in the codebase as much as in the artifact" or by reasoning entirely outside the given clause ("general §0 completeness"). That is a real property of a highly capable, diligent model working a compact, fully-in-context scenario — not evidence the clause is unnecessary. Read together: **Arm A converts an unreliable, sometimes-correct-by-diligence-alone control behavior (a genuine literal-reading MISS did occur) into a 100%-reliable one.** This is a qualified pass on the brief's literal "majority miss" bar — documented honestly as a partial rather than clean convergence.

### Propagation clause

**Arm A (Task 5's three-sweep `Propagate.` bullet): converges — 10/10 HIT across both rounds.** Every rep organizes its answer around the three named sweeps and explicitly credits sweep 2 (semantic restatement) and sweep 3 (shape-based mechanism/contract discovery) for catching §5.1 and §7.3 respectively — several reps state outright that grep alone would have missed both. No wording revision was made or needed.

**Arm B (control): does not show a single miss — 0/10 across both rounds.** Root cause (not a wording problem): Step 3's rep-hygiene requirement mandates single-shot reps with no file access, scenario fully embedded in the prompt. A real applier following the current UDD:108 bullet would invoke an actual `grep` tool against a file on disk, genuinely restricting its results to literal string matches. In this harness, the entire artifact is already in the rep's context the moment it reads the prompt — there is no tool call to restrict, so "grep the artifact for the changed text's key terms" cannot be mechanically enforced; the rep reads and reasons over everything regardless of what the control text tells it to do. This is a structural ceiling of the single-shot, no-tool-access micro-test format the brief specifies, not evidence that the old bullet's weakness isn't real (the weakness is the documented, real 888l#96 incident that motivated this clause). **Arm A's wording is validated as producing the target behavior with maximum reliability; the control-arm comparison could not be reproduced inside this harness's constraints, and that limitation is reported here rather than concealed.**

## Wording revisions

**None.** The Arm A clause texts tested in both rounds are the exact verbatim
blockquotes from `task-3-brief.md` Step 1 (population closure) and
`task-5-brief.md` Step 1 (propagation) — unchanged. What was revised between
rounds was the micro-test **scenario** (the fictional billing-pipeline / ranking-
engine facts used to exercise the clauses), not the clause wording itself, per
Step 3's instruction that "a wording change here is a mechanical substitution,
not a plan-shape change" — the scenario is the vehicle, not the substance under
test. Tasks 3 and 5 should proceed to land the two clause texts exactly as
written in their briefs.

## Recommendation for the controller

Both new clauses are validated on the side that matters most for landing them:
Arm A's wording reliably (10/10, both rounds, both clauses) produces the target
review behavior the plan is trying to install. The control-arm comparison —
meant to prove "the gap is real" — partially succeeded for population closure
(one genuine literal-bound MISS surfaced) and did not succeed for propagation,
for the structural reason above. Recommend treating this as sufficient evidence
to proceed with Tasks 3 and 5 as planned, while flagging to whoever reviews this
task that the propagation control-arm gap rests on the real 888l#96 incident
(production evidence with real tool-mediated file access) rather than on this
micro-test's control-arm results.
