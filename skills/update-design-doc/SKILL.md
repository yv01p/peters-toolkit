---
name: update-design-doc
description: Use when a critical-design-review v2 output exists and the design spec needs to be revised to address its findings. Takes one or more CDR v2 review file paths as arguments. Processes each finding sequentially with user approval. Commits pre-state and post-state when the spec is in a git repo. Empty review = no edits made.
version: 2.0.0
---

# Update Design Document

## Overview

Apply the findings from one or more `critical-design-review` v2 outputs to the design spec they reviewed, in place. Each finding is processed individually with user approval. The skill commits the pre-state (when in a git repo) before overwriting and the post-state after. Empty input is a valid input — no findings → no edits → no commits.

## Input contract

Invoked with one or more paths to CDR v2 review files. If not provided in the invocation, ask the user. The skill auto-discovers the spec path from each review's `**Spec:** <path>` header (path may be backtick-wrapped).

| Input | Source |
|---|---|
| Review file paths | Argument(s) at invocation time |
| Original design spec | Auto-discovered from each review's `**Spec:**` header |
| Codebase files | Read on demand to ground fixes in real context |

## Out of scope for this skill

- **Producing a new design** is `thorough-brainstorming`'s job (or upstream `brainstorming`).
- **Reviewing the design** is `critical-design-review`'s job.
- **Auditing security** is `critical-security-review`'s job — and security findings are code-level, not design-level (file:line + code snippets + before/after code patches). This skill does NOT consume critical-security-review output. If you have critical-security-review findings, address them in code; UIP v2 does not consume critical-security-review output (critical-security-review v2 is code-only by design) — surfacing them through this skill creates either silent drops or scope-confused design docs.
- **CDR v1 reviews** are not supported. CDR v1's section structure (Critical Issues / Minor Issues / Alternative Architectural Challenge) was structurally over-engineering-prone and was replaced in CDR v2. Re-run the review with CDR v2 first. (CDR v1 review files may still exist on disk in legacy locations — these are not supported input.)
- **"Improving" the spec for clarity, voice, or "senior architecture quality"** beyond what the findings require is out of scope. There is no "Holistic Upgrade" pass. There is no "scan for any remaining weak/unclear/risky areas" pass.
- **Touching code referenced by the spec** is out of scope. This skill modifies the spec only.

## Reviewer-equivalent mindset

You are not a Senior Architect. You are not graded on completeness of revision. Your job is to address each finding the upstream review surfaced, faithfully, with the smallest fix that resolves it. Empty review input → no edits made → still a valid output. You are not playing a role; the discipline emerges from this skill's constraints, not from a persona.

## Ruthless YAGNI when applying fixes

Each fix must be the smallest change that addresses the finding. Specifically forbidden:

- Expanding the fix to "improve adjacent code while we're here"
- Polishing prose that didn't need polishing
- Adding "missing" sections (Response contract, Risks, Future considerations) the user never asked for
- Documenting edge cases the upstream review didn't surface
- "Architectural improvements" that weren't proposed inline by the §2 finding
- Adding a Changelog, version field, "Last updated" marker, or any other metadata accumulation

The discipline is the same as `thorough-brainstorming`'s: every line you add must justify itself against the upstream finding. If a candidate edit doesn't resolve a specific finding, drop it.

## Process

1. **Read each review file in `review_files`.** Detect format by header section names. If the review does NOT contain at least one of: `## 1. Verified-assumptions cross-check`, `## 2. Literal-wrongness findings`, `## 3. Forced decisions`, `## 5. Recommendation` — refuse with this exact message:

   > "Input does not appear to be CDR v2 output. This skill only accepts critical-design-review v2.0.0+ reviews. Re-run `critical-design-review` (v2.0.0+) on the spec first. If you have a CDR v1 review file, its findings are not supported — they tend to include speculative noise that v2 explicitly removed."

   Do not attempt to fall back to v1 parsing. Do not fabricate findings.

2. **From each accepted review, extract:**
   - Spec path: parse `**Spec:** <path>` from the header. Strip surrounding backticks if present.
   - §1 items: classify each as "Still holds" (no action) or "failed (with new evidence at file:line)" (high-priority §2-equivalent).
   - §2 findings: list each.
   - §3 forced decisions: list each as `{the choice, why it's forced, the options}`.
   - §4 items: skip (already-resolved history).
   - Recommendation label: ✅ / ⚠️ / 🛑 / 🚧.

