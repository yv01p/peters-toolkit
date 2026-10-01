#!/usr/bin/env bash
# Hermetic: regression test for the sproc-xray batch-plan command in SKILL.md (F18/F29, #8).
# Extracts the awk one-liner verbatim (by content, so it survives future LIMIT edits) and runs
# it against a known-answer fixture, a shell-injection filename, and $ / ' filenames. No
# network / install. Runs the extracted command with a scratch temp dir as cwd so a regression
# cannot touch the repo.
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/sproc-xray/SKILL.md"

fail(){ echo "FAIL: $1" >&2; exit 1; }

ORIG_CWD="$(pwd)"
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

# --- Extract the batch-plan command verbatim from SKILL.md ---
start=$(grep -n "awk -F'|' -v LIMIT=[0-9]* '" "$SKILL" | head -1 | cut -d: -f1)
end=$(grep -n '<WORK>/batches\.tsv$' "$SKILL" | head -1 | cut -d: -f1)
[ -n "$start" ] || fail "could not find the batch-plan command's start line in SKILL.md"
[ -n "$end" ] || fail "could not find the batch-plan command's end line in SKILL.md"

# run_case LIMIT WORKDIR — writes WORKDIR/cmd.sh (command with <WORK> and LIMIT substituted)
# and WORKDIR/sources.tsv must already exist. Runs the command with WORKDIR as cwd.
run_case() {
  local limit="$1" workdir="$2"
  sed -n "${start},${end}p" "$SKILL" \
    | sed -e "s#<WORK>#${workdir}#g" -e "s/LIMIT=[0-9][0-9]*/LIMIT=${limit}/" \
    > "$workdir/cmd.sh"
  ( cd "$workdir" && bash "$workdir/cmd.sh" ) >"$workdir/cmd.out" 2>"$workdir/cmd.err"
}

# --- Case A: known answer (in-repo dbonly1 fixture, plan Task 3 Step 10's sources.tsv build) ---
CASEA="$TMPROOT/caseA"
mkdir -p "$CASEA"
FIXTURE="$ROOT/tests/sproc-planning-dbonly/dbonly1/sql"
[ -d "$FIXTURE" ] || fail "fixture missing: $FIXTURE"
find "$FIXTURE" -type f | LC_ALL=C sort \
  | awk '{s=($0 ~ /-Test\.sql$/)?"test":"production"; print $0"|"s}' > "$CASEA/sources.tsv"
run_case 3400 "$CASEA"
[ -s "$CASEA/batches.tsv" ] || fail "Case A: batches.tsv empty or missing ($(cat "$CASEA/cmd.err" 2>/dev/null))"

got_b1="$(awk -F'|' '$1=="01"{print $2}' "$CASEA/batches.tsv" | xargs -n1 basename | sort)"
got_b2="$(awk -F'|' '$1=="02"{print $2}' "$CASEA/batches.tsv" | xargs -n1 basename | sort)"
exp_b1="$(printf '%s\n' \
  fn_calculate_discount-Test.sql fn_calculate_discount.sql fn_calculate_tax.sql \
  fn_check_inventory_status.sql fn_format_order_number-Test.sql fn_format_order_number.sql \
  fn_validate_postal_code-Test.sql fn_validate_postal_code.sql pkg_order_state.sql | sort)"
exp_b2="$(printf '%s\n' \
  prc_finalize_order.sql prc_reset_batch_totals.sql trg_order_status_audit.sql | sort)"

[ "$got_b1" = "$exp_b1" ] || fail "Case A: batch 01 mismatch. Got:
$got_b1
Expected:
$exp_b1"
[ "$got_b2" = "$exp_b2" ] || fail "Case A: batch 02 mismatch. Got:
$got_b2
Expected:
$exp_b2"
num_batches="$(awk -F'|' '{print $1}' "$CASEA/batches.tsv" | sort -u | wc -l | tr -d ' ')"
[ "$num_batches" = "2" ] || fail "Case A: expected exactly 2 batches, got $num_batches"

# --- Case B: injection is inert ---
CASEB="$TMPROOT/caseB"
mkdir -p "$CASEB/src"
INJFILE='a$(touch INJECTED).sql'
printf 'some bytes here\n' > "$CASEB/src/$INJFILE"
find "$CASEB/src" -type f | LC_ALL=C sort \
  | awk '{s=($0 ~ /-Test\.sql$/)?"test":"production"; print $0"|"s}' > "$CASEB/sources.tsv"
run_case 999999 "$CASEB"

