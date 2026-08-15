---
name: critical-design-review
description: Use when reviewing a design spec produced by thorough-brainstorming, before the design is implemented. Use for adversarial design review, second-opinion on a finalized spec, or finding issues in a design before they become bugs. Multiple iterative passes supported.
version: 2.4.0
---

# Critical Design Review

## Overview

Adversarially review a design spec — typically produced by `thorough-brainstorming` — to surface things the design will literally break on and forced decisions the spec hasn't picked. Empty output is a valid result; this skill exists to find real problems, not to demonstrate value.

## Shared discipline (read first)

Read `shared-review-discipline.md` in this skill's directory before building §0.
Its contents are binding for every review this skill produces: reviewer mindset,
the evidence-tier ladder (which binds `ok` rows AND findings), negative-claims
verification, the `Evidence:`-line requirement on §2 fixes and §3 options, and
the shared rationalization table.

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

## Coverage before candidates (the enumeration sweep)

Precision machinery tells you what to drop; it does not tell you where to look. Before generating any candidate finding, enumerate the review surface as a checkable list — this becomes §0 of your output:

1. **Sections:** one row per section of the spec (by header), including sections that look settled or boilerplate. Late sections get the same depth of read as early ones.
2. **Rules and operands:** one row per rule the design defines over inputs (matching, comparison, extraction, filtering, routing). For each: name every operand it touches (both sides of any comparison; key-side AND app-side; first party AND second party), and check BOTH failure directions — over-inclusion (claims/matches something it shouldn't) and under-inclusion (silently misses something it should catch). A rule that treats two structurally-similar operands differently is a mandatory row: test the operand the spec assumes is clean against real data; never accept "it's clean" by assertion. Two sub-rules are mandatory rows of their own:
   - **Identity and exclusion rules** — cache keys, dedup keys, self-match exclusion, anything that decides whether two records are "the same thing." Check over-merge (distinct entities conflated: same-name siblings, same-caption successors, same-title revisions) and under-merge, against the real data's identity structure. "The values are calibrated later" does not cover these: calibration sets *values* (thresholds, counts, wording); it cannot repair *mechanics* — a key that conflates two distinct entities, an exclusion that references a field the record doesn't carry, is wrong at every threshold.
   - **Eligibility predicates** — for any scope test over a status or type ("all confirmed results", "case-law entries", "verified records"), enumerate every PRODUCER of that status/type in the code (grep the constructors/assignment sites that emit it) — one row per producer, checking the predicate's assumptions against what that producer actually populates. The input classes are defined by what the code can produce, not by the paths the spec happens to name; the producer the spec didn't mention is the classic unhandled input class.
3. **Data-flow arrows:** one row per arrow, and an arrow ends at an **operation** — an API call, a computation, a comparison, a render — not at a stage name. For each consuming operation: list the parameters it requires, and trace each one back to a field that exists in the artifact the operation's stage actually reads. "The data reaches the stage" is not the check; "every parameter of the operation exists in what the stage received" is. Flag every arrow that crosses a persistence/serialization boundary (write-then-read of JSON/DB/file artifacts): the in-memory shape and the persisted shape are different objects — dump a real record's key set and check against it, don't reason from the in-memory type of the same concept. A single design concept ("a verified record") silently splitting into two incompatible shapes across a write-to-disk is a recurring real-failure class; so is a downstream operation whose required parameter exists nowhere in the artifact its stage enumerates from. An operation with more than one caller gets **one row per call site**, not one per operation — each caller sources the operation's parameters from its own artifacts, and verifying sourcing once "for the operation" hides the caller whose inputs come from somewhere else. The canonical instance: an eval/spike-side replica of a runtime call — same operation, but its parameters come from persisted artifacts that may lack fields the runtime path holds in memory.

Work through the enumeration; give every row a disposition — one line for non-load-bearing rows, the evidence-tier ladder in `shared-review-discipline.md` for load-bearing ones: `ok — <what you checked>`, `→ §2/§3` (became a finding), or `dropped — <reason>` (candidate generated, failed the literal-wrongness test). Two disciplines on the rows themselves:

- **Proportionality:** the sweep scales with the artifact — a five-line spec gets a three-row sweep, not a template's worth of rows. §0 is a search discipline, not a form to fill; padding it with rows that check nothing is the same fabricated coverage as an unexamined `ok`.
- **Finish the surface:** a row that yields a finding is not thereby disposed. Before moving on, check the surface's remaining named identifiers — types, functions, exceptions, fixtures, columns — against the codebase. A found defect marks where the scan continues, not where it stops; the second phantom identifier in a block routinely hides behind the first. **And the family:** a confirmed finding additionally obligates a recurrence sweep — enumerate the structurally similar siblings of the defective instance and check each for the same failure shape, bounded to the enclosing surface: the remaining checks in the same validator/file span, the sibling tests in the same module, the other outbound seams of the same test, the other fields under the same constraint kind, the sentences that follow in the same spec/plan paragraph. The family lives in the codebase as much as in the artifact. Record it as one §0 row per family member, or one row naming the family with a per-member disposition.

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

## Reviewer rationalization table

The shared table in `shared-review-discipline.md` applies in full. CDR-specific rows:

| Thought | Reality |
|---|---|
| "The spec says consumer X doesn't access internals of Y, so removing the `[InternalsVisibleTo]` / unexporting Y / etc. is safe." | Negative claims are load-bearing when a deletion's safety depends on them. Verify by grep'ing the **specific internal symbol** in X's source — not the public API around it. See "Negative claims require empirical evidence" in the shared file. |
| "I grep'd the consumer for the public API and it's all clean — claim verified." | You grep'd the wrong target. The access-controlled symbol is what matters. Re-grep for the internal type/member name itself. |
| "This arrow just passes data between stages; no row needed." | Arrows crossing a write-then-read boundary are where in-memory and persisted shapes diverge. One line to confirm the consumer's required fields exist in the shape it actually reads. |
| "The rule's other operand is obviously the same shape; checking one side covers both." | Structurally-similar operands treated differently by a rule is a named smell. Test the assumed-clean side against real data. |
| "The arrow reaches the stage with the right records, so the arrow is ok." | Records arriving is half the check. Name the consuming operation's parameters and confirm each exists in the artifact the stage reads. |

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
[Per finding: description / evidence (file:line) / proposed fix / the fix's own `Evidence:` line (or `UNVERIFIED:`)]
[OR: "No literal-wrongness findings."]

## 3. Forced decisions
[Per item: the choice / why it's forced / the options, each ending with its `Evidence:` line (or `UNVERIFIED:`)]
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
