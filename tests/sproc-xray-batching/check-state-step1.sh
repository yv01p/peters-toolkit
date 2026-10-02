#!/usr/bin/env bash
# Hermetic: regression test for the Oracle GLOBAL_STATE STEP 1 command in the dialect file (#13).
# STEP 1 is the only source of state.tsv's names in a batched run. Extracts the command verbatim
# (the lines between the "# STEP 1" and "# STEP 2" comments, minus comment lines), runs it with
# a fixture dir as cwd (the command reads sql/*), and checks which File:Line rows it prints.
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DIALECT="$ROOT/skills/sproc-xray/references/dialects/oracle.md"

fail(){ echo "FAIL: $1" >&2; exit 1; }

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

# --- Extract STEP 1 verbatim ---
s1=$(grep -n '^# STEP 1 ' "$DIALECT" | head -1 | cut -d: -f1)
s2=$(grep -n '^# STEP 2 ' "$DIALECT" | head -1 | cut -d: -f1)
[ -n "$s1" ] && [ -n "$s2" ] || fail "could not find the GLOBAL_STATE STEP 1 / STEP 2 comments in oracle.md"
sed -n "$((s1+1)),$((s2-1))p" "$DIALECT" | grep -v '^#' > "$TMPROOT/step1.sh"
[ -s "$TMPROOT/step1.sh" ] || fail "STEP 1 has no command lines between :$s1 and :$s2"

# --- Fixture ---
F="$TMPROOT/run"
mkdir -p "$F/sql"
# Control: one-line header (works before the fix).
cat > "$F/sql/oneline.pks" <<'EOF'
CREATE OR REPLACE PACKAGE pkg_one AS
  g_count NUMBER := 0;
  PROCEDURE p1;
END pkg_one;
/
EOF
# Split after OR REPLACE.
cat > "$F/sql/split.pks" <<'EOF'
CREATE OR REPLACE
PACKAGE pkg_split AS
  g_total NUMBER := 0;
  PROCEDURE p2;
END pkg_split;
/
EOF
# Split after EDITIONABLE, indented PACKAGE BODY.
cat > "$F/sql/split.pkb" <<'EOF'
CREATE OR REPLACE EDITIONABLE
  PACKAGE BODY pkg_split AS
  l_cache VARCHAR2(10);
  PROCEDURE p2 IS BEGIN g_total := g_total + 1; END;
END pkg_split;
/
EOF
# One keyword per line.
cat > "$F/sql/tall.pks" <<'EOF'
CREATE
OR
REPLACE
PACKAGE
pkg_tall
AS
  c_limit CONSTANT NUMBER := 10;
  FUNCTION f RETURN NUMBER;
END pkg_tall;
/
EOF

( cd "$F" && bash "$TMPROOT/step1.sh" ) > "$TMPROOT/out" 2> "$TMPROOT/err" \
  || fail "STEP 1 exited non-zero: $(cat "$TMPROOT/err")"

# Every package-level declaration, with its own File:Line.
for want in \
  'sql/oneline.pks:2:   g_count NUMBER := 0;' \
  'sql/split.pks:3:   g_total NUMBER := 0;' \
  'sql/split.pkb:3:   l_cache VARCHAR2(10);' \
  'sql/tall.pks:7:   c_limit CONSTANT NUMBER := 10;'
do
  grep -qxF "$want" "$TMPROOT/out" || fail "missing STEP 1 row: $want
Got:
$(cat "$TMPROOT/out")"
done

# The region still closes at the first nested PROCEDURE/FUNCTION.
if grep -qE ':[[:space:]]+(PROCEDURE|FUNCTION|END)[[:space:]]' "$TMPROOT/out"; then
  fail "STEP 1 printed lines past a region's first PROCEDURE/FUNCTION:
$(cat "$TMPROOT/out")"
fi

echo "PASS: GLOBAL_STATE STEP 1 opens a region on one-line and split package headers"
