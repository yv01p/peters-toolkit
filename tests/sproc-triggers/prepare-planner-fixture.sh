#!/usr/bin/env bash
# Builds the rep-facing copy of the trgplan1 fixture: the trigger-bearing x-ray report plus
# the synthetic application tree, with `trgplan1/README.md` (the answer key) excluded
# entirely.
#
# Why: trgplan1/README.md records, for both of the corpus's 2 logic units
# (`prc_log_status_change`, `trg_account_status_sync`), whether it is app-called,
# DB-internal-called, or a live DB-internal entry point with no app caller — and the
# Dimension-3 cascade binding the two together. A rep that can see that file can transcribe
# the answer instead of computing it from the report and the app tree — the same instrument
# failure as method leakage in the prompt (see planner-rep-prompt-template.md, Ruling 14).
# As with tests/sproc-planning/prepare-rep-fixture.sh (which this script mirrors), the
# ENTIRE README is the answer key here, so this script excludes the file wholesale, not a
# section of it (contrast tests/sproc-triggers/prepare-xray-fixture.sh, which strips only a
# `## Ground truth` section — that script serves a different fixture shape, Task 1's, where
# the README carries both prose an analyst legitimately reads and a ground-truth section
# that must not leak; here the whole file is scorer-only). BOTH arms of this harness must
# build their fixture with this script; if the arms differ in the fixture itself, the
# comparison the harness exists to make is confounded.
#
# Usage:  prepare-planner-fixture.sh <destination-dir>
#         Creates <destination-dir>/trgplan1 containing TRIGGER-SPROC-XRAY-baseline.md and
#         app/, and prints its absolute path on stdout — that path is {FIXTURE_PATH} in
#         planner-rep-prompt-template.md.
#
# Idempotent: an existing <destination-dir>/trgplan1 is removed and rebuilt from the
# committed source. The committed fixture (including its README.md) is never modified.
#
# NOTE (Ruling 14 — REP-ISOLATION, see planner-rep-prompt-template.md): this script only
# controls the COPY'S CONTENTS (excludes README.md). It does not, and cannot, control where
# <destination-dir> itself lives — that is the caller's responsibility. Per REP-ISOLATION
# requirement 1, the caller must pass a neutral sandbox path that does not encode this
# checkout (not a path shaped like the default per-session scratch dir, which embeds the
# working directory's name) — otherwise a rep can identify and wander into the real
# repository regardless of what this script excludes.
#
# Fails loudly (exit 1) rather than ever handing a rep a copy that contains README.md.
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)/trgplan1"
REPORT_NAME="TRIGGER-SPROC-XRAY-baseline.md"

if [ "$#" -ne 1 ]; then
  echo "usage: $(basename "$0") <destination-dir>" >&2
  exit 2
fi

[ -d "$SRC" ] || { echo "FATAL: source fixture not found: $SRC" >&2; exit 1; }
[ -f "$SRC/$REPORT_NAME" ] || { echo "FATAL: x-ray report not found: $SRC/$REPORT_NAME" >&2; exit 1; }
[ -d "$SRC/app" ] || { echo "FATAL: application tree not found: $SRC/app" >&2; exit 1; }
[ -f "$SRC/README.md" ] || { echo "FATAL: fixture README not found: $SRC/README.md (nothing to exclude — fixture shape has changed)" >&2; exit 1; }

mkdir -p "$1"
DEST="$(cd "$1" && pwd)/trgplan1"

# The next step is `rm -rf "$DEST"`. If the destination resolves to the committed fixture
# itself — which it does for `<repo>/tests/sproc-triggers`, or for `.` when the caller's cwd
# is that directory — that rm would DELETE THE FROZEN FIXTURE. Compare resolved paths and
# refuse. This is the one failure mode of this script that is not recoverable by re-running
# it.
if [ "$DEST" = "$SRC" ]; then
  echo "FATAL: destination resolves to the committed fixture itself ($SRC)." >&2
  echo "       Refusing to delete the frozen fixture. Pass a scratch directory, not the" >&2
  echo "       tests/sproc-triggers directory (and note the destination gets a /trgplan1 suffix)." >&2
  exit 1
fi

rm -rf "$DEST"
mkdir -p "$DEST"

# Copy only the rep-safe artifacts by name — an allowlist, not a denylist, so a future file
# added to trgplan1/ (another answer-key note, a scratch file) does not leak by default.
cp "$SRC/$REPORT_NAME" "$DEST/$REPORT_NAME"
cp -r "$SRC/app" "$DEST/app"

# Verify the copy really excludes the README before reporting success.
if [ -e "$DEST/README.md" ]; then
  echo "FATAL: README.md present in $DEST after build — answer key would leak to the rep." >&2
  exit 1
fi
if [ ! -f "$DEST/$REPORT_NAME" ] || [ ! -d "$DEST/app" ]; then
  echo "FATAL: rep-facing copy is missing the report or the app tree after build." >&2
  exit 1
fi

echo "$DEST"
