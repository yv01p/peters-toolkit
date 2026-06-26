---
name: critical-design-review
description: Use when reviewing a design spec produced by thorough-brainstorming, before the design is implemented. Use for adversarial design review, second-opinion on a finalized spec, or finding issues in a design before they become bugs. Multiple iterative passes supported.
version: 2.1.0
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

### Critical pitfall — grep the right symbol

"X uses only public API `foo()`" is NOT sufficient evidence that "X doesn't access internal type `T`". Public methods can return internal types; field declarations, parameter types, local-variable types, and base-class declarations all require the type itself to be accessible. **If T is the access-controlled symbol, grep X for `\bT\b` — not for the public method that happens to return T.**

Worked example (real failure that motivated this section):
- **Spec claim:** "Deleting `[InternalsVisibleTo(\"Enrichers.GlobalExecutionId\")]` is safe — that enricher uses only the public LibLog API."
- **Wrong verification:** grep `LogProvider` in `GlobalExecutionId/`. Hit found — looks like a public-API call. Conclude: claim verified.
- **Right verification:** grep `\bILog\b` in `GlobalExecutionId/`. Four hits: `private readonly ILog _logger = LogProvider.For<...>();`. The field type `ILog` is internal. Removing the IVT breaks compilation in 4 files.
- **Verdict:** the public-API call returns an internal type; the consumer's field type leaks the access requirement; the claim is false; this is a §2 finding.

### When grep can't verify

If access happens through reflection, dynamic dispatch, code generation, runtime DI registration, string-based lookup, or any mechanism that hides symbol references from grep — the negative claim is unverifiable at design-review time. Do NOT bless it as "probably fine." Surface as a §3 forced decision: "Verify empirically by attempting the change and observing the toolchain's response; defer the change if it fails." The user can then decide whether to spike-test now or accept the risk.

### When the claim is incidental, not load-bearing

The literal-wrongness test still applies. A throwaway "this isn't used elsewhere" remark in spec prose is NOT a CDR concern. An explicit "this is safe to delete because nothing depends on it" IS. The trigger is whether the spec's safety argument rests on the negative claim.

## The four finding categories

These are the only categories that exist. There is no "miscellaneous." Each requires a *specific kind* of finding; none has a "fill this in" prompt.

| # | Category | What goes here | Output if empty |
|---|---|---|---|
| 1 | Verified-assumptions cross-check | For each item in the spec's `Verified assumptions` section: does it still hold under a fresh read of the cited evidence? Skip entirely if the section is absent (with a warning at the top of the review). | "All verified assumptions reconfirmed" |
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

## Iterative review behavior

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
  §1 Verified-assumptions cross-check: <X reconfirmed, Y failed> | n/a (section missing)
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

## 1. Verified-assumptions cross-check
[Per spec assumption: still holds | failed (with new evidence at file:line)]
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
- DON'T propose decomposition unless the spec genuinely covers multiple independent subsystems.
- DON'T comment on variable names, micro-optimizations, or low-level implementation details.
- DON'T perform any of the tasks described in the spec itself — only review.
- DON'T surface security findings that don't fail literal-wrongness — those are critical-security-review's job.
- DON'T surface implementation-time edge cases (race conditions in called primitives, integration edge cases) — those are critical-implementation-review's job.
