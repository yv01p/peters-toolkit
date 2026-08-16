#!/usr/bin/env bash
# Hermetic: asserts both UDD and UIP SKILL.md carry the evidence-slot invariants.
# Whitespace-normalizes before matching so a hard-wrapped literal still matches
# (a line-based grep would miss `This line is always present` where §3.1b wraps it).
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
err=0
for f in skills/update-design-doc/SKILL.md skills/update-implementation-plan/SKILL.md; do
  norm="$(tr -s '[:space:]' ' ' < "$ROOT/$f")"
  for lit in "This line is always present" "never place the Evidence line only inside a widget option"; do
    case "$norm" in
      *"$lit"*) : ;;
      *) echo "MISSING evidence-slot invariant in $f: [$lit]" >&2; err=1 ;;
    esac
  done
done
[ "$err" -eq 0 ] || exit 1
echo "evidence-slot OK (both skills carry the slot + rendering invariants)"
