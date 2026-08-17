#!/usr/bin/env bash
# Hermetic: asserts sproc-xray SKILL.md isolates scratch per-run (unique mktemp dir
# entered via cd), anchors the report to the original invocation dir, guards the
# "file wins" rule with a source-consistency check, and cleans up unconditionally.
# Regression guard for beta-test finding #1 (scratch collision). No network / install.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/sproc-xray/SKILL.md"

err=0
need(){ grep -qF "$1" "$SKILL" || { echo "FAIL (missing): $2" >&2; err=1; }; }
absent(){ grep -qF "$1" "$SKILL" && { echo "FAIL (present): $2" >&2; err=1; }; }

# (a) Step 1 captures the original dir, creates a unique scratch dir, and cd's into it
need 'ORIG="$(pwd)"'  'Step 1 must capture the original invocation dir'
need 'mktemp -d'      'Step 1 must create a per-run scratch dir (mktemp -d)'
need 'cd "$WORK"'     'Step 1 must cd into the scratch dir'
grep -qE 'mktemp -d.*cd "\$WORK"' "$SKILL" || { echo "FAIL (missing): Step 1 must create+enter the scratch dir in one command" >&2; err=1; }
# (b) report anchored to the original dir, not the post-cd working dir
need '$ORIG/reports/' 'report must be written under $ORIG'
# (c) source-consistency check gating file-wins
need 'analyzed source set' 'must carry the source-consistency check language'
grep -qiE 'contamination|HALT' "$SKILL" || { echo "FAIL (missing): contamination/HALT gate" >&2; err=1; }
# (d) cleanup unconditional
need 'rm -rf "$WORK"' 'cleanup must rm -rf the scratch dir'
absent 'If the codebase was cloned from a GitHub URL, delete the cloned temp directory' \
       'cleanup must not be gated on GitHub-clone'
# (e) fixed shared scratch path must be gone
absent '/tmp/{repo-name}-xray' 'the fixed /tmp/{repo-name}-xray path must be removed'

if [ "$err" -ne 0 ]; then echo "sproc-xray scratch-isolation: FAIL" >&2; exit 1; fi
echo "sproc-xray scratch-isolation OK"
