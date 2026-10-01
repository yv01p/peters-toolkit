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

# run_gate DIR NN — prints the gate's output for batch NN of the run state in DIR.
run_gate() {
  sed -n "$((start+1)),$((end-1))p" "$SKILL" \
    | sed -e "s#<WORK>#$1/work#g" -e "s#<SRC>#$1/src#g" -e "s/NN/$2/g" > "$1/gate-$2.sh"
  ( cd "$1" && bash "$1/gate-$2.sh" 2>&1 )
}

# make_state DIR — two same-named files in different directories, one per batch, with
# correct worker output. manifest.tsv File is the path relative to <SRC>.
make_state() {
  local d="$1" W="$1/work"
  mkdir -p "$d/src/schema_a" "$d/src/schema_b" "$W/batch-01" "$W/batch-02"
  printf 'CREATE PROCEDURE a_log AS BEGIN NULL; END;\n/\n' > "$d/src/schema_a/util.sql"
  printf 'CREATE PROCEDURE b_fmt AS BEGIN NULL; END;\n/\n' > "$d/src/schema_b/util.sql"
  printf 'a_log|Procedure|schema_a/util.sql|2\nb_fmt|Procedure|schema_b/util.sql|2\n' > "$W/manifest.tsv"
  printf '01|%s|production\n02|%s|production\n' "$d/src/schema_a/util.sql" "$d/src/schema_b/util.sql" > "$W/batches.tsv"
  printf 'a_log|0|0|0|none|util.sql|2\n' > "$W/batch-01/metrics.tsv"
  printf 'b_fmt|0|0|0|none|util.sql|2\n' > "$W/batch-02/metrics.tsv"
  touch "$W/batch-01/done" "$W/batch-02/done"
}

# --- Case A: same-named files in different batches, correct workers: both batches pass ---
A="$TMPROOT/caseA"; make_state "$A"
for nn in 01 02; do
  out="$(run_gate "$A" "$nn")"
  [ -z "$out" ] || fail "Case A: batch $nn failed the gate with correct worker output:
$out"
done

# --- Case B: a missing object is still caught ---
B="$TMPROOT/caseB"; make_state "$B"; : > "$B/work/batch-02/metrics.tsv"
[ -n "$(run_gate "$B" 02)" ] || fail "Case B: batch 02 has no metrics rows but passed the gate"

# --- Case C: a stray row is still caught ---
C="$TMPROOT/caseC"; make_state "$C"; printf 'b_fmt|0|0|0|none|util.sql|2\n' >> "$C/work/batch-01/metrics.tsv"
[ -n "$(run_gate "$C" 01)" ] || fail "Case C: batch 01 carries batch 02's routine but passed the gate"

echo "sproc-xray completeness gate OK"
