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

## [2.2.0] — 2026-07-05

**Targets Superpowers 6.0.x**

### Changed

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
