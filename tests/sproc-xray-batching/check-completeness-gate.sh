#!/usr/bin/env bash
# Hermetic: regression test for the sproc-xray completeness gate in SKILL.md (#12).
# Extracts the gate command verbatim (the fenced bash block between the "Completeness gate"
# item and the "Combine" item), substitutes <WORK>, <SRC> and NN, and runs it per batch on a
# crafted run state. The gate passes when the command prints nothing.
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/sproc-xray/SKILL.md"

fail(){ echo "FAIL: $1" >&2; exit 1; }

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

# --- Extract the gate command verbatim from SKILL.md ---
g=$(grep -n '\*\*Completeness gate, per batch, by command\.\*\*' "$SKILL" | head -1 | cut -d: -f1)
c=$(grep -n '\*\*Combine\.\*\*' "$SKILL" | head -1 | cut -d: -f1)
[ -n "$g" ] && [ -n "$c" ] || fail "could not find the Completeness gate and Combine items in SKILL.md"
start=$(awk -v g="$g" -v c="$c" 'NR>g && NR<c && /^ *```bash$/ {print NR; exit}' "$SKILL")
[ -n "$start" ] || fail "no verbatim gate command: no \`\`\`bash block between the Completeness gate item (:$g) and Combine (:$c)"
end=$(awk -v s="$start" 'NR>s && /^ *```$/ {print NR; exit}' "$SKILL")
[ -n "$end" ] || fail "gate command block at :$start has no closing fence"

# --- Pins: byte-wise awks and sorts (Cases F and G only fail without them on some hosts) ---
block="$(sed -n "$((start+1)),$((end-1))p" "$SKILL")"
[ "$(printf '%s\n' "$block" | grep -o 'LC_ALL=C awk' | wc -l | tr -d ' ')" = 2 ] || fail "gate block must run both awks under LC_ALL=C"
[ "$(printf '%s\n' "$block" | grep -o 'LC_ALL=C sort' | wc -l | tr -d ' ')" = 2 ] || fail "gate block must run both sorts under LC_ALL=C"

# run_gate DIR NN [ROOTNAME] — prints the gate's output for batch NN of the run state in DIR.
run_gate() {
  local root="$1/${3:-src}"
  printf '%s\n' "$block" \
    | sed -e "s/NN/$2/g" -e "s#<WORK>#$1/work#g" -e "s#<SRC>#$root#g" > "$1/gate-$2.sh"
  ( cd "$1" && bash "$1/gate-$2.sh" 2>&1 )
}

# make_state DIR [ROOTNAME] [FORM] [DIR_A] [NAME_A] — two same-named files in different
# directories, one per batch, with correct worker output, plus a Table line that no worker
# reports (the gate counts routines only). FORM is the manifest File form:
# rel (path relative to <SRC>, the default), dot (./rel) or abs (absolute path).
make_state() {
  local d="$1" root="$1/${2:-src}" form="${3:-rel}" da="${4:-schema_a}" na="${5:-a_log}" W="$1/work" pa pb
  mkdir -p "$root/$da" "$root/schema_b" "$W/batch-01" "$W/batch-02"
  printf 'CREATE PROCEDURE %s AS BEGIN NULL; END;\n/\n' "$na" > "$root/$da/util.sql"
  printf 'CREATE PROCEDURE b_fmt AS BEGIN NULL; END;\n/\n' > "$root/schema_b/util.sql"
  case "$form" in
    rel) pa="$da/util.sql"; pb="schema_b/util.sql" ;;
    dot) pa="./$da/util.sql"; pb="./schema_b/util.sql" ;;
    abs) pa="$root/$da/util.sql"; pb="$root/schema_b/util.sql" ;;
  esac
  printf '%s|Procedure|%s|2\nb_fmt|Procedure|%s|2\nt_x|Table|%s|2\n' "$na" "$pa" "$pb" "$pa" > "$W/manifest.tsv"
  printf '01|%s|production\n02|%s|production\n' "$root/$da/util.sql" "$root/schema_b/util.sql" > "$W/batches.tsv"
  printf '%s|0|0|0|none|util.sql|2\n' "$na" > "$W/batch-01/metrics.tsv"
  printf 'b_fmt|0|0|0|none|util.sql|2\n' > "$W/batch-02/metrics.tsv"
  touch "$W/batch-01/done" "$W/batch-02/done"
}

