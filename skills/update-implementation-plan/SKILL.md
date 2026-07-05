---
name: update-implementation-plan
description: Use when a critical-implementation-review v2 output exists and the implementation plan needs to be revised to address its findings. Takes one or more CIR v2 review file paths as arguments. Processes each finding sequentially with user approval. Commits pre-state and post-state when the plan is in a git repo. Empty review = no edits made.
version: 2.1.0
---

# Update Implementation Plan

## Overview

Apply the findings from one or more `critical-implementation-review` v2 outputs to the implementation plan they reviewed, in place. Each finding is processed individually with user approval. The skill commits the pre-state (when in a git repo) before overwriting and the post-state after. Empty input is a valid input — no findings → no edits → no commits.

## Process

1. Read each review file in `review_files` (passed as argument; ask user if not provided). Detect format by two markers, BOTH required: (a) the `**Plan:** <path>` header in the file's preamble, and (b) at least one of: `## 1. Verified-plan-assumptions cross-check`, `## 2. Literal-wrongness findings`, `## 3. Forced decisions`, `## 5. Recommendation`. Section names alone are NOT sufficient — CDR v2 output shares three of the four headers; the `**Plan:**` header is what distinguishes CIR output from its siblings. If either marker is absent, refuse with the verbatim message in the "Input contract" section.

2. From each accepted review, extract: plan path (parse `**Plan:** <path>` from header; bare path expected per CIR v2 emission practice — defensive backtick-stripping is YAGNI per evidence), §1 items classified as "still holds", "failed (with new evidence at file:line)", or — when the review's §1 carries a span check (emitted by CIR v2.1.0+) — "uncovered dependency" (own dispatch; see the finding-category table), §2 findings, §3 forced decisions `{the choice / why it's forced / the options}`, §4 history (skip), §5 recommendation label (✅/⚠️/🛑). §0 (Coverage enumeration, emitted by CIR v2.1.0+): skip if present — reviewer bookkeeping, not findings.

3. Read the plan file once. Read codebase files cited by either the plan or the reviews on demand to ground fixes in real context.

4. **Forced-decisions gate.** If any review's recommendation is 🛑 "Surface forced decisions to user", process §3 BEFORE §1/§2. For each §3 item:
   - Present "the choice / why it's forced / the options" to the user verbatim.
   - If options are clearly enumerable (a/b/c, bullet list), ask the user to pick one.
   - If options are inline prose and not clearly enumerable, ask the user to clarify what the available picks are, then ask for the pick.
   - Apply the picked option to the plan text in memory: **TRACK it as a (find-string, replace-string) tuple, exactly as step 5 does.** §3 resolutions ARE tracked changes — they flow through steps 7–9 with everything else; a §3-only run still writes to disk and commits.
   - The user's option pick IS the approval — do not run step 5's `Apply this fix?` gate on §3 items.
   - **You never pick.** §3's whole purpose is that the user decides.

   Do not proceed to §1/§2 processing until all §3 items are resolved.

5. **Process remaining findings in this order:**
   - §1 failed verified-plan-assumptions (high priority — plan rests on falsified ground)
   - §1 uncovered dependencies from the span check, if the review has them (see the finding-category table)
   - §2 literal-wrongness findings

   For each finding:
   - **Restate the finding** — quote or directly reference the relevant part of the review.
   - **Read the plan section it touches.** Ground the fix in cited codebase evidence.
   - **Propose the smallest fix that resolves the finding.** No scope expansion. No adjacent improvements. No prose polishing of unrelated content. No "while we're here" additions. No pattern sweep across the plan for instances the review didn't cite.
   - **End with:** `Apply this fix? (yes / no / modify)` — wait for the user.
   - **On approve: TRACK the change. Do NOT call the Edit or Write tool yet.** Note the (find-string, replace-string) for the plan text in your conversation context. All disk writes are deferred to step 9 — this guarantees step 8's snapshot operates on the unmodified plan. **For §1-failure updates, the find-string is the entire current row from the plan's `Verified plan-level assumptions` table; the replace-string is the row with the corrected fact.** Track as a separate (find-string, replace-string) tuple alongside the body fix.

6. **§4 (Previously addressed) findings:** skip. No action needed.

7. **No-op short-circuit.** If no changes were tracked in steps 4–5 (0 forced decisions applied AND 0 fixes approved — all rejected, or empty review): skip steps 8-9 entirely. Output the summary in step 10 with `Pre-state SHA: N/A. Post-state SHA: unchanged.` Do NOT take any git side effects when nothing is pending. The user invoked the skill, the skill ran, no work needed doing — that's a valid clean result.

8. **Snapshot guarantee** — only reached if step 7's no-op short-circuit didn't fire (i.e., ≥1 change is tracked). The disk plan is still in its pre-edit state at this point. BEFORE applying the tracked changes:

   a. Run `git -C <plan-dir> rev-parse --is-inside-work-tree` to determine if the plan lives in a git repo.
   b. **If in git repo:**
      - Run `git -C <plan-dir> status --porcelain <plan>`.
      - If output is empty → plan is clean and committed. Proceed.
      - If non-empty → plan has uncommitted changes. Auto-commit pre-state with this message:
        ```
        snapshot before update-implementation-plan applies N fixes from <review basenames>
        ```
        Scope the commit to the plan alone — `git commit -m "<message>" -- <plan>` — never a bare `git commit`: unrelated files someone else left staged or dirty in the repo must not be swept into the snapshot.
   c. **If NOT in git repo:**
      - Warn: `Plan at <path> is not in a git repository. Overwrite will be destructive (no recoverable history).`
      - Ask: `Proceed / save .bak copy alongside / abort` — wait for user.
      - If user picks save .bak: write `<plan>.pre-update.bak` (single suffix; overwrites previous .bak if any).
      - If user picks abort: stop the skill; report what would have been applied.

9. **Apply tracked changes; commit post-state:**
   a. NOW apply all changes you tracked in step 5 to the plan at its original path. Use the Edit tool for each tracked (find-string, replace-string) tuple, OR use Write with the full cumulative content if there are many changes — either is acceptable, pick whichever is less error-prone for the change set. No `_v2` filename suffix. No version bump in the plan. No appended Changelog. No "Last updated" marker.
   b. **If in git repo:** auto-commit post-state with this message:
      ```
      applied N fixes from <review basenames> to <plan basename>
      ```
      Scoped to the plan alone (`git commit -m "<message>" -- <plan>`), same as the pre-state snapshot.

10. **Output one-line summary:**
    ```
    Applied N fixes (M rejected, K forced decisions resolved). Plan at <path>.
    Pre-state SHA: <sha or N/A>. Post-state SHA: <sha or unchanged>.
    ```
    N counts every applied edit, §3-driven ones included; K says how many of those resolved forced decisions; M counts rejected findings. Use the singular ("1 fix") when N=1, in both the summary and the commit messages. Pre-state SHA is the snapshot commit when step 8 created one, the pre-existing HEAD when the plan was already clean, and `N/A` only on the step-7 no-op path.

### Multi-review constraint

If multiple review files are passed and they do NOT all carry the same `**Plan:**` value, error with:

> `Multi-review invocation requires all reviews to target the same plan. Found N distinct plan paths: <list>. Invoke separately per plan.`

Single-plan invocation is the supported case.

## Input contract

### Acceptance check (Step 1)

Read each review file at the path the user provides. Look for these markers indicating it's a CIR v2 output — BOTH required:

- At least one of these section headers (case-sensitive substring match): `## 1. Verified-plan-assumptions cross-check`, `## 2. Literal-wrongness findings`, `## 3. Forced decisions`, `## 5. Recommendation`
- The `**Plan:** <path>` header in the file's preamble

