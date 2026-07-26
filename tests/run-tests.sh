#!/usr/bin/env bash
# Runs every deterministic guard. Hermetic — no Superpowers install or network needed.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
fail=0
echo "== provenance =="; bash "$ROOT/provenance/check-companion-provenance.sh" || fail=1
echo "== lockstep ==";   bash "$ROOT/lockstep/check-version-lockstep.sh"       || fail=1
echo "== bugfix status =="; ( cd "$ROOT/.." && node --test 'skills/bugfix/tests/**/*.test.mjs' ) || fail=1
if [ "$fail" -ne 0 ]; then echo "TESTS FAILED" >&2; exit 1; fi
echo "ALL TESTS PASSED"
