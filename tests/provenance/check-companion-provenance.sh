#!/usr/bin/env bash
# Hermetic: verifies the forked companion files against a committed snapshot, and
# that no Superpowers path removed in the targeted version has reappeared.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
MANIFEST="tests/provenance/companion-manifest.sha256"

# 1) byte-for-byte provenance of the six companion files (strip the # header first)
grep -v '^#' "$MANIFEST" | grep -vE '^[[:space:]]*$' | sha256sum -c -

# 2) A1 regression: refs to Superpowers paths removed in the targeted version must not reappear
if grep -rnE 'spec-reviewer-prompt|code-quality-reviewer|config/superpowers/worktrees' skills README.md CHANGELOG.md 2>/dev/null; then
  echo "ERROR: a reference to a removed Superpowers path reappeared (see above)." >&2
  exit 1
fi
echo "provenance OK"
