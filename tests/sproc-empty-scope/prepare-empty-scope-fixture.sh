#!/usr/bin/env bash
# Builds a rep-facing copy of one of the four empty-scope fixture cells, with every
# `README.md` answer key excluded entirely.
#
# Why: `empty1/README.md` and `viewlogic1/README.md` each record the exact answer a
# sproc-xray rep must independently reach (whether the empty-scope short-circuit should
# fire). A rep that can see either file can transcribe the answer instead of computing it
# from the corpus alone — the same instrument failure as method leakage in the prompt (see
# tests/sproc-planning/prepare-rep-fixture.sh, Ruling 14, and
# tests/sproc-xray-binary/prepare-binary-fixture.sh, which this script mirrors). The whole
# README is the answer key here, not a section of it — like those two scripts (and unlike
# tests/sproc-metrics/prepare-rep-fixture.sh, which truncates only a `## Ground truth`
# heading), this script excludes the file wholesale, never truncates it.
#
# Four fixture cells, two "views":
#   x-ray view       — a corpus only, no report present:
#     empty        <destination-dir>/empty1/app        (from empty1/app)
#     viewlogic    <destination-dir>/viewlogic1/sql     (from viewlogic1/sql)
#   migration-plan view — a committed x-ray report plus its app tree:
#     planning-empty   <destination-dir>/empty1/{EMPTY1-SPROC-XRAY.md, app/}
#                       (report from empty-report/, app tree from empty1/app)
#     planning-binary  <destination-dir>/binonly1/{BINONLY1-SPROC-XRAY.md, sample_db.mdf}
#                       (report from binary-report/, corpus from
#                       ../sproc-xray-binary/binonly1/sample_db.mdf)
#
# All four cells must be built with this one script, or the cells differ in
# fixture-preparation mechanics and the comparison the harness exists to make is confounded.
#
# Usage:  prepare-empty-scope-fixture.sh <cell> <destination-dir>
#         <cell> is one of: empty | viewlogic | planning-empty | planning-binary
#         Prints the absolute path to the rep-facing fixture directory on stdout — that
#         path is {FIXTURE_PATH} in rep-prompt-template.md.
#
# Idempotent: an existing destination for the chosen cell is removed and rebuilt from the
# committed source. No committed fixture (including any README.md) is ever modified.
#
# NOTE (Ruling 14 — REP-ISOLATION, see tests/sproc-planning/rep-prompt-template.md): this
# script only controls the COPY'S CONTENTS (excludes every README.md). It does not, and
# cannot, control where <destination-dir> itself lives — that is the caller's
# responsibility. Per REP-ISOLATION requirement 1, the caller must pass a neutral sandbox
# path that does not encode this checkout (not a path shaped like the default per-session
# scratch dir, which embeds the working directory's name) — otherwise a rep can identify and
# wander into the real repository regardless of what this script excludes.
#
# Fails loudly (exit 1) rather than ever handing a rep a copy that contains a README.md.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BINARY_SRC_DIR="$(cd "$SCRIPT_DIR/../sproc-xray-binary" && pwd)"

if [ "$#" -ne 2 ]; then
  echo "usage: $(basename "$0") <cell: empty|viewlogic|planning-empty|planning-binary> <destination-dir>" >&2
  exit 2
fi

CELL="$1"
DEST_ROOT="$2"

# refuse_if_same_resolved_path OLD_PATH_DESC SRC NEW_PATH_DESC DEST
#
# The DEST computed below is about to be `rm -rf`'d. If it resolves to a source directory
# this script reads from, that rm would DELETE THE FROZEN FIXTURE (or, for planning-binary,
# a fixture belonging to a DIFFERENT test suite entirely). Compare resolved paths and
# refuse. This is the one failure mode of this script that is not recoverable by re-running
# it.
refuse_if_same_resolved_path() {
  local src="$1" dest="$2" src_label="$3"
  if [ "$dest" = "$src" ]; then
    echo "FATAL: destination resolves to the committed fixture itself ($src_label: $src)." >&2
    echo "       Refusing to delete the frozen fixture. Pass a scratch directory, not a" >&2
    echo "       tests/sproc-empty-scope (or tests/sproc-xray-binary) directory." >&2
    exit 1
  fi
}

mkdir -p "$DEST_ROOT"
DEST_ROOT="$(cd "$DEST_ROOT" && pwd)"

