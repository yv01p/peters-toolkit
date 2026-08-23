#!/usr/bin/env bash
# Hermetic: asserts the round-completion amendments (888l#96) landed in
# skills/. Whitespace-normalizes before matching so a hard-wrapped literal
# still matches (a line-based grep would miss a literal that wraps across
# lines in the rendered markdown).
#
# NOT wired into tests/run-tests.sh yet (Task 2 of the round-completion
# plan) — Task 6 wires it in once the amendments land (Tasks 3-5). Until
# then this script is expected to FAIL against the working tree; see
# tests/round-completion/baseline-results.md for the recorded RED evidence.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
err=0

SHARED="skills/critical-design-review/shared-review-discipline.md"
CDR="skills/critical-design-review/SKILL.md"
CIR="skills/critical-implementation-review/SKILL.md"
UDD="skills/update-design-doc/SKILL.md"
UIP="skills/update-implementation-plan/SKILL.md"

# require FILE LITERAL LABEL -- literal (non-glob) substring match against
# the whitespace-normalized file content.
require() {
  norm="$(tr -s '[:space:]' ' ' < "$ROOT/$1")"
  case "$norm" in
    *"$2"*) : ;;
    *) echo "MISSING $3 in $1: [$2]" >&2; err=1 ;;
  esac
}

# forbid FILE LITERAL LABEL -- fails if the literal IS still present.
forbid() {
  norm="$(tr -s '[:space:]' ' ' < "$ROOT/$1")"
  case "$norm" in
    *"$2"*) echo "STALE $3 still present in $1: [$2]" >&2; err=1 ;;
    *) : ;;
  esac
}

echo "-- assertion 1: shared file carries the Population closure section --"
require "$SHARED" "## Population closure" "population-closure section header"

echo "-- assertion 2: CDR + CIR reference population closure, enclosing-surface bound gone --"
for f in "$CDR" "$CIR"; do
  require "$f" "per the population-closure section in \`shared-review-discipline.md\`" "population-closure family reference"
  forbid  "$f" "bounded to the enclosing surface" "'bounded to the enclosing surface'"
done

echo "-- assertion 3: shared file carries per-direction grammar + class-tag vocabulary --"
for lit in "over: ok — <probe> / under: → §2.1" "[totality]" "[existence]"; do
  require "$SHARED" "$lit" "per-direction/class-tag slot grammar"
done

echo "-- assertion 4: UDD + UIP carry the Propagation: slot + three-sweep enumeration --"
for f in "$UDD" "$UIP"; do
  for lit in "**Propagation** — the enumerated sites from the three sweeps" \
             "1. **Literal:**" "2. **Semantic restatements:**" "3. **Mechanism/contract:**"; do
    require "$f" "$lit" "Propagation slot / three-sweep enumeration"
  done
done

echo "-- assertion 5: CDR + CIR carry the amendment-hunk clause + both anchor forms --"
for f in "$CDR" "$CIR"; do
  for lit in "reviewed at fix-equivalent rigor" \
             "**Artifact HEAD at review:**" \
             "**Artifact anchor at review:** content:"; do
    require "$f" "$lit" "amendment-hunk clause / anchor form"
  done
done

echo "-- assertion 6: CDR + CIR carry the fresh-context dispatch note + slot-grammar audit step --"
for f in "$CDR" "$CIR"; do
  for lit in "Run the review as a fresh-context agent whose context is this skill" "Slot audit:"; do
    require "$f" "$lit" "fresh-context dispatch note / slot-grammar audit step"
  done
done

if [ "$err" -ne 0 ]; then
  echo "ROUND-COMPLETION CHECKS FAILED" >&2
  exit 1
fi
echo "round-completion OK (population closure, slot grammar, propagation, amendment anchoring, slot-grammar audit all present)"