3. **Read the spec file once.** Read codebase files cited by either the spec or the reviews on demand to ground fixes in real context.

4. **Forced-decisions gate.** If any review's recommendation is 🛑 "Surface forced decisions to user", process §3 BEFORE §2. For each §3 item:
   - Present "the choice / why it's forced / the options" to the user verbatim.
   - If the options are clearly enumerable (a/b/c, bullet list, etc.), ask the user to pick one.
   - If the options are inline prose and not clearly enumerable, ask the user to clarify what the available picks are, then ask for the pick.
   - Apply the picked option to the spec text in memory.
   - **You never pick.** The whole point of §3 is that the user must decide.

   Do not proceed to §2 processing until all §3 items are resolved.

5. **Process remaining findings in this order:**
   - §1 failed verified-assumptions (high priority — design rests on falsified ground)
   - §2 literal-wrongness findings

   For each finding:
   - **Restate the finding** — quote or directly reference the relevant part of the review.
   - **Read the spec section it touches.** Ground the fix in cited codebase evidence.
   - **Propose the smallest fix that resolves the finding.** No scope expansion. No adjacent improvements. No clarity polishing of unrelated prose. No "while we're here" additions.
   - **End with:** `Apply this fix? (yes / no / modify)` — wait for the user.
   - **On approve: TRACK the change. Do NOT call the Edit or Write tool yet.** Note the (find-string, replace-string) for the spec text in your conversation context. All disk writes are deferred to step 9 — this guarantees step 8's snapshot operates on the unmodified spec. If the fix also invalidates an item in the spec's `Verified assumptions` section, track an update for that item too (match by bold-text key); surface the assumption update to the user as part of the proposal.

6. **§4 (Previously addressed) findings:** skip. No action needed.

7. **No-op short-circuit.** If no changes were tracked in step 5 (0 fixes approved, all rejected, or empty review): skip steps 8-9 entirely. Output the summary in step 10 with `Pre-state SHA: N/A. Post-state SHA: unchanged.` Do NOT take any git side effects when nothing is pending. The user invoked the skill, the skill ran, no work needed doing — that's a valid clean result.

8. **Snapshot guarantee** — only reached if step 7's no-op short-circuit didn't fire (i.e., ≥1 change is tracked). The disk spec is still in its pre-edit state at this point. BEFORE applying the tracked changes:

   a. Run `git -C <spec-dir> rev-parse --is-inside-work-tree` to determine if the spec lives in a git repo.
   b. **If in git repo:**
      - Run `git -C <spec-dir> status --porcelain <spec>`.
      - If output is empty → spec is clean and committed. Proceed.
      - If non-empty → spec has uncommitted changes. Auto-commit pre-state with this message:
        ```
        snapshot before update-design-doc applies N fixes from <review basenames>
        ```
   c. **If NOT in git repo:**
      - Warn: `Spec at <path> is not in a git repository. Overwrite will be destructive (no recoverable history).`
      - Ask: `Proceed / save .bak copy alongside / abort` — wait for user.
      - If user picks save .bak: write `<spec>.pre-update.bak` (single suffix; overwrites previous .bak if any).
      - If user picks abort: stop the skill; report what would have been applied.

9. **Apply tracked changes; commit post-state:**
   a. NOW apply all changes you tracked in step 5 to the spec at its original path. Use the Edit tool for each tracked (find-string, replace-string) tuple, OR use Write with the full cumulative content if there are many changes — either is acceptable, pick whichever is less error-prone for the change set. No `_v2` filename suffix. No version bump in the doc. No appended Changelog.
   b. **If in git repo:** auto-commit post-state with this message:
      ```
      applied N fixes from <review basenames> to <spec basename>
      ```

10. **Output one-line summary:**
    ```
    Applied N fixes (M rejected, K forced decisions resolved). Spec at <path>.
    Pre-state SHA: <sha or N/A>. Post-state SHA: <sha or unchanged>.
    ```

## Finding-category dispatch

