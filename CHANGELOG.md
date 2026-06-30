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