case "$CELL" in
  empty)
    # x-ray view: empty1's corpus only — README.md excluded, no *-SPROC-XRAY.md present.
    SRC="$SCRIPT_DIR/empty1"
    [ -d "$SRC/app" ] || { echo "FATAL: application tree not found: $SRC/app" >&2; exit 1; }
    [ -f "$SRC/README.md" ] || { echo "FATAL: fixture README not found: $SRC/README.md (nothing to exclude — fixture shape has changed)" >&2; exit 1; }

    DEST="$DEST_ROOT/empty1"
    refuse_if_same_resolved_path "$SRC" "$DEST" "empty1"

    rm -rf "$DEST"
    mkdir -p "$DEST"
    cp -r "$SRC/app" "$DEST/app"
    ;;

  viewlogic)
    # x-ray view: viewlogic1's corpus only — README.md excluded, no *-SPROC-XRAY.md present.
    SRC="$SCRIPT_DIR/viewlogic1"
    [ -d "$SRC/sql" ] || { echo "FATAL: sql tree not found: $SRC/sql" >&2; exit 1; }
    [ -f "$SRC/README.md" ] || { echo "FATAL: fixture README not found: $SRC/README.md (nothing to exclude — fixture shape has changed)" >&2; exit 1; }

    DEST="$DEST_ROOT/viewlogic1"
    refuse_if_same_resolved_path "$SRC" "$DEST" "viewlogic1"

    rm -rf "$DEST"
    mkdir -p "$DEST"
    cp -r "$SRC/sql" "$DEST/sql"
    ;;

  planning-empty)
    # migration-plan view: EMPTY1-SPROC-XRAY.md (from empty-report/) + empty1/app.
    REPORT_SRC="$SCRIPT_DIR/empty-report/EMPTY1-SPROC-XRAY.md"
    APP_SRC="$SCRIPT_DIR/empty1/app"
    [ -f "$REPORT_SRC" ] || { echo "FATAL: x-ray report not found: $REPORT_SRC (Task 1 Step 2 generates this from a real x-ray run — has it run yet?)" >&2; exit 1; }
    [ -d "$APP_SRC" ] || { echo "FATAL: application tree not found: $APP_SRC" >&2; exit 1; }

    DEST="$DEST_ROOT/empty1"
    refuse_if_same_resolved_path "$SCRIPT_DIR/empty1" "$DEST" "empty1"
    refuse_if_same_resolved_path "$SCRIPT_DIR/empty-report" "$DEST" "empty-report"

    rm -rf "$DEST"
    mkdir -p "$DEST"
    cp "$REPORT_SRC" "$DEST/EMPTY1-SPROC-XRAY.md"
    cp -r "$APP_SRC" "$DEST/app"

    if [ -e "$DEST/README.md" ]; then
      echo "FATAL: README.md present in $DEST after build — answer key would leak to the rep." >&2
      exit 1
    fi
    ;;

  planning-binary)
    # migration-plan view: BINONLY1-SPROC-XRAY.md (from binary-report/) + the binonly1
    # corpus's sample_db.mdf (from ../sproc-xray-binary/binonly1/ — its own README.md is
    # excluded here exactly as it is by that suite's own prepare-binary-fixture.sh).
    REPORT_SRC="$SCRIPT_DIR/binary-report/BINONLY1-SPROC-XRAY.md"
    MDF_SRC="$BINARY_SRC_DIR/binonly1/sample_db.mdf"
    [ -f "$REPORT_SRC" ] || { echo "FATAL: x-ray report not found: $REPORT_SRC (Task 1 Step 2 generates this from a real x-ray run — has it run yet?)" >&2; exit 1; }
    [ -f "$MDF_SRC" ] || { echo "FATAL: binary corpus not found: $MDF_SRC" >&2; exit 1; }

    DEST="$DEST_ROOT/binonly1"
    refuse_if_same_resolved_path "$SCRIPT_DIR/binary-report" "$DEST" "binary-report"
    refuse_if_same_resolved_path "$BINARY_SRC_DIR/binonly1" "$DEST" "binonly1 (tests/sproc-xray-binary)"

    rm -rf "$DEST"
    mkdir -p "$DEST"
    cp "$REPORT_SRC" "$DEST/BINONLY1-SPROC-XRAY.md"
    cp "$MDF_SRC" "$DEST/sample_db.mdf"

    if [ -e "$DEST/README.md" ]; then
      echo "FATAL: README.md present in $DEST after build — answer key would leak to the rep." >&2
      exit 1
    fi
    ;;

  *)
    echo "FATAL: unknown cell '$CELL' — must be one of: empty | viewlogic | planning-empty | planning-binary" >&2
    exit 2
    ;;
esac

# Belt-and-suspenders: no README.md anywhere under the built destination, regardless of cell.
if find "$DEST" -iname 'README.md' -print -quit | grep -q .; then
  echo "FATAL: a README.md survived the build under $DEST — answer key would leak to the rep." >&2
  exit 1
fi

echo "$DEST"