| CDR v2 section | Action |
|---|---|
| §1 verified-assumptions cross-check (Still holds) | No action. Don't surface. |
| §1 verified-assumptions cross-check (failed) | High-priority §2-equivalent. Update the spec's `Verified assumptions` section to reflect the corrected fact, plus the design change the failure forces. |
| §2 literal-wrongness | Standard finding processing (per-finding gate, smallest-fix). |
| §3 forced decisions | Special: present options, user picks, apply. Process before §2 if recommendation is 🛑. |
| §4 previously addressed (history) | Skip. |
| §5 recommendation | Inform behavior (🛑 vs ⚠️ vs ✅), don't process as a finding. |

## Anti-patterns

- DON'T invent findings beyond what the upstream review surfaced. There is no "Holistic Upgrade" step. There is no "H1/H2/H3" finding class.
- DON'T propose architectural alternatives the upstream review didn't propose.
- DON'T expand fix scope to "improve adjacent code while we're here."
- DON'T rewrite the spec for stylistic / clarity / "senior architecture" reasons unless a specific finding requires it.
- DON'T pick for the user on a §3 forced decision.
- DON'T apply §2 fixes before §3 forced decisions are resolved (when recommendation is 🛑).
- DON'T silently strip the spec's `Verified assumptions` section. If a §1-failed-finding invalidates an assumption, update that section explicitly.
- DON'T bump the document version. DON'T append a Changelog.
- DON'T accept critical-security-review output as input — security findings are code-level, not design-level.
- DON'T accept CDR v1 output as input — re-run the review with CDR v2 first.
- DON'T skip the snapshot gate before overwriting.
- DON'T overwrite the spec when no fixes were applied (no-op write is wrong).
- DON'T play "Senior Principal Architect" or any other expert-role framing.

## Rationalization table

These thoughts mean STOP — you're rationalizing your way into producing speculation:

| Thought | Reality |
|---|---|
| "I should also clean up adjacent prose while I'm editing this section." | Out of scope. The fix is the fix. Drop. |
| "I'll add an inline citation/reference to the cited evidence so future readers understand the fix." | The fix is the fix as the review proposed it. If the review's proposed-fix text included the citation verbatim, include it. If it didn't, don't add it. Inline cross-references to other code = scope addition. |
| "The user will appreciate it if I tighten the writing throughout." | They didn't ask. A fix that changes the spec's voice without addressing a finding is scope creep. Drop. |
| "This finding is borderline / probably already addressed." | State the evidence to the user; let them decide whether to skip. Don't silently drop. |
| "The §3 forced decision has an obvious right answer." | The whole reason it's §3 is that the codebase or product constraints force a choice the spec hasn't picked. The user picks. You don't. |
| "Now that I'm rewriting this section, I should also document edge cases." | If the edge case isn't a finding, it's not in scope. Drop. |
| "The user might want to know about a future migration risk / BIGINT serialization / API contract evolution." | Speculation about a future the user hasn't asked about. Drop. |
| "I should add a 'Last updated' / 'Changelog' / version field for traceability." | No. Git history (when present) does this. The user picked the no-ceremony default. |
| "The fix changes the design's shape; I should re-verify all the spec's assumptions." | Re-verify only the assumptions the fix touches. Surface to the user; do not silently re-verify others. |
| "The user has critical-security-review output and wants me to apply it through this skill." | This skill doesn't accept critical-security-review input. Tell the user; recommend code-level remediation. Do not fold security findings into the design. |
| "The spec is in a git repo and clean — I'll skip the post-state commit since 'nothing important happened'." | If at least one fix was applied, the post-state commit IS the audit trail. Always commit when in git AND changes were made. |
| "Empty review means I should at least scan for issues to demonstrate the skill ran." | Empty review = valid output = no work done. Demonstration-by-fabrication is the failure mode this skill exists to prevent. |
| "The review didn't propose an architecture alternative, but the §2 fix would clearly benefit from one — I'll propose it." | Alternatives belong in the §2 finding's proposed-fix prose (per CDR v2's design). If CDR v2 didn't propose one, don't invent one. |
| "I noticed the upstream review missed a real issue — let me address it too while I'm here." | The review is the contract. If the review missed something, surface it back to the user as a hint to re-run CDR; don't fold it into this update silently. |