# both_pass LABEL DIR [ROOTNAME]
both_pass() {
  local nn out
  for nn in 01 02; do
    out="$(run_gate "$2" "$nn" "${3:-}")"
    [ -z "$out" ] || fail "$1: batch $nn failed the gate with correct worker output:
$out"
  done
}

# --- Case A: same-named files in different batches, correct workers: both batches pass ---
A="$TMPROOT/caseA"; make_state "$A"; both_pass "Case A" "$A"

# --- Case B: a missing object is still caught ---
B="$TMPROOT/caseB"; make_state "$B"; : > "$B/work/batch-02/metrics.tsv"
out="$(run_gate "$B" 02)"
printf '%s\n' "$out" | grep -qx '< b_fmt' || fail "Case B: batch 02's missing routine must print as '< b_fmt'. Got:
$out"

# --- Case C: a stray row is still caught ---
C="$TMPROOT/caseC"; make_state "$C"; printf 'b_fmt|0|0|0|none|util.sql|2\n' >> "$C/work/batch-01/metrics.tsv"
[ -n "$(run_gate "$C" 01)" ] || fail "Case C: batch 01 carries batch 02's routine but passed the gate"

# --- Case C2: a batch with no done file is caught ---
C2="$TMPROOT/caseC2"; make_state "$C2"; rm "$C2/work/batch-01/done"
[ -n "$(run_gate "$C2" 01)" ] || fail "Case C2: batch 01 has no done file but passed the gate"

# --- Case D: a ' in the source root ---
D="$TMPROOT/caseD"; make_state "$D" "it's src"; both_pass "Case D" "$D" "it's src"

# --- Case E: manifest File written ./-prefixed or absolute ---
for form in dot abs; do
  E="$TMPROOT/caseE-$form"; make_state "$E" src "$form"; both_pass "Case E ($form)" "$E"
done

# --- Case F: Latin-1 directory and routine name; missing and stray still caught ---
LA="$(printf 'sch\351ma_a')"; LN="$(printf 'a_l\351g')"
F="$TMPROOT/caseF"; make_state "$F" src rel "$LA" "$LN"; both_pass "Case F" "$F"
F2="$TMPROOT/caseF2"; make_state "$F2" src rel "$LA" "$LN"; : > "$F2/work/batch-01/metrics.tsv"
[ -n "$(run_gate "$F2" 01)" ] || fail "Case F: batch 01 lost its Latin-1 routine but passed the gate"
F3="$TMPROOT/caseF3"; make_state "$F3" src rel "$LA" "$LN"; printf 'b_fmt|0|0|0|none|util.sql|2\n' >> "$F3/work/batch-01/metrics.tsv"
[ -n "$(run_gate "$F3" 01)" ] || fail "Case F: batch 01 carries batch 02's routine but passed the gate"

# --- Case G: names a UTF-8 sort can tie, listed in different orders by manifest and worker ---
G="$TMPROOT/caseG"; make_state "$G"
{ printf 'alog|Procedure|schema_a/util.sql|2\n'; printf 'a_l\351g|Procedure|schema_a/util.sql|2\n'; printf 'a_l\350g|Procedure|schema_a/util.sql|2\n'; } >> "$G/work/manifest.tsv"
{ printf 'a_l\350g|0|0|0|none|util.sql|2\n'; printf 'a_l\351g|0|0|0|none|util.sql|2\n'; printf 'alog|0|0|0|none|util.sql|2\n'; cat "$G/work/batch-01/metrics.tsv"; } > "$G/work/batch-01/metrics.new"
mv "$G/work/batch-01/metrics.new" "$G/work/batch-01/metrics.tsv"
both_pass "Case G" "$G"

echo "sproc-xray completeness gate OK"