If either is absent, **reject** with this exact message shape:

> "Input does not appear to be CIR v2 output. This skill only accepts critical-implementation-review v2.0.0+ reviews. Re-run `critical-implementation-review` (v2.0.0+) on the plan first. If you have a CIR v1.6.0 review file, its section structure ('Critical Issues' / 'Minor Issues & Improvements') was structurally over-engineering-prone and was replaced — re-run with v2 first. If you have a critical-security-review output, address those findings in code, not through this skill — critical-security-review v2 is code-only by design. If the file carries a `**Spec:**` header, it is critical-design-review output — use `update-design-doc` for it instead."

No silent translation. No best-effort fallback for CIR v1.6.0 reviews, critical-security-review v1.0.0 outputs, or hand-written review-shaped notes.

### Empty-section handling

CIR v2 omits §1 entirely when the source plan's `Verified plan-level assumptions` table was empty. UIP v2's parser handles this by skipping §1 processing when the section is absent — not a rejection condition. Same for §2/§3/§4 if empty/omitted.

### Plan-path discovery

CIR v2's output preamble emits `**Plan:** <absolute path>`. UIP v2's parser extracts this header value as the plan path. Bare-path emission is the observed practice; defensive backtick-stripping is YAGNI per evidence (no backticks observed; no consumer reports of failure).

### What UIP v2 trusts vs. verifies