[ -e "$CASEB/INJECTED" ] && fail "Case B: injection fired — INJECTED created in the run's temp dir"
[ -e "$CASEB/src/INJECTED" ] && fail "Case B: injection fired — INJECTED created in src/"
[ -e "$ORIG_CWD/INJECTED" ] && fail "Case B: injection fired — INJECTED created in the test's cwd"
[ -e "$ROOT/INJECTED" ] && fail "Case B: injection fired — INJECTED created in the repo root"
grep -qF "$INJFILE" "$CASEB/batches.tsv" 2>/dev/null || fail "Case B: injected-named file is missing from batches.tsv"

# --- Case C: $ and ' names are sized ---
CASEC="$TMPROOT/caseC"
mkdir -p "$CASEC/src"
head -c 3000 /dev/zero | tr '\0' 'x' > "$CASEC/src/"'PKG$UTIL.sql'
head -c 3000 /dev/zero | tr '\0' 'x' > "$CASEC/src/"'X$Y.sql'
head -c 3000 /dev/zero | tr '\0' 'x' > "$CASEC/src/""it's.sql"
find "$CASEC/src" -type f | LC_ALL=C sort \
  | awk '{s=($0 ~ /-Test\.sql$/)?"test":"production"; print $0"|"s}' > "$CASEC/sources.tsv"
run_case 4000 "$CASEC"
[ -s "$CASEC/batches.tsv" ] || fail "Case C: batches.tsv empty or missing ($(cat "$CASEC/cmd.err" 2>/dev/null))"

distinct="$(awk -F'|' '{print $1}' "$CASEC/batches.tsv" | sort -u | wc -l | tr -d ' ')"
[ "$distinct" = "3" ] || fail "Case C: expected 3 distinct batch numbers (files sized independently), got $distinct:
$(cat "$CASEC/batches.tsv")"

# --- Case D: every package in a multi-package file stays with its other half (#11) ---
# ~1 KB files under LIMIT=1500, so any two units land in different batches.
pad(){ head -c 1000 /dev/zero | tr '\0' ' '; echo; }
spec(){ printf 'CREATE OR REPLACE PACKAGE %s AS\n  PROCEDURE p;\nEND %s;\n/\n' "$1" "$1"; }
body(){ printf 'CREATE OR REPLACE PACKAGE BODY %s AS\n  PROCEDURE p IS BEGIN NULL; END;\nEND %s;\n/\n' "$1" "$1"; }
batch_of(){ awk -F'|' -v f="$2" '{n=$(2); sub(/.*\//, "", n)} n==f {print $(1)}' "$1/batches.tsv"; }
same_batch(){
  local dir="$1" label="$2" a="$3" b="$4" ba bb
  ba="$(batch_of "$dir" "$a")"; bb="$(batch_of "$dir" "$b")"
  [ -n "$ba" ] && [ "$ba" = "$bb" ] || fail "$label: $a (batch '$ba') and $b (batch '$bb') must share a batch:
$(cat "$dir/batches.tsv")"
}

# D1: one all-specs file, then a body file per package.
CASED1="$TMPROOT/caseD1"
mkdir -p "$CASED1/src"
{ spec pkg_a; spec pkg_b; pad; } > "$CASED1/src/a_specs.pks"
{ body pkg_a; pad; } > "$CASED1/src/b_pkg_a.pkb"
{ body pkg_b; pad; } > "$CASED1/src/c_pkg_b.pkb"
find "$CASED1/src" -type f | LC_ALL=C sort | awk '{print $0"|production"}' > "$CASED1/sources.tsv"
run_case 1500 "$CASED1"
[ -s "$CASED1/batches.tsv" ] || fail "Case D1: batches.tsv empty or missing ($(cat "$CASED1/cmd.err" 2>/dev/null))"
same_batch "$CASED1" "Case D1" a_specs.pks b_pkg_a.pkb
same_batch "$CASED1" "Case D1" a_specs.pks c_pkg_b.pkb

# D2: a spec file per package, then one all-bodies file that joins both.
CASED2="$TMPROOT/caseD2"
mkdir -p "$CASED2/src"
{ spec pkg_a; pad; } > "$CASED2/src/a_pkg_a.pks"
{ spec pkg_b; pad; } > "$CASED2/src/b_pkg_b.pks"
{ body pkg_a; body pkg_b; pad; } > "$CASED2/src/c_bodies.pkb"
find "$CASED2/src" -type f | LC_ALL=C sort | awk '{print $0"|production"}' > "$CASED2/sources.tsv"
run_case 1500 "$CASED2"
[ -s "$CASED2/batches.tsv" ] || fail "Case D2: batches.tsv empty or missing ($(cat "$CASED2/cmd.err" 2>/dev/null))"
same_batch "$CASED2" "Case D2" c_bodies.pkb a_pkg_a.pks
same_batch "$CASED2" "Case D2" c_bodies.pkb b_pkg_b.pks

echo "sproc-xray batch-plan command OK"
