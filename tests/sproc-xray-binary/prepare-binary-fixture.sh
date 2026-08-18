#!/usr/bin/env bash
# Builds the rep-facing copy of a binary-DB-file fixture corpus (`binonly1` or `mixed1`)
# with the corpus's `README.md` (the answer key) excluded entirely.
#
# Why: each corpus README records the embedded/parsed routine names — the ground truth
# grep -a recovers from `sample_db.mdf`, and for mixed1, the ground truth parsed from the
# `.sql` files — plus the expected report behavior. A rep that can see that file can
# transcribe the answer instead of computing it from the corpus alone — the same instrument
# failure as method leakage in the prompt (see tests/sproc-planning/prepare-rep-fixture.sh,
# Ruling 14, and tests/sproc-planning-dbonly/prepare-dbonly-fixture.sh, which this script
# mirrors). As with those scripts, the ENTIRE README is the answer key here (unlike
# tests/sproc-metrics/prepare-rep-fixture.sh, which truncates only a `## Ground truth`
# section), so this script excludes the file wholesale.
#
# Both corpora (binonly1: routines ONLY in the binary; mixed1: routines in .sql AND
# additional routines only in the binary) must be built with this same script, or the two
# arms of the eventual RED/GREEN comparison differ in fixture-preparation mechanics and the
# comparison the harness exists to make is confounded.
#
# Usage:  prepare-binary-fixture.sh <corpus-name> <destination-dir>
#         <corpus-name> is "binonly1" or "mixed1".
#         Creates <destination-dir>/<corpus-name> containing the corpus's rep-safe source
#         files (sample_db.mdf, and for mixed1 also the .sql files) and prints its absolute
#         path on stdout — that path is {FIXTURE_PATH} in rep-prompt-template.md.
#
# Idempotent: an existing <destination-dir>/<corpus-name> is removed and rebuilt from the
# committed source. The committed fixture (including its README.md) is never modified.
#
# NOTE (Ruling 14 — REP-ISOLATION, see tests/sproc-planning/planner-rep-prompt-template.md):
# this script only controls the COPY'S CONTENTS (excludes README.md). It does not, and
# cannot, control where <destination-dir> itself lives — that is the caller's responsibility.
# Per REP-ISOLATION requirement 1, the caller must pass a neutral sandbox path that does not
# encode this checkout (not a path shaped like the default per-session scratch dir, which
# embeds the working directory's name) — otherwise a rep can identify and wander into the
# real repository regardless of what this script excludes.
#
# Fails loudly (exit 1) rather than ever handing a rep a copy that contains README.md.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ "$#" -ne 2 ]; then
  echo "usage: $(basename "$0") <corpus-name: binonly1|mixed1> <destination-dir>" >&2
  exit 2
fi

CORPUS="$1"

case "$CORPUS" in
  binonly1|mixed1) ;;
  *)
    echo "FATAL: unknown corpus '$CORPUS' — must be 'binonly1' or 'mixed1'." >&2
    exit 2
    ;;
esac

SRC="$SCRIPT_DIR/$CORPUS"

[ -d "$SRC" ] || { echo "FATAL: source fixture not found: $SRC" >&2; exit 1; }
[ -f "$SRC/sample_db.mdf" ] || { echo "FATAL: sample_db.mdf not found: $SRC/sample_db.mdf" >&2; exit 1; }
[ -f "$SRC/README.md" ] || { echo "FATAL: fixture README not found: $SRC/README.md (nothing to exclude — fixture shape has changed)" >&2; exit 1; }

mkdir -p "$2"
DEST="$(cd "$2" && pwd)/$CORPUS"

# The next step is `rm -rf "$DEST"`. If the destination resolves to the committed fixture
# itself — which it does for `<repo>/tests/sproc-xray-binary`, or for `.` when the caller's
# cwd is that directory — that rm would DELETE THE FROZEN FIXTURE. Compare resolved paths
# and refuse. This is the one failure mode of this script that is not recoverable by
# re-running it.
if [ "$DEST" = "$SRC" ]; then
  echo "FATAL: destination resolves to the committed fixture itself ($SRC)." >&2
  echo "       Refusing to delete the frozen fixture. Pass a scratch directory, not the" >&2
  echo "       tests/sproc-xray-binary directory (and note the destination gets a /$CORPUS suffix)." >&2
  exit 1
fi

rm -rf "$DEST"
mkdir -p "$DEST"

# Copy only the rep-safe artifacts by name — an allowlist, not a denylist, so a future file
# added to the corpus (another answer-key note, a scratch file) does not leak by default.
cp "$SRC/sample_db.mdf" "$DEST/sample_db.mdf"

if [ "$CORPUS" = "mixed1" ]; then
  shopt -s nullglob
  sql_files=("$SRC"/*.sql)
  shopt -u nullglob
  if [ "${#sql_files[@]}" -eq 0 ]; then
    echo "FATAL: mixed1 fixture has no .sql files — fixture shape has changed." >&2
    exit 1
  fi
  for f in "${sql_files[@]}"; do
    cp "$f" "$DEST/$(basename "$f")"
  done
fi

# Verify the copy really excludes the README before reporting success.
if [ -e "$DEST/README.md" ]; then
  echo "FATAL: README.md present in $DEST after build — answer key would leak to the rep." >&2
  exit 1
fi
if [ ! -f "$DEST/sample_db.mdf" ]; then
  echo "FATAL: rep-facing copy is missing sample_db.mdf after build." >&2
  exit 1
fi
if [ "$CORPUS" = "mixed1" ] && [ -z "$(find "$DEST" -maxdepth 1 -name '*.sql' -print -quit)" ]; then
  echo "FATAL: rep-facing mixed1 copy is missing its .sql files after build." >&2
  exit 1
fi

echo "$DEST"
