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

- Added recall machinery to the CDR/CIR family, closing a structural recall gap diagnosed across two independent instances (a false-negative parsing defect that survived 3 review rounds; a spec whose 5 findings dripped one-per-round across 5 rounds, all discoverable from round 1). The family prompt was all precision machinery (drop-it tables, "empty is valid") with no search procedure — reviews halted at the first defensible finding.
- `critical-design-review` → 2.2.0: new "Coverage before candidates" enumeration sweep (§0 of the review output — sections, rules-and-operands in both failure directions, data-flow arrows with persistence-boundary flagging); §1 span check (name design dependencies with no covering assumption); rule-over-input-class claims added to the empirical-evidence recipe (check false positives AND false negatives against real data); input-cleanliness claims named as negative claims (with the corporate-first-party worked example); anti-anchor rule for iterative rounds (build the enumeration before reading prior reviews); new rationalization rows and anti-patterns guarding the sweep's integrity.
- `critical-implementation-review` → 2.1.0: same family device adapted to plans — §0 enumeration over tasks × surfaces (step prose, code blocks, commands, wiring text) plus cross-task interface contracts (Consumes/Produces pairs, fixture handoffs, persistence-boundary flags); §1 span check extended to the "Inherited from spec" list; the static/dynamic mode-switch generalized through §0; matching rationalization rows and anti-patterns.
- Precision posture unchanged by design: the sweep drives candidate *generation* only; every candidate still passes the literal-wrongness gate, §0 is bookkeeping (not a fifth finding category), and dropped candidates are recorded with reasons, never promoted. Device validated in three live trials before landing (zero noise findings across all three) and gated on two pre-fix regression reproductions before merge.

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
