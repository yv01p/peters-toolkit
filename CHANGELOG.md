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

## [2.0.0] — 2026-06-27

First documented release. **Targets Superpowers 5.1.x.**

### Added

- This changelog and a version line in the README, so the toolkit's version and
  its Superpowers compatibility are discoverable rather than buried in the plugin
  manifest.

### Notes

- Adopted independent SemVer for the toolkit, with Superpowers compatibility
  stated separately in prose rather than encoded into the version number.
