#!/usr/bin/env bash
# Hermetic: asserts the per-routine-LOC contract stays in lockstep across the
# sproc-xray producer and the sproc-migration-plan consumer (beta finding #6).
# x-ray must emit LOC in Extraction Metrics; Dim-1 must read it from there, not
# from the drifted Component Manifest LOC column. No network / install.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
XRAY="$ROOT/skills/sproc-xray/SKILL.md"
PLAN="$ROOT/skills/sproc-migration-plan/SKILL.md"

err=0
need(){   grep -qF "$2" "$1" || { echo "FAIL (missing in $(basename "$1")): $3"  >&2; err=1; }; }
absent(){ grep -qF "$2" "$1" && { echo "FAIL (present in $(basename "$1")): $3" >&2; err=1; }; }

# (a) x-ray producer: LOC appended after File in the tsv contract and rendered header
need "$XRAY" 'UDTFlags|File|LOC'          'metrics.tsv contract must append |LOC after File'
need "$XRAY" '| UDT Usage | File | LOC |' 'rendered Extraction Metrics header must end | UDT Usage | File | LOC |'
# (b) planner consumer: Dim-1 fed from Extraction Metrics LOC
need "$PLAN" 'Extraction Metrics LOC'     'Dim-1 must be fed from Extraction Metrics LOC'
# (c) planner consumer: the drifted feed must be gone
absent "$PLAN" 'Component Manifest LOC column' 'Dim-1 must no longer read the Component Manifest LOC column'

if [ "$err" -ne 0 ]; then echo "sproc-xray/plan LOC-contract: FAIL" >&2; exit 1; fi
echo "sproc-xray/plan LOC-contract OK"
