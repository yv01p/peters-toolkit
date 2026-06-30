#!/usr/bin/env bash
# Hermetic: asserts the version marker is identical across plugin.json / README / CHANGELOG,
# the "targets Superpowers X.x" string agrees across README / CHANGELOG, and the provenance
# manifest's recorded target equals it (binds synced files to the declared target).
# Note: no `set -e` — a missing/empty marker should fall through to the explicit
# MISMATCH message and a non-zero exit, not abort opaquely at the extraction line.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

ver_plugin=$(grep -oE '"version"[[:space:]]*:[[:space:]]*"[0-9]+\.[0-9]+\.[0-9]+"' .claude-plugin/plugin.json | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
ver_readme=$(grep -m1 -oE '\*\*Version [0-9]+\.[0-9]+\.[0-9]+\*\*' README.md | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
ver_chlog=$(grep -m1 -oE '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' CHANGELOG.md | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
tgt_readme=$(grep -m1 -oE 'targets Superpowers [0-9]+\.[0-9]+\.x' README.md | grep -oE '[0-9]+\.[0-9]+\.x')
tgt_chlog=$(grep -m1 -oE 'Targets Superpowers [0-9]+\.[0-9]+\.x' CHANGELOG.md | grep -oE '[0-9]+\.[0-9]+\.x')
tgt_manifest=$(grep -m1 -oE '^# target: [0-9]+\.[0-9]+\.x' tests/provenance/companion-manifest.sha256 | grep -oE '[0-9]+\.[0-9]+\.x')

err=0
if ! { [ "$ver_plugin" = "$ver_readme" ] && [ "$ver_readme" = "$ver_chlog" ]; }; then
  echo "VERSION MISMATCH: plugin=$ver_plugin readme=$ver_readme changelog=$ver_chlog" >&2; err=1
fi
if ! { [ "$tgt_readme" = "$tgt_chlog" ] && [ "$tgt_chlog" = "$tgt_manifest" ]; }; then
  echo "TARGET MISMATCH: readme=$tgt_readme changelog=$tgt_chlog manifest=$tgt_manifest" >&2; err=1
fi
[ "$err" -eq 0 ] || exit 1
echo "lockstep OK (version=$ver_plugin, target=$tgt_readme)"
