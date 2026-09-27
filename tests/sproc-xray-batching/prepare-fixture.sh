#!/usr/bin/env bash
# Builds the #8 GREEN-run inputs under <dest-dir>:
#   adempiere/     ADempiere sparse clone at the pinned commit (reused when present)
#   t2/o1-corpus   db/ddlutils/oracle/functions — 50 files (T2)
#   t3/o3-corpus   functions + procedures + views, flattened — 250 files (T3)
#   t5/dbonly1     tests/sproc-planning-dbonly/dbonly1/sql plus one dynamic call (T5)
#   plugin-3400/   this plugin's .claude-plugin/ and skills/sproc-xray/ with LIMIT=3400 (T5)
# Pass a neutral <dest-dir> (e.g. /tmp/sproc-green) that does not name this checkout, so a run
# cannot find its way to the repo's baseline results. The committed fixtures are never modified.
# Usage: prepare-fixture.sh <dest-dir>. Prints the dest dir on success.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SHA=59557cc2ee85ac938cd4f31a246d891bc2b15b8f
[ "$#" -eq 1 ] || { echo "usage: $(basename "$0") <dest-dir>" >&2; exit 2; }
mkdir -p "$1"; DEST="$(cd "$1" && pwd)"
fail(){ echo "FATAL: $1" >&2; exit 1; }

A="$DEST/adempiere"
if [ ! -d "$A/.git" ]; then
  git clone -q --filter=blob:none --no-checkout https://github.com/adempiere/adempiere.git "$A"
  git -C "$A" sparse-checkout set db/ddlutils/oracle/functions db/ddlutils/oracle/procedures db/ddlutils/oracle/views
fi
git -C "$A" -c advice.detachedHead=false checkout -q "$SHA"
[ "$(git -C "$A" rev-parse HEAD)" = "$SHA" ] || fail "clone is not at $SHA"
O="$A/db/ddlutils/oracle"

rm -rf "$DEST/t2" "$DEST/t3" "$DEST/t5" "$DEST/plugin-3400"
mkdir -p "$DEST/t2/o1-corpus" "$DEST/t3/o3-corpus" "$DEST/t5/dbonly1" "$DEST/plugin-3400/skills"
cp "$O"/functions/* "$DEST/t2/o1-corpus/"
cp "$O"/functions/* "$O"/procedures/* "$O"/views/* "$DEST/t3/o3-corpus/"

cp "$ROOT"/tests/sproc-planning-dbonly/dbonly1/sql/* "$DEST/t5/dbonly1/"
P="$DEST/t5/dbonly1/prc_finalize_order.sql"
sed -n 18p "$P" | grep -q 'g_batch_total :=' || fail "prc_finalize_order.sql:18 is not the g_batch_total write"
DYN="  EXECUTE IMMEDIATE 'BEGIN prc_reset_batch_totals; END;';"
awk -v d="$DYN" 'NR==18 {print; print ""; print "  -- Dynamic call (reduced-confidence edge)"; print d; next} 1' "$P" > "$P.tmp" && mv "$P.tmp" "$P"

cp -R "$ROOT/.claude-plugin" "$DEST/plugin-3400/"
cp -R "$ROOT/skills/sproc-xray" "$DEST/plugin-3400/skills/"
S="$DEST/plugin-3400/skills/sproc-xray/SKILL.md"
[ "$(grep -c 'LIMIT=[0-9]' "$S")" -eq 1 ] || fail "expected exactly one LIMIT=<n> in SKILL.md"
sed 's/LIMIT=[0-9][0-9]*/LIMIT=3400/' "$S" > "$S.tmp" && mv "$S.tmp" "$S"
[ "$(grep -c 'LIMIT=3400' "$S")" -eq 1 ] || fail "LIMIT=3400 not set"

count(){ ls "$1" | wc -l | tr -d ' '; }
bytes(){ cat "$1"/* | wc -c | tr -d ' '; }
[ "$(count "$DEST/t2/o1-corpus")" = 50 ] && [ "$(bytes "$DEST/t2/o1-corpus")" = 122831 ] || fail "T2 corpus is not 50 files / 122,831 bytes"
[ "$(count "$DEST/t3/o3-corpus")" = 250 ] && [ "$(bytes "$DEST/t3/o3-corpus")" = 579953 ] || fail "T3 corpus is not 250 files / 579,953 bytes"
[ "$(count "$DEST/t5/dbonly1")" = 12 ] && [ "$(grep -cF "$DYN" "$P")" = 1 ] || fail "T5 corpus is not 12 files with one dynamic call"
echo "$DEST"
