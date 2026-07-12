---
name: critical-design-review
description: Use when reviewing a design spec produced by thorough-brainstorming, before the design is implemented. Use for adversarial design review, second-opinion on a finalized spec, or finding issues in a design before they become bugs. Multiple iterative passes supported.
version: 2.3.0
---

# Critical Design Review

## Overview

Adversarially review a design spec — typically produced by `thorough-brainstorming` — to surface things the design will literally break on and forced decisions the spec hasn't picked. Empty output is a valid result; this skill exists to find real problems, not to demonstrate value.

## Input contract

Invoked with a path to a design spec. The skill imposes no rigid section structure on the spec — designs scale to their complexity (per `thorough-brainstorming`), so a 5-line endpoint design is as legitimate as a multi-component architectural design. The one structural element this skill cares about is the spec's `Verified assumptions` section. See below.

## Out of scope for this skill

Comprehensive security review is the `critical-security-review` skill's job. CDR catches security issues only when they fail the literal-wrongness test against the spec's stated outcome (e.g., a SQL injection in the design's own query). For threat modeling, authn/authz audit, dependency CVE checks, or trust-boundary analysis, run `critical-security-review` separately. Do not use CDR's literal-wrongness section as a back door for security findings the user didn't ask for.

Implementation-level concerns (race conditions in called primitives, error-path swallowing, integration edge cases that depend on the actual implementation) are `critical-implementation-review`'s job, after a plan is written.

## Soft requirement: `Verified assumptions` section

**Detection:** case-insensitive substring match for `verified assumptions` in any header line of the spec body (lines starting with `#`).

| Situation | Behavior |
|---|---|
| Spec has a `Verified assumptions` section | Treat each item as ground truth. Do NOT re-question those facts. §1 of the output (verified-assumptions cross-check) becomes a fresh-read sanity check against the cited evidence — not a re-litigation. |
| Spec has no `Verified assumptions` section | Proceed with the review. Emit a top-of-output warning: `⚠️ This spec lacks a 'Verified assumptions' section. Reviewer cannot distinguish verified facts from unverified assumptions; treat findings accordingly.` Skip §1 of the output entirely. |

## Reviewer mindset

Your job is to find the things in this spec that would literally break the user's stated outcome. You are not paid by the issue. An empty review is a valid output. Your job is correctness-defense, not value-demonstration.

You are not playing a role. You are not a Senior Principal Architect. You are not graded on issues-found per review. The discipline emerges from the constraints in this skill — the literal-wrongness test, the bounded finding categories, the explicit delegation of security and implementation concerns to other skills — not from a persona.

## Coverage before candidates (the enumeration sweep)

Precision machinery tells you what to drop; it does not tell you where to look. Before generating any candidate finding, enumerate the review surface as a checkable list — this becomes §0 of your output:

1. **Sections:** one row per section of the spec (by header), including sections that look settled or boilerplate. Late sections get the same depth of read as early ones.
2. **Rules and operands:** one row per rule the design defines over inputs (matching, comparison, extraction, filtering, routing). For each: name every operand it touches (both sides of any comparison; key-side AND app-side; first party AND second party), and check BOTH failure directions — over-inclusion (claims/matches something it shouldn't) and under-inclusion (silently misses something it should catch). A rule that treats two structurally-similar operands differently is a mandatory row: test the operand the spec assumes is clean against real data; never accept "it's clean" by assertion. Two sub-rules are mandatory rows of their own:
   - **Identity and exclusion rules** — cache keys, dedup keys, self-match exclusion, anything that decides whether two records are "the same thing." Check over-merge (distinct entities conflated: same-name siblings, same-caption successors, same-title revisions) and under-merge, against the real data's identity structure. "The values are calibrated later" does not cover these: calibration sets *values* (thresholds, counts, wording); it cannot repair *mechanics* — a key that conflates two distinct entities, an exclusion that references a field the record doesn't carry, is wrong at every threshold.
   - **Eligibility predicates** — for any scope test over a status or type ("all confirmed results", "case-law entries", "verified records"), enumerate every PRODUCER of that status/type in the code (grep the constructors/assignment sites that emit it) — one row per producer, checking the predicate's assumptions against what that producer actually populates. The input classes are defined by what the code can produce, not by the paths the spec happens to name; the producer the spec didn't mention is the classic unhandled input class.
3. **Data-flow arrows:** one row per arrow, and an arrow ends at an **operation** — an API call, a computation, a comparison, a render — not at a stage name. For each consuming operation: list the parameters it requires, and trace each one back to a field that exists in the artifact the operation's stage actually reads. "The data reaches the stage" is not the check; "every parameter of the operation exists in what the stage received" is. Flag every arrow that crosses a persistence/serialization boundary (write-then-read of JSON/DB/file artifacts): the in-memory shape and the persisted shape are different objects — dump a real record's key set and check against it, don't reason from the in-memory type of the same concept. A single design concept ("a verified record") silently splitting into two incompatible shapes across a write-to-disk is a recurring real-failure class; so is a downstream operation whose required parameter exists nowhere in the artifact its stage enumerates from. An operation with more than one caller gets **one row per call site**, not one per operation — each caller sources the operation's parameters from its own artifacts, and verifying sourcing once "for the operation" hides the caller whose inputs come from somewhere else. The canonical instance: an eval/spike-side replica of a runtime call — same operation, but its parameters come from persisted artifacts that may lack fields the runtime path holds in memory.

Work through the enumeration; give every row a disposition — one line for non-load-bearing rows, the evidence-tier ladder below for load-bearing ones: `ok — <what you checked>`, `→ §2/§3` (became a finding), or `dropped — <reason>` (candidate generated, failed the literal-wrongness test). Two disciplines on the rows themselves:

- **Proportionality:** the sweep scales with the artifact — a five-line spec gets a three-row sweep, not a template's worth of rows. §0 is a search discipline, not a form to fill; padding it with rows that check nothing is the same fabricated coverage as an unexamined `ok`.
- **Finish the surface:** a row that yields a finding is not thereby disposed. Before moving on, check the surface's remaining named identifiers — types, functions, exceptions, fixtures, columns — against the codebase. A found defect marks where the scan continues, not where it stops; the second phantom identifier in a block routinely hides behind the first. **And the family:** a confirmed finding additionally obligates a recurrence sweep — enumerate the structurally similar siblings of the defective instance and check each for the same failure shape, bounded to the enclosing surface: the remaining checks in the same validator/file span, the sibling tests in the same module, the other outbound seams of the same test, the other fields under the same constraint kind, the sentences that follow in the same spec/plan paragraph. The family lives in the codebase as much as in the artifact. Record it as one §0 row per family member, or one row naming the family with a per-member disposition.

### Evidence tiers: the disposition must match the claim class

An `ok` disposition is only as strong as the evidence named in it. For
**load-bearing rows** — any row whose failure would be a §1 or §2
finding — the named check must meet the tier its claim class requires.
Paste the decisive evidence into the row (the actual key list, the
actual count, the command run); an evidence tier asserted but not shown
is fabricated coverage.

| Claim class | Minimum evidence | Never sufficient |
|---|---|---|
| Totality/coverage over a population ("the join holds", "every X maps", "all keys parse") | Run the rule over the full real population it will see, or inspect both the covered set and the residual set | One sampled instance generalized to the class (n=1 "spot check") |
| Field present in a persisted artifact | Dump a real record's key set and cite the keys | Schema docstrings, Pydantic models, or the in-memory type of the same concept |
| Field absent from a persisted artifact | A dump of a record that **reached the state that populates the field** (stratify by status before sampling) | Absence in a record that never reached the populating state (a stuck run proves nothing about completed ones) |
| Artifact–consumer compatibility ("the harness consumes these files") | Push at least one real artifact through the consuming operation or its validator | Existence/count evidence — "67 files on disk" discharges "67 files exist", never "these files load" |
| Bidirectional completeness ("every X is Y" mappings, span checks, listed↔required correspondences) | Both directions checked, each direction's disposition named in the row | A one-direction pass |

Existence-level evidence discharges existence-level claims only. A
load-bearing row that can't meet its tier in-round is not `ok`: upgrade
the evidence, or surface it as a §3 forced decision (verify empirically /
accept the risk / defer) — the "When grep can't verify" rule generalizes
to evidence tiers. Non-load-bearing rows keep their one-line check;
the ladder does not license padding.

The sweep drives candidate **generation only**. §0 is bookkeeping, not a fifth finding category — findings live only in §1–§4, and every candidate still passes the literal-wrongness test before it may appear in §2. A `dropped` row must never be promoted to a finding to justify the sweep's cost. Empty §2 remains a valid output — but only after the surface is covered. "I found one real issue" is not a reason to stop; "every §0 row has a disposition and this is all that's wrong" is.

## Ruthless YAGNI for reviewers

A "good" review surfaces only what the user needs to know to make a good decision **about what they asked for**. It does not enumerate every adjacent improvement opportunity, every architectural concern that didn't make the spec, every hypothetical future scaling cliff. Treat additions to your review the way `thorough-brainstorming` treats additions to a design: every line must justify itself.

Specifically forbidden:

- Findings about scalability / extensibility / maintainability without a literal-wrongness justification
- Findings about features the spec didn't include — the spec's scope is the user's, not yours
- "We could also" / "we should also" / "it would be better to" framings
- Best-practice-as-correctness ("industry standard is X")
- Quota-driven critique ("I should find at least N issues to be useful")
- Re-raising items the verified-assumptions section already settled
- Security findings that don't fail the literal-wrongness test — those are critical-security-review's job
- "Adjacent FYIs" the user might find interesting — there is no FYI section

If a candidate finding doesn't fit one of the four finding categories below, drop it. There is no "miscellaneous notes" section. There is no "minor improvements" section. There is no "questions for clarification" section. There is no "out-of-scope findings" section. Empty is a valid output.

## The literal-wrongness test

Apply this to every candidate finding before it appears in §2 of the output:

> **Would the asked-for behavior be literally wrong, broken, or impossible without addressing this?**

If yes → §2.
If "this might be problematic," "best practice is," "to be safe," "the user might later want," or "industry standard is" — the finding is speculation. Drop it. Do NOT route it to a different section to keep it alive.

The asked-for behavior includes the explicit and the immediately-implied — but be honest about which is which. "The spec adopts `requireSession`" does not by itself imply "401 for unauth callers" — it implies whatever `requireSession` actually does on the unauth path. If the spec explicitly says "401 expected on unauth," then 401-on-unauth is the asked-for behavior; if it doesn't, then "throws on unauth" is the asked-for behavior. Don't smuggle in a strong reading of "implied" to manufacture a literal-wrongness finding.

When the asked-for behavior depends on a primitive the design calls, and the primitive is broken in a way that breaks the asked-for behavior — that's §2. The fact that the bug lives in another file does not move the finding out of §2. Conversely, a primitive that is broken in ways that *don't* affect the asked-for behavior is not a CDR finding at all (critical-security-review may catch it; CDR does not).

### Worked examples

| Candidate finding | Literal-wrongness test | Verdict |
|---|---|---|
| "Endpoint lacks `Cache-Control: no-store` even though it returns user PII" | Without it, does the asked-for behavior fail? The asked-for response is `{userId, email}`. Whatever caching might happen doesn't change the response the caller receives. | Speculation. Drop. |
| "Endpoint should validate that `req.params.id` is numeric before querying" | Without it, does the asked-for behavior fail? The DB driver parameterizes the query; non-numeric `id` returns 0 rows → already 404 by design. The asked-for behavior is unchanged. | Speculation. Drop. |
| "The session cookie is forgeable, so the endpoint can return any user's record" | Without addressing this, does the asked-for behavior (`return THE caller's record`) fail? The endpoint correctly returns the cookie's user's record. The forgery makes the authn trust model wrong, not the design wrong. | Drop from CDR. Goes to critical-security-review. |
| "Endpoint references `requireSession` but `requireSession` throws raw `Error`, which Express does not turn into 401" | Without addressing this, does the asked-for behavior work? Only if the spec actually says 401 is expected. If the spec says "throws on unauth" matching what the primitive does, that's the asked-for behavior and it works. | Depends on the spec. If spec asserts 401 → §2. If spec just says "throws on unauth" → not literal-wrongness; drop. |

## Negative claims require empirical evidence

A **negative claim** asserts that something does NOT happen — "consumer X doesn't access internals of Y", "symbol Z has no callers", "feature F is unused", "module M doesn't depend on N". Spec authors often cite negative claims as the reason a deletion or change is safe ("we can delete Y because nothing depends on it"). When a negative claim is **load-bearing for the spec's safety**, you MUST treat it as a §2 candidate UNLESS you have grep evidence against the specific symbol whose absence is being claimed. A negative claim accepted on faith is the most common way a CDR misses a real literal-wrongness finding.

### Verification recipe

| Claim shape | Grep target | Hit means |
|---|---|---|
| "Consumer X doesn't access [internal/private/protected] members of provider Y" | The **specific internal symbol names** declared in Y — especially type names (`internal interface Foo`, `internal class Bar`) — grep'd in X's source. Not the public API around them. | Claim is FALSE → §2 finding. |
| "Symbol Z is unused" / "Z has no callers" | `\bZ\b` across the codebase, excluding Z's own declaration site. | Any non-self hit → claim FALSE → §2. |
| "Feature/flag F is dead" | `\bF\b` and any documented aliases / configuration keys. | Hit → claim FALSE → §2. |
| "Module M has no external dependents" | Imports / `require` / project references / `using` statements naming M, across the codebase. | Hit → claim FALSE → §2. |
| "Rule R produces correct output on all inputs of class C" (incl. recovery/coverage-rate claims: "recover the 180", "handles all variants") | Run R — or hand-trace it — over the real corpus/data it will see. Inspect BOTH the matched/covered set (spurious hits) AND the unmatched/residual set (silent misses). | Either failure direction on real data → §2. |

### Critical pitfall — grep the right symbol

"X uses only public API `foo()`" is NOT sufficient evidence that "X doesn't access internal type `T`". Public methods can return internal types; field declarations, parameter types, local-variable types, and base-class declarations all require the type itself to be accessible. **If T is the access-controlled symbol, grep X for `\bT\b` — not for the public method that happens to return T.**

Worked example (real failure that motivated this section):
- **Spec claim:** "Deleting `[InternalsVisibleTo(\"Enrichers.GlobalExecutionId\")]` is safe — that enricher uses only the public LibLog API."
- **Wrong verification:** grep `LogProvider` in `GlobalExecutionId/`. Hit found — looks like a public-API call. Conclude: claim verified.
- **Right verification:** grep `\bILog\b` in `GlobalExecutionId/`. Four hits: `private readonly ILog _logger = LogProvider.For<...>();`. The field type `ILog` is internal. Removing the IVT breaks compilation in 4 files.
- **Verdict:** the public-API call returns an internal type; the consumer's field type leaks the access requirement; the claim is false; this is a §2 finding.

### Input-cleanliness claims are negative claims

"X is just the party name", "this field never carries suffixes", "input class C needs no special handling" — each asserts an absence of structure in an input. When a rule's correctness rests on one, it is load-bearing; test it against the real corpus, in both failure directions. Real failure that motivated this: a citation matcher extracted a first-party surname as "the last content token before `v.`"; the spec asserted the text before `v.` "is just the party name." Real corpus anchors had corporate parties — `Air Safety, Inc. v. …` extracts `inc.`, `Trammell Crow Co. No. 60 v. …` extracts `60` — so every corporate-first-party citation silently failed to match: a false-negative miss on the operand assumed clean. Three review rounds hunted over-inclusion only and accepted the cleanliness assertion without a corpus test; the enumeration sweep's both-directions rule plus this section exists so round 1 catches it.

### When grep can't verify

If access happens through reflection, dynamic dispatch, code generation, runtime DI registration, string-based lookup, or any mechanism that hides symbol references from grep — the negative claim is unverifiable at design-review time. Do NOT bless it as "probably fine." Surface as a §3 forced decision: "Verify empirically by attempting the change and observing the toolchain's response; defer the change if it fails." The user can then decide whether to spike-test now or accept the risk.

### When the claim is incidental, not load-bearing

The literal-wrongness test still applies. A throwaway "this isn't used elsewhere" remark in spec prose is NOT a CDR concern. An explicit "this is safe to delete because nothing depends on it" IS. The trigger is whether the spec's safety argument rests on the negative claim.

## The four finding categories

These are the only categories that exist. There is no "miscellaneous." Each requires a *specific kind* of finding; none has a "fill this in" prompt.

| # | Category | What goes here | Output if empty |
|---|---|---|---|
| 1 | Verified-assumptions cross-check | For each item in the spec's `Verified assumptions` section: does it still hold under a fresh read of the cited evidence? Then the **span check**: name any design dependency with no covering assumption — a fact the design needs that no listed item verifies, as scoped. Ground-truth status attaches to each listed item as written, not to the gaps between items; a mis-scoped assumption ("citations are enumerable" verified, "enumerated records carry the probe's inputs" never stated) hides in exactly that gap. Bounded: one line per uncovered dependency; verify it in-round with read evidence, or — when it can't be verified — surface it as a §3 forced decision (the "When grep can't verify" rule applies to span gaps too: verify empirically / accept the risk / defer). An unverifiable dependency never stays a §1-only note — that would let §5 read ✅ over an unverified load-bearing fact. Don't re-litigate listed items. Skip the whole section only if it is absent from the spec (with a warning at the top of the review). | "All verified assumptions reconfirmed; span check found no uncovered dependency" |
| 2 | Literal-wrongness findings | Each candidate must pass the literal-wrongness test above. Per item: description / evidence (file:line or behavior) / proposed fix. | "No literal-wrongness findings." |
| 3 | Forced decisions | Real either/or the spec leaves unpicked, where a codebase or product constraint forces a choice the spec hasn't named. Reviewer surfaces the choice; never picks. Per item: the choice / why it's forced / the options. | "No forced decisions found." |
| 4 | Previously addressed (history) | Only present if prior reviews exist. Brief bullets on items from the review history that have been resolved by the spec's current state. | Section omitted entirely. |

**Notably absent from v2:**

- No "Out-of-scope findings" section. Anything that's not §2 (literal-wrongness), not §3 (forced decision), and not §4 (history) is noise; drop. Security goes to critical-security-review; implementation concerns go to critical-implementation-review.
- No "Alternative Architectural Challenge" section. If a §2 finding has a different architecture as its proposed fix, propose it inline within §2. Do not invent alternatives without a §2 finding to attach them to.
- No "Minor Issues & Improvements" section.
- No "Architectural Soundness" mandate (modularity / scalability / extensibility / maintainability). Replaced by the literal-wrongness test.
- No "Questions for Clarification" section. If something is a real either/or the spec hasn't picked, it's a §3 forced decision. If it's speculation about intent, drop it.

## Proposed fixes are claims too

A §2 finding's proposed fix is reviewer-authored artifact text: the
update skill applies it, often verbatim. A proposed fix that introduces a
new load-bearing claim — names a function or signature, asserts a
property of the data or corpus, claims an instrument capability, or
asserts parity/safety "by construction" — must carry the same evidence
this skill demands of the text it is replacing: grep, dump, signature
read, or run, cited inline in the fix. If the evidence can't be produced
in-round, prefix the fix with `UNVERIFIED:` so the update skill treats it
as a claim to verify before applying, not a fact to transcribe. An
unverified fix applied verbatim is how a review authors the next round's
finding.

## Reviewer rationalization table

These thoughts mean STOP — you're rationalizing your way into producing speculation:

| Thought | Reality |
|---|---|
| "I should propose at least one alternative architecture to be helpful." | Alternatives serve §2 findings. Without a §2 finding, an alternative is forced speculation. Drop. |
| "I notice X could fail at scale" — but scale isn't in the spec. | Scale isn't in the spec because the user didn't ask. Apply the literal-wrongness test against the asked-for outcome. |
| "There's no metrics / observability / audit trail." | Unless the user asked, this is generic over-instrumentation noise. Drop. |
| "We could refactor X for clarity." | Adjacent improvement. Drop. |
| "Best practice would be to add X." | Best-practice ≠ correctness. Apply the literal-wrongness test. |
| "I haven't found anything critical, let me at least surface minor improvements." | Empty is a valid output. Filling categories is over-engineering. There is no "minor improvements" category to fill. |
| "The verified-assumptions section claims X is true, but what if it changes?" | Verified facts are ground truth. "What if it changes" is speculation about a future the user hasn't asked about. |
| "The spec doesn't address [edge case the user didn't mention]." | The spec covers the asked-for path. Edge cases come up during implementation, not in design review. |
| "I should be thorough; quality reviews find at least N issues." | Quota-driven critique. The number of real findings is whatever the design actually has wrong. Often zero. |
| "I'm an experienced architect; I should have an opinion on the tech choices." | The user picked the tech. Opinions on tech choices are noise unless they fail the literal-wrongness test. |
| "The verified-assumptions section says X is true, but I should double-check by re-reasoning." | If you read the cited evidence and it still holds, the assumption is reconfirmed. If the evidence doesn't hold, the assumption fails — that's a §1 finding. Don't double-check via vibes. |
| "This is a small spec — I should find at least one structural concern, otherwise the review looks lazy." | A small spec rests on smaller assumptions, not on weaker ones. If the asked-for behavior doesn't literally fail, there is no concern to surface, regardless of how the review "looks." |
| "I noticed a security issue that doesn't fail literal-wrongness — I'll surface it as an FYI." | Security audit is `critical-security-review`'s job. CDR catches security issues only when they fail the literal-wrongness test against the spec's outcome. Surfacing security FYIs duplicates another skill and is noise here. |
| "I'll surface this as a §3 forced decision so the user has to weigh in." | §3 is for choices the codebase or product constraints actually force. If you're inventing the choice to make the user think about something you find interesting, drop it. |
| "The fix I'm proposing in §2 would also benefit from refactoring adjacent code, so I'll fold that in." | The §2 finding is the finding. The fix is the fix. Don't expand scope to justify additional cleanup. |
| "I need to add 'questions for clarification' so the reviewee knows what to think about." | There is no Questions section. If something is a real either/or the spec hasn't picked, it's a §3 forced decision. If it's speculation about intent, drop it. |
| "The 'asked-for behavior' obviously implies X (where X is something the spec doesn't say)." | Be honest about what the spec actually says vs. what you'd assume in the spec's place. If the spec doesn't say X, X is not part of the asked-for behavior — don't smuggle X in to manufacture a §2 finding. |
| "The spec says consumer X doesn't access internals of Y, so removing the `[InternalsVisibleTo]` / unexporting Y / etc. is safe." | Negative claims are load-bearing when a deletion's safety depends on them. Verify by grep'ing the **specific internal symbol** in X's source — not the public API around it. Public methods can return internal types; field annotations leak access. See "Negative claims require empirical evidence." |
| "I grep'd the consumer for the public API and it's all clean — claim verified." | You grep'd the wrong target. The access-controlled symbol is what matters. Re-grep for the internal type/member name itself. |
| "I have a solid finding already; the rest of the spec is probably fine." | One finding proves the search worked, not that it finished. The sweep isn't done until every §0 row has a disposition. Stopping at the first defensible finding is how a defect survives four rounds one section over. |
| "Enumerating the surface is overhead; I'll spot-check the likely sections." | §0 is part of the output and checkable — a section, rule, or arrow with no row is a visible hole. Spot-checking is exactly how silent-miss (false-negative) defects survive review after review. |
| "This arrow just passes data between stages; no row needed." | Arrows crossing a write-then-read boundary are where in-memory and persisted shapes diverge. One line to confirm the consumer's required fields exist in the shape it actually reads. |
| "The rule's other operand is obviously the same shape; checking one side covers both." | Structurally-similar operands treated differently by a rule is a named smell. Test the assumed-clean side against real data — the miss that motivated this discipline lived on exactly the operand nobody tested. |
| "This mechanism is spike-tunable / experiment-calibrated, so it's out of scope for review." | Calibration sets values — thresholds, counts, wording. It cannot repair mechanics: identity keys, exclusion criteria, input availability. A key that conflates two distinct entities or an exclusion referencing a field the record doesn't carry is wrong at every calibrated value. Mechanics rows stay in the sweep. |
| "The spec names the paths that produce this status, and I verified those." | The predicate matches whatever the CODE can produce, not what the spec lists. Grep the producers of that status/type; a producer the spec didn't name is an unhandled input class waiting in exactly the blind spot the spec's list creates. |
| "The arrow reaches the stage with the right records, so the arrow is ok." | Records arriving is half the check. The stage's operation consumes specific parameters — name them and confirm each exists in the artifact the stage reads. An enumeration step that yields records lacking the fields its own next operation needs is the canonical silent break. |
| "I verified this operation's parameter sourcing at its call site." | At *a* call site. An operation with several callers is sourced several ways — the eval-side replica of a runtime call reads persisted artifacts the runtime path never touches. One row per caller; the caller the spec treats as a copy of another is the one that breaks. |
| "This block already gave me a finding; the rest of it is covered." | A finding disposes a defect, not a surface. The block's remaining named identifiers are unchecked until checked — the second phantom type in a block hides behind the first, and it has survived exactly this rationalization before. |
| "I counted the artifacts, so the row is ok." | Counting proves existence; only the consumer proves compatibility. Push one real record through the consuming operation — 66/67 answer keys once failed a loader whose line number three rounds had cited as evidence. |
| "I checked one case and it matched byte-identically." | n=1 verifies that case, not the class. Totality claims get the full population or both-sets inspection — 19/116 silent join failures lived behind exactly this spot check. |
| "The schema/docstring says the field is there." | The persisted artifact is the operand, not the type. Dump a real record's keys — a field that existed in every docstring and no artifact has survived two rounds this way. |
| "The field wasn't in the records I sampled, so it's absent." | Records that never reached the state that populates the field prove nothing. Sample where the field would be set. |
| "I found the broken check; the rest of that validator is a different concern." | A found check has siblings enforcing the same invariant for other statuses and paths. Inventory the enclosing span — the `partial` twin of a found `success` check sat 30 lines down and cost a full round. |
| "This test's outbound call is mocked; the test's row is done." | One row per outbound seam of the test, not one per test. The unmocked second seam is where the live call escapes. |
| "The fix is my own analysis; it doesn't need the evidence treatment." | Reviewer-authored text bypasses every gate unless this one holds. Four late findings in one retrospective cycle were quoted verbatim from a prior round's proposed fix. |

## Iterative review behavior

- **Re-derive coverage every round.** In round N>1, complete the §0 enumeration sweep BEFORE reading prior reviews; the previous round's fix and its neighbors are single enumeration rows, not the search area. History tells you what's *resolved*, never what's *covered* — an update loop that only re-examines the last diff walks a thread through one section while the rest of the spec goes unread. (Prior-review reading remains mandatory for the never-re-raise rule; it just happens after the enumeration is built.)
- **History awareness.** Read all prior reviews matching `<spec-basename>-critical-review-*.md` in the output directory. Never re-raise an issue already present in any prior review (resolved or not). If a prior issue is now confirmed as still wrong despite previous mention, surface it in §1 (verified-assumptions cross-check) or §2 (literal-wrongness) only if the cited evidence has changed; do not duplicate.
- **Default output location:** `docs/criticalreviews/<spec-basename>-critical-review-N.md`, relative to the repository root. Create the directory if it does not exist. User preference overrides.
- **Numbering:** N is one higher than the highest existing N for that spec basename, or 1 if none. Never overwrite.

## Present the review

After writing the review file, surface a brief summary to the user as terminal text so they can see the findings. The summary is a navigation aid, not a substitute for opening the file.

Format (terminal output; do NOT append to the review file):

```
Critical Design Review written to:
  <path/to/review/file.md>

<icon> <recommendation label>
  §0 Coverage: <N rows — X ok, Y → findings, Z dropped>
  §1 Verified-assumptions cross-check: <X reconfirmed, Y failed, Z uncovered dependencies> | n/a (section missing)
  §2 Literal-wrongness findings: <count>
  §3 Forced decisions: <count>
  §4 Previously addressed: <count> | n/a (first round)
```

The recommendation line uses the icon + label from the bounded taxonomy in `Final recommendation taxonomy` (✅ / ⚠️ / 🛑 / 🚧). Per-section counts are factual — how many bullets the section actually contains. If §1 was skipped because the spec lacked a `Verified assumptions` section, write `n/a (section missing)`. If §4 is omitted because no prior reviews exist, write `n/a (first round)`.

Print the summary. CDR ends after printing it; no further prompts.

## Output format

````markdown
# Critical Design Review: <spec basename> (Round N)

**Spec:** `<absolute path to spec>`
**Verified Assumptions section:** present | MISSING

[If MISSING, immediately after the header:]
> ⚠️ This spec lacks a `Verified assumptions` section. Reviewer cannot distinguish verified facts from unverified assumptions; treat findings accordingly.

## 0. Coverage enumeration
[One row per enumerated item — sections / rules-and-operands (both failure directions) / data-flow arrows (persistence boundaries flagged) — each with its disposition: `ok — <what was checked>` | `→ §2.n` / `→ §3.n` | `dropped — <reason it failed literal-wrongness>`]

## 1. Verified-assumptions cross-check
[Per spec assumption: still holds | failed (with new evidence at file:line)]
[Then span check: uncovered dependencies (one line each) | "span check found no uncovered dependency"]
[If section missing: omit this entire section]

## 2. Literal-wrongness findings
[Per finding: description / evidence (file:line) / proposed fix]
[OR: "No literal-wrongness findings."]

## 3. Forced decisions
[Per item: the choice / why it's forced / the options]
[OR: "No forced decisions found."]

## 4. Previously addressed
[Only if prior reviews exist. Bullets of items from review history now resolved.]

## 5. Recommendation
[One of the four bounded options below]
````

## Final recommendation taxonomy

Bounded set. No generic "Major revisions needed" fallthrough.

- ✅ **Approve as-is** — §2 and §3 are both empty. Spec is ready for implementation planning.
- ⚠️ **Approve with literal-wrongness fixes** — §2 non-empty, §3 empty. User must address §2 items, may proceed afterward.
- 🛑 **Surface forced decisions to user** — §3 non-empty. User input needed before proceeding (regardless of §2 state).
- 🚧 **Spec needs decomposition** — only when the spec genuinely covers multiple independent subsystems. Not a generic catchall for "this needs more work."

Disambiguation:
- §2 and §3 both non-empty → 🛑 (forced decisions block forward progress more strongly than literal-wrongness fixes).

## Anti-patterns

- DON'T propose architectural alternatives without a §2 finding to attach them to.
- DON'T add an "Out-of-scope findings" section, a "Minor Issues" section, a "Questions for Clarification" section, an "FYI" section, or any section not named above. There are four finding categories. There is no fifth.
- DON'T re-raise issues from prior reviews.
- DON'T re-question items in the Verified Assumptions section unless the cited evidence has changed.
- DON'T play "Senior Principal Architect" or any other expert-role framing.
- DON'T fabricate findings to fill empty sections. Empty is a valid output.
- DON'T mark a §0 row `ok` without naming what you checked — an unexamined `ok` is fabricated coverage.
- DON'T promote a §0 `dropped` candidate into §2 to make the sweep look productive — the literal-wrongness gate is unchanged.
- DON'T propose decomposition unless the spec genuinely covers multiple independent subsystems.
- DON'T comment on variable names, micro-optimizations, or low-level implementation details.
- DON'T perform any of the tasks described in the spec itself — only review.
- DON'T surface security findings that don't fail literal-wrongness — those are critical-security-review's job.
- DON'T surface implementation-time edge cases (race conditions in called primitives, integration edge cases) — those are critical-implementation-review's job.
