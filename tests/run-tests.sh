#!/usr/bin/env bash
# Runs every deterministic guard. Hermetic — no Superpowers install or network needed.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
fail=0
echo "== provenance =="; bash "$ROOT/provenance/check-companion-provenance.sh" || fail=1
echo "== lockstep ==";   bash "$ROOT/lockstep/check-version-lockstep.sh"       || fail=1
echo "== shared-discipline =="; bash "$ROOT/shared-discipline/check-companion-wiring.sh" || fail=1
echo "== evidence-slot =="; bash "$ROOT/evidence-slot/check-evidence-slot.sh" || fail=1
echo "== round-completion =="; bash "$ROOT/round-completion/check-round-completion.sh" || fail=1
echo "== sproc-xray-scratch =="; bash "$ROOT/sproc-xray-scratch/check-scratch-isolation.sh" || fail=1
echo "== sproc-xray-loc-contract =="; bash "$ROOT/sproc-xray-loc-contract/check-loc-contract.sh" || fail=1
echo "== bugfix status =="; ( cd "$ROOT/.." && node --test 'skills/bugfix/tests/**/*.test.mjs' ) || fail=1
echo "== tracker-adapter =="; ( cd "$ROOT/.." && node --test 'skills/tracker-adapter/tests/**/*.test.mjs' ) || fail=1
if [ "$fail" -ne 0 ]; then echo "TESTS FAILED" >&2; exit 1; fi
echo "ALL TESTS PASSED"