- **Trusts** (does NOT re-verify): the review's classifications themselves. CIR v2's §1 says "still holds" → UIP v2 takes that at face value. CIR v2's §2 says "literal-wrongness at file:line X" → UIP v2 reads the cited evidence to ground the fix, but doesn't re-question whether it's actually wrong (that's CIR's job; doing it twice violates the trust boundary).
- **Reads on demand**: codebase files cited by the review or referenced by the plan's tasks — to ground each fix in real context.
- **Newly authored**: the (find-string, replace-string) tuples that transcribe the upstream-proposed fix into the plan text.

## Out of scope for this skill

- **Producing a new plan** is `thorough-writing-plans`'s job (or upstream `superpowers:writing-plans`).
- **Reviewing the plan** is `critical-implementation-review`'s job.
- **Auditing security** is `critical-security-review`'s job — and security findings are code-level, not plan-level (file:line + code snippets + before/after code patches). This skill does NOT consume critical-security-review output. If you have critical-security-review findings, address them in code (critical-security-review v2 is code-only by design; a future `update-code-from-critical-security-review` skill may exist eventually but does not exist today). Surfacing them through this skill creates either silent drops or scope-confused plan docs.
- **CIR v1.6.0 reviews** are not supported. CIR v1.6.0's section structure (Critical Issues / Minor Issues & Improvements / Questions for Clarification) was structurally over-engineering-prone and was replaced in CIR v2. Re-run the review with CIR v2 first.
- **"Improving" the plan for clarity, voice, or "senior engineering quality"** beyond what the findings require is out of scope. There is no "Holistic Upgrade" pass. There is no "scan for any remaining weak/unclear/risky areas" pass. There is no `H1/H2/H3` finding class.
- **Pattern sweep across the plan** for instances the review didn't cite is out of scope. The review is the contract; if it missed something, surface back to the user as a hint to re-run CIR; don't fold in silently.
- **Touching code referenced by the plan** is out of scope. This skill modifies the plan only.

## Reviewer-equivalent mindset

You are not a Senior Engineer. You are not graded on completeness of revision. Your job is to address each finding the upstream review surfaced, faithfully, with the smallest fix that resolves it. Empty review input → no edits made → still a valid output. You are not playing a role; the discipline emerges from this skill's constraints, not from a persona.

## Ruthless YAGNI when applying fixes

Each fix must be the smallest change that addresses the finding. Specifically forbidden:

- Expanding the fix to "improve adjacent code while we're here"
- Polishing prose that didn't need polishing
- Adding "missing" sections (Risks, Implementation Notes, Future Work, Tradeoffs Discussed) the user never asked for
- Documenting edge cases the upstream review didn't surface
- "Implementation improvements" that weren't proposed inline by the §2 finding
- Adding a Changelog, version field, "Last updated" marker, or any other metadata accumulation
- **Pattern sweep across the plan** for instances the review didn't cite — the review IS the contract; if it missed something, surface back to user as hint to re-run CIR, don't fold in silently

The discipline is the same as `thorough-brainstorming`'s: every line you add must justify itself against the upstream finding. If a candidate edit doesn't resolve a specific finding, drop it.

## Finding-category dispatch

| CIR v2 section | Action |
|---|---|
| §0 coverage enumeration (CIR v2.1.0+) | Reviewer bookkeeping. Skip. Never process a §0 row — including `dropped` candidates — as a finding; findings live only in §1–§3. |
| §1 verified-plan-assumptions cross-check (Still holds) | No action. Don't surface. |
| §1 verified-plan-assumptions cross-check (failed) | High-priority §2-equivalent. Update the plan's `Verified plan-level assumptions` table to reflect the corrected fact (find-string = entire current row; replace-string = updated row), plus the plan changes the failure forces (separate (find-string, replace-string) tuple in the plan body). |
| §1 span check: uncovered dependency (CIR v2.1.0+) | Distinct class — neither "still holds" nor "failed". Present each to the user with the reviewer's evidence. If it can be verified now (read the cited evidence), propose adding a covering row to the plan's `Verified plan-level assumptions` table — the per-fix gate applies. If it can't, put the choice to the user (verify empirically / accept the risk and leave it uncovered / re-run CIR). Never silently drop an uncovered dependency. |
| §2 literal-wrongness | Standard finding processing (per-finding gate, smallest-fix). |
| §3 forced decisions | Special: present options, user picks, apply. Process before §1/§2 if recommendation is 🛑. |
| §4 previously addressed (history) | Skip. |
| §5 recommendation | Inform behavior (🛑 vs ⚠️ vs ✅), don't process as a finding. |

