#!/usr/bin/env bash
# Builds the rep-facing copy of the xraytest1 fixture: the committed fixture with the
# `## Ground truth` section of its README removed.
#
# Why: the sproc-xray intake step has the analyst read the project README. A rep that can
# see the ground-truth numbers can transcribe them without computing anything — the same
# instrument failure as method leakage in the prompt. BOTH arms of the harness must build
# their fixture with this script; if the arms differ in the fixture itself, the comparison
# the harness exists to make is confounded.
#
# Usage:  prepare-rep-fixture.sh <destination-dir>
#         Creates <destination-dir>/xraytest1 and prints its absolute path on stdout —
#         that path is {FIXTURE_PATH} in rep-prompt-template.md.
#
# Idempotent: an existing <destination-dir>/xraytest1 is removed and rebuilt from the
# committed source. The committed fixture is never modified.
#
# Fails loudly (exit 1) rather than ever handing a rep an un-stripped README.
set -euo pipefail

MARKER='## Ground truth'
SRC="$(cd "$(dirname "$0")" && pwd)/xraytest1"

if [ "$#" -ne 1 ]; then
  echo "usage: $(basename "$0") <destination-dir>" >&2
  exit 2
fi

[ -d "$SRC" ] || { echo "FATAL: source fixture not found: $SRC" >&2; exit 1; }
[ -f "$SRC/README.md" ] || { echo "FATAL: fixture README not found: $SRC/README.md" >&2; exit 1; }

# Locate the ground-truth heading in the committed README BEFORE copying anything. If the
# heading is absent the fixture has changed shape, and stripping cannot be verified — stop.
marker_line="$(grep -n -m1 -F -x "$MARKER" "$SRC/README.md" | cut -d: -f1 || true)"
if [ -z "$marker_line" ]; then
  echo "FATAL: heading '$MARKER' not found in $SRC/README.md." >&2
  echo "       Refusing to produce a fixture whose ground truth may still be visible." >&2
  exit 1
fi

mkdir -p "$1"
DEST="$(cd "$1" && pwd)/xraytest1"

# The next step is `rm -rf "$DEST"`. If the destination resolves to the committed fixture
# itself — which it does for `<repo>/tests/sproc-metrics`, or for `.` when the caller's cwd
# is that directory — that rm would DELETE THE FROZEN FIXTURE. Compare resolved paths and
# refuse. This is the one failure mode of this script that is not recoverable by re-running it.
if [ "$DEST" = "$SRC" ]; then
  echo "FATAL: destination resolves to the committed fixture itself ($SRC)." >&2
  echo "       Refusing to delete the frozen fixture. Pass a scratch directory, not the" >&2
  echo "       tests/sproc-metrics directory (and note the destination gets an /xraytest1 suffix)." >&2
  exit 1
fi

rm -rf "$DEST"
cp -r "$SRC" "$DEST"
head -n "$((marker_line - 1))" "$SRC/README.md" > "$DEST/README.md"

# Verify the copy really is stripped before reporting success.
if grep -q -F -x "$MARKER" "$DEST/README.md"; then
  echo "FATAL: heading '$MARKER' still present in $DEST/README.md after stripping." >&2
  exit 1
fi

echo "$DEST"
