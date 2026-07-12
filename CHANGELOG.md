# Changelog

All notable changes to Peter's Agentic Toolkit are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The toolkit is versioned **independently** of Superpowers — its version number
reflects toolkit changes, not the Superpowers release it builds on. Each entry
below states the Superpowers version that release targets.

## Release checklist

When cutting a new version, update in lockstep:

1. `.claude-plugin/plugin.json` → `version`
2. A new entry in this file (date, what changed, Superpowers target)
3. The README version line (and the install-requirement line if compatibility changed)
4. A new `git tag vX.Y.Z`
5. Regenerate `tests/provenance/companion-manifest.sha256` (and its `# target:` line) if the visual-companion files were re-synced to a new Superpowers target

## [2.3.0] — 2026-07-12

**Targets Superpowers 6.0.x–6.1.x** (verified against 6.1.1)

### Added
- CDR 2.3.0 / CIR 2.2.0: evidence-tier ladder for §0 dispositions; family recurrence sweep at first hit; proposed-fix evidence standard (`UNVERIFIED:` tag). CIR additionally: negative-claims section (ported from CDR, plan-prose adaptations); "Run what is runnable".
- UDD 2.2.0 / UIP 2.2.0: verify new load-bearing claims in review fixes before applying; propagation of the applied fix's changed terms (UIP's blanket no-pattern-sweep scoped to defects, five sites); evidence ratchet into Verified assumptions. UIP trusts-boundary carve-out (classification vs prescription).

Motivated by the 888l review-loop retrospective (23 late findings across 6 features: evidence-tier shallowness, fix-induced defects, finish-the-surface under-generalization).

## [2.2.2] — 2026-07-05

**Targets Superpowers 6.0.x–6.1.x** (verified against 6.1.1)

### Fixed