## Anti-patterns

- DON'T invent findings beyond what the upstream review surfaced. There is no "Holistic Upgrade" step. There is no `H1/H2/H3` finding class.
- DON'T propose implementation alternatives the upstream review didn't propose.
- DON'T expand fix scope to "improve adjacent code while we're here."
- DON'T pattern-sweep the plan for instances the review didn't cite.
- DON'T pick for the user on a §3 forced decision.
- DON'T apply §1/§2 fixes before §3 forced decisions are resolved (when recommendation is 🛑).
- DON'T silently strip the plan's `Verified plan-level assumptions` table. If a §1-failed-finding invalidates an assumption, update that table row explicitly.
- DON'T bump the plan version. DON'T append a Changelog. DON'T add a "Last updated" marker.
- DON'T accept critical-security-review output as input — security findings are code-level.
- DON'T accept CIR v1.6.0 output as input — re-run with CIR v2 first.
- DON'T skip the snapshot gate before overwriting.
- DON'T overwrite the plan when no fixes were applied (no-op write is wrong).
- DON'T play "Senior Staff Engineer" or any other expert-role framing.
- DON'T touch code referenced by the plan — modify the plan only.

## Rationalization table

These thoughts mean STOP — you're rationalizing your way into producing speculation:

| Thought | Reality |
|---|---|
| "I should also clean up adjacent plan prose while editing this section." | Out of scope. The fix is the fix. Drop. |
| "I'll add an inline citation/reference to the cited evidence so future readers understand the fix." | The fix is the fix as the review proposed it. If the review's proposed-fix text included the citation verbatim, include it. If it didn't, don't add it. Inline cross-references to other code = scope addition. |
| "The user will appreciate it if I tighten the writing throughout." | They didn't ask. A fix that changes the plan's voice without addressing a finding is scope creep. Drop. |
| "This finding is borderline / probably already addressed." | State the evidence to the user; let them decide whether to skip. Don't silently drop. |
| "The §3 forced decision has an obvious right answer." | The whole reason it's §3 is that the codebase or product constraints force a choice the plan hasn't picked. The user picks. You don't. |
| "Now that I'm rewriting this section, I should also document edge cases." | If the edge case isn't a finding, it's not in scope. Drop. |
| "The user might want to know about a future migration risk / API contract evolution / deployment consideration." | Speculation about a future the user hasn't asked about. Drop. |
| "I should add a 'Last updated' / 'Changelog' / version field for traceability." | No. Git history (when present) does this. The user picked the no-ceremony default. |
| "The fix changes the plan's shape; I should re-verify all the plan's assumptions." | Re-verify only the assumptions the failed §1-finding touches. Surface to the user; do not silently re-verify others. |
| "The user has critical-security-review output and wants me to apply it through this skill." | This skill doesn't accept critical-security-review input. Tell the user; recommend code-level remediation (critical-security-review v2 is code-only by design). Do not fold security findings into the plan. |
| "The plan is in a git repo and clean — I'll skip the post-state commit since 'nothing important happened'." | If at least one fix was applied, the post-state commit IS the audit trail. Always commit when in git AND changes were made. |
| "Empty review means I should at least scan for issues to demonstrate the skill ran." | Empty review = valid output = no work done. Demonstration-by-fabrication is the failure mode this skill exists to prevent. |
| "The review didn't propose an implementation alternative, but the §2 fix would clearly benefit from one — I'll propose it." | Alternatives belong in the §2 finding's proposed-fix prose (per CIR v2's design). If CIR v2 didn't propose one, don't invent one. |
| "I noticed the upstream review missed a real issue — let me address it too while I'm here." | The review is the contract. If the review missed something, surface it back to the user as a hint to re-run CIR; don't fold it into this update silently. |
| "The plan's `Verified plan-level assumptions` table is outdated; let me also re-verify the ones the review didn't fail." | Re-verify only the assumptions a failed §1-finding touches. Other assumptions are CIR's job, not yours. |
| "I should also pattern-sweep the plan for similar issues — the review only cited examples." | UIP v1.1.0 had a 'pattern sweep' instruction; v2 explicitly drops it. The review IS the contract. If a class of issue exists beyond what the review cited, surface back to user as a hint to re-run CIR — don't fold in silently. |
| "The span-check item is unverified and proposes no fix — nothing for me to apply, skip it." | Uncovered dependencies are the span check's entire output. Present each to the user; ratchet verified ones into the `Verified plan-level assumptions` table; put unverifiable ones to the user as a choice. A silent drop here defeats the check one skill downstream of where it ran. |
