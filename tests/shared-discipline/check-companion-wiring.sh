#!/usr/bin/env bash
# Guards the CDR/CIR shared-review-discipline companion wiring:
# the companion must exist, and both SKILL.mds must instruct reading it.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
COMPANION="skills/critical-design-review/shared-review-discipline.md"
[ -f "$COMPANION" ] || { echo "ERROR: $COMPANION missing" >&2; exit 1; }
grep -q 'shared-review-discipline\.md' skills/critical-design-review/SKILL.md \
  || { echo "ERROR: CDR SKILL.md does not reference the companion" >&2; exit 1; }
grep -q 'critical-design-review/shared-review-discipline\.md' skills/critical-implementation-review/SKILL.md \
  || { echo "ERROR: CIR SKILL.md does not reference the companion (with its cross-skill path)" >&2; exit 1; }
# The companion must keep its core sections (renames here break both skills' references)
for h in "Evidence tiers" "Negative claims require empirical evidence" "Proposed fixes and §3 options are claims too" "Shared reviewer rationalization table"; do
  grep -q "$h" "$COMPANION" || { echo "ERROR: companion lost section: $h" >&2; exit 1; }
done
echo "shared-discipline wiring OK"
