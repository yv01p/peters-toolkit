#!/usr/bin/env bash
# Hermetic: regression test for the sproc-xray proof split in SKILL.md Step 4.6 (#10).
# Extracts the split command verbatim (by content) and runs it on built assembled files:
# A — proof runs become pointer lines and move byte-identical to the proofs file;
# B — an odd fence count inside a proof exits non-zero (the run falls back);
# C — an even fence count inside one proof passes and tears it (the accepted known issue).
# D — a non-proof fence right after a proof run follows the run's pointer line.
# No network / install. Runs in a scratch temp dir.
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/sproc-xray/SKILL.md"

fail(){ echo "FAIL: $1" >&2; exit 1; }

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

# --- Extract the split command verbatim from SKILL.md ---
start=$(grep -nF 'W="<WORK>"; D="<ORIG>/reports"' "$SKILL" | head -1 | cut -d: -f1)
end=$(grep -n '"\$W/assembled\.md"$' "$SKILL" | head -1 | cut -d: -f1)
[ -n "$start" ] || fail "could not find the split command's start line in SKILL.md"
[ -n "$end" ] || fail "could not find the split command's end line in SKILL.md"

# run_case NAME — CASE/w/assembled.md must exist. Writes CASE/o/reports/SYS-SPROC-XRAY{,-PROOFS}.md
# and sets rc to the command's exit status.
run_case() {
  local c="$TMPROOT/$1"
  sed -n "${start},${end}p" "$SKILL" \
    | sed -e "s#<WORK>#$c/w#g" -e "s#<ORIG>#$c/o#g" -e "s#{SYSTEM}#SYS#g" > "$c/cmd.sh"
  ( cd "$c" && bash "$c/cmd.sh" ) >"$c/cmd.out" 2>"$c/cmd.err"; rc=$?
  R="$c/o/reports/SYS-SPROC-XRAY.md"; P="$c/o/reports/SYS-SPROC-XRAY-PROOFS.md"
}
F='```'

# --- Case A: two proofs split by a blank line, a caption, a third proof, non-proof fences ---
mkdir -p "$TMPROOT/A/w"
printf '%s\n' '# SYS — X-Ray' '## Sec One' 'intro line' \
  "$F" '$ echo one' 'one' "$F" '' "$F" '$ echo two' 'two' "$F" 'caption line' \
  "$F" '$ echo three' 'three' "$F" '## Sec Two' "${F}mermaid" 'flowchart TD' "$F" \
  "$F" 'UPDATE orders SET x = 1' "$F" 'closing prose' > "$TMPROOT/A/w/assembled.md"
run_case A
[ "$rc" -eq 0 ] || fail "Case A: exit $rc ($(cat "$TMPROOT/A/cmd.err"))"
printf '%s\n' '# SYS — X-Ray' '## Sec One' 'intro line' \
  'Proofs 1–2: see `SYS-SPROC-XRAY-PROOFS.md`.' 'caption line' \
  'Proof 3: see `SYS-SPROC-XRAY-PROOFS.md`.' '## Sec Two' "${F}mermaid" 'flowchart TD' "$F" \
  "$F" 'UPDATE orders SET x = 1' "$F" 'closing prose' > "$TMPROOT/A/exp-R"
printf '%s\n' '# Proof blocks for `SYS-SPROC-XRAY.md`' '' \
  'Every proof block of the report, in report order, under the report heading it sat below.' \
  '' '## Proof 1 — Sec One' '' "$F" '$ echo one' 'one' "$F" \
  '' '## Proof 2 — Sec One' '' "$F" '$ echo two' 'two' "$F" \
  '' '## Proof 3 — Sec One' '' "$F" '$ echo three' 'three' "$F" > "$TMPROOT/A/exp-P"
diff "$TMPROOT/A/exp-R" "$R" >/dev/null || fail "Case A: report differs from expected:
$(diff "$TMPROOT/A/exp-R" "$R")"
diff "$TMPROOT/A/exp-P" "$P" >/dev/null || fail "Case A: proofs file differs from expected:
$(diff "$TMPROOT/A/exp-P" "$P")"

# --- Case B: odd fence count inside the last proof -> non-zero exit ---
mkdir -p "$TMPROOT/B/w"
printf '%s\n' '## S' "$F" '$ cat notes.md' "${F}sql" 'x' "$F" 'end' > "$TMPROOT/B/w/assembled.md"
run_case B
[ "$rc" -ne 0 ] || fail "Case B: expected a non-zero exit for an odd fence count, got 0"

# --- Case C: even fence count inside one proof -> exit 0, proof torn (accepted, Known issues) ---
mkdir -p "$TMPROOT/C/w"
printf '%s\n' '## S' "$F" "\$ sed -n '1,5p' f1.sql" '/* usage:' "$F" 'SELECT f1 FROM dual;' "$F" '*/' "$F" 'after' \
  > "$TMPROOT/C/w/assembled.md"
run_case C
[ "$rc" -eq 0 ] || fail "Case C: exit $rc ($(cat "$TMPROOT/C/cmd.err"))"
grep -q '^\$ ' "$R" && fail "Case C: a line starting \"\$ \" is in the report"
printf '%s\n' '## S' 'Proof 1: see `SYS-SPROC-XRAY-PROOFS.md`.' 'SELECT f1 FROM dual;' "$F" '*/' "$F" 'after' \
  > "$TMPROOT/C/exp-R"
diff "$TMPROOT/C/exp-R" "$R" >/dev/null || fail "Case C: report differs from expected:
$(diff "$TMPROOT/C/exp-R" "$R")"
tail -4 "$P" | diff - <(printf '%s\n' "$F" "\$ sed -n '1,5p' f1.sql" '/* usage:' "$F") >/dev/null \
  || fail "Case C: proofs file does not end at the first inner fence:
$(tail -4 "$P")"


# --- Case D: a non-proof fence directly after a proof run -> pointer line, then the block ---
mkdir -p "$TMPROOT/D/w"
printf '%s\n' '## S' "$F" '$ echo one' 'one' "$F" "${F}mermaid" 'flowchart TD' "$F" 'after' > "$TMPROOT/D/w/assembled.md"
run_case D
[ "$rc" -eq 0 ] || fail "Case D: exit $rc ($(cat "$TMPROOT/D/cmd.err"))"
printf '%s\n' '## S' 'Proof 1: see `SYS-SPROC-XRAY-PROOFS.md`.' "${F}mermaid" 'flowchart TD' "$F" 'after' > "$TMPROOT/D/exp-R"
diff "$TMPROOT/D/exp-R" "$R" >/dev/null || fail "Case D: report differs from expected:
$(diff "$TMPROOT/D/exp-R" "$R")"
tail -4 "$P" | diff - <(printf '%s\n' "$F" '$ echo one' 'one' "$F") >/dev/null \
  || fail "Case D: proofs file does not end with the proof block:
$(tail -4 "$P")"

echo "sproc-xray proof split OK"