- Vendor-neutral todo phrasing completed across the remaining four skills — `arch-review` → 2.0.1, `critical-implementation-review` → 2.1.1, `resume-handoff`, `tma` → 2.0.1 (was "TodoWrite", a tool name current harnesses no longer expose; same factual-correction class as 2.2.1's TB/TWP edits, closing the pass queued there). Repo-wide grep now clean.

### Changed

- `create-handoff` → 2.1.0: **no longer stages the handoff file** (`git add` removed from Step 4). Staging without committing left foreign files armed in the index indefinitely — observed live: four staged-never-committed handoffs sat in a real repo's index for 7 weeks and were genuinely swept into an unrelated snapshot commit by a bare `git commit` during the UDD/UIP audit's baseline trials (the hazard UDD/UIP 2.1.0 mitigated consumer-side; this removes the producer-side root cause). Handoffs are session-local by design (matching observed user practice: gitignored in one repo, never committed in another); the acknowledgment now says so. Also: Environment template gains a `Stashes:` line — Step 1 always gathered `git stash list` but the template never recorded it.
- `resume-handoff` → 2.0.2: fidelity report's stash line now compares against the handoff's recorded `Stashes:` field instead of asserting "new stash entries since handoff" with no recorded baseline (graceful when older handoffs lack the field); Environment validation row updated to match.

## [2.2.1] — 2026-07-05

**Targets Superpowers 6.0.x–6.1.x** (verified against 6.1.1)

### Fixed

- `thorough-brainstorming` → 2.1.1: process-flow diagram now matches the checklist on commit placement — the diagram showed a single commit at the terminal node while checklist item 9 commits at the write step (and the write node is re-entered, with commit, on self-review fixes and user-requested changes).
- `thorough-writing-plans` → 2.1.1: removed the stale "UIP currently appends one (transitional gap; UIP v2 will drop it)" Changelog cross-ref — false since UIP 2.1.0, which forbids appending a Changelog. Same stale-ref class as the CDR/CIR fixes in 2.2.0.
- Both: vendor-neutral todo phrasing (was "TodoWrite", a tool name current harnesses no longer expose; matches upstream Superpowers 6.x's deliberate vendor-neutral convention).
- `thorough-writing-plans`: the emitted plan's "For agentic workers" header block synced byte-identical to upstream Superpowers 6.x (`REQUIRED SUB-SKILL`, `executing-plans` fallback for subagent-less harnesses, "task-by-task") — the 2.1.0 W1 sync had shipped a simplified SDD-only variant; found by the TWP↔consumers audit.

### Audit note

- Full `thorough-brainstorming` ↔ consumers contract audit (TWP acceptance, CDR §1 ground-truth/fresh-read, UDD ratchet target, decomposition path). Three statically-suspected defects did NOT reproduce in blind baseline trials (7/7 reps complied: spec heading/evidence always detectable by both consumers' detectors; plan-as-spec rejected under user pressure; post-review edits committed unprompted), so no guidance edits were made for them per the no-failing-test rule. Remaining TodoWrite references in `arch-review` / `critical-implementation-review` / `resume-handoff` / `tma` are noted for a future pass.

## [2.2.0] — 2026-07-05

**Targets Superpowers 6.0.x–6.1.x** (verified against 6.1.1, released 2026-07-02: the v6.0.3→v6.1.1 delta leaves every skill the toolkit depends on — `subagent-driven-development`, `writing-plans`, `brainstorming` SKILL.md, `requesting-code-review`, `using-git-worktrees`, `writing-skills` process content — byte-identical or cosmetically edited (dead-link/Gemini-CLI-line removals only); remaining changes are the `using-superpowers` bootstrap trim, Gemini CLI removal, and Codex packaging)

### Changed

- Added recall machinery to the CDR/CIR family, closing a structural recall gap diagnosed across two independent instances (a false-negative parsing defect that survived 3 review rounds; a spec whose 5 findings dripped one-per-round across 5 rounds, all discoverable from round 1). The family prompt was all precision machinery (drop-it tables, "empty is valid") with no search procedure — reviews halted at the first defensible finding.
- `critical-design-review` → 2.2.0: new "Coverage before candidates" enumeration sweep (§0 of the review output — sections, rules-and-operands in both failure directions, data-flow arrows with persistence-boundary flagging); §1 span check (name design dependencies with no covering assumption); rule-over-input-class claims added to the empirical-evidence recipe (check false positives AND false negatives against real data); input-cleanliness claims named as negative claims (with the corporate-first-party worked example); anti-anchor rule for iterative rounds (build the enumeration before reading prior reviews); new rationalization rows and anti-patterns guarding the sweep's integrity.
- `critical-implementation-review` → 2.1.0: same family device adapted to plans — §0 enumeration over tasks × surfaces (step prose, code blocks, commands, wiring text) plus cross-task interface contracts (Consumes/Produces pairs, fixture handoffs, persistence-boundary flags); §1 span check extended to the "Inherited from spec" list; the static/dynamic mode-switch generalized through §0; matching rationalization rows and anti-patterns.
- Precision posture unchanged by design: the sweep drives candidate *generation* only; every candidate still passes the literal-wrongness gate, §0 is bookkeeping (not a fifth finding category), and dropped candidates are recorded with reasons, never promoted. Device validated in three live trials before landing (zero noise findings across all three) and gated on two pre-fix regression reproductions before merge.
- `update-design-doc` → 2.1.0 and `update-implementation-plan` → 2.1.0: correctness and alignment fixes from a full UDD/UIP↔CDR/CIR audit, each defect confirmed by blind baseline trials on synthetic fixtures before the fix was written:
  - Forced-decision-only runs (§3 items, empty §2) now explicitly persist: §3 resolutions are tracked changes flowing through the snapshot/apply/commit steps; the no-op short-circuit is scoped to "steps 4–5", not "step 5" (baseline agents documented that the literal text let the user's applied decisions silently never reach disk).
  - Pre-state and post-state auto-commits are pathspec-scoped to the spec/plan file — a baseline trial's plain `git commit` really did sweep an unrelated pre-staged file into the snapshot commit.
  - Acceptance checks now require BOTH the `**Spec:**`/`**Plan:**` header AND the section-header markers; CDR and CIR share three of four section names, so each updater previously accepted its sibling's output on the literal check (survival depended on agent judgment). Refusal messages now name the sibling skill.
  - `update-design-doc` gains the multi-review same-spec constraint (mirroring UIP's same-plan rule): a baseline trial batch-edited two different specs in one run with one combined commit.
  - 🚧 "Spec needs decomposition" now has defined behavior in `update-design-doc`: a decomposition gate — surface to the user, ask proceed-anyway vs back-to-brainstorming, don't process findings without the pick (previously "given no defined behavior anywhere in the skill", per baseline).
  - Forward-compatible dispatch for the CDR 2.2.0 / CIR 2.1.0 output contract (inert against stock reviews): §0 Coverage enumeration is skipped as reviewer bookkeeping (a `dropped` row is never a finding), and §1 span-check "uncovered dependency" items get their own class — present to the user, ratchet verified ones into the spec's `Verified assumptions` section / plan's assumptions table, put unverifiable ones to the user as a choice; never silently drop (baseline: the item "fits neither bucket" of the still-holds/failed classifier and evaporated).
  - Summary/commit-message clarifications observed as ambiguities in every baseline: N counts §3-driven edits (K flags them), singular "1 fix", and pre-state SHA semantics when the doc was already clean.

## [2.1.0] — 2026-06-30

**Targets Superpowers 6.0.x**

### Changed

- Retargeted from Superpowers 5.1.x to 6.0.x (W1: plan-format blocks, W2: visual-companion sync + security fix)
- Fixed README overclaims: clarified that the Toolkit invokes `subagent-driven-development` directly and reaches `requesting-code-review` / `using-git-worktrees` transitively through it, not by direct calls (W4)
- Softened README intro prose to match actual usage pattern (W4)
- Repositioned `critical-security-review` as optional and post-implementation (usually post-SDD), rather than mandatory and part of the pipeline (W3)
- Updated plan-format blocks in `thorough-writing-plans` and `critical-implementation-review` to match Superpowers 6.0.x conventions (W1)

### Security

- Fixed `critical-security-review` to use Superpowers' `code-review` skill without passing `--no-auth` (W2)

### Added

- Provenance and lockstep tests to verify version/target/format consistency across plugin.json / README / CHANGELOG (W5)

## [2.0.0] — 2026-06-27

First documented release. **Targets Superpowers 5.1.x.**

### Added

- This changelog and a version line in the README, so the toolkit's version and
  its Superpowers compatibility are discoverable rather than buried in the plugin
  manifest.

### Notes

- Adopted independent SemVer for the toolkit, with Superpowers compatibility
  stated separately in prose rather than encoded into the version number.
