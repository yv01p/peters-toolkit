#!/usr/bin/env bash
# Not hermetic: checks the toolkit against the INSTALLED Superpowers, a hard requirement.
# Breakage (exit 1): a superpowers:<name> that skills/ references is missing upstream, or
# SDD's task-brief can't extract a task from thorough-writing-plans' own plan template.
# Drift (UPSTREAM DRIFT notice, exit 0): a forked companion file differs from upstream's,
# or the installed major.minor differs from the provenance manifest's target.
# Usage: check-superpowers-compat.sh [SUPERPOWERS_DIR]   (default: the installed plugin)
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MANIFEST="tests/provenance/companion-manifest.sha256"

SP=""
if [ $# -ge 1 ]; then
  SP="$(cd "$1" 2>/dev/null && pwd)"
else
  SP=$(node -e '
    try {
      const p = require(require("os").homedir() + "/.claude/plugins/installed_plugins.json").plugins || {};
      const k = Object.keys(p).find(k => k.startsWith("superpowers@"));
      if (k && p[k][0]) console.log(p[k][0].installPath);
    } catch (e) {}')
fi
if [ -z "$SP" ] || [ ! -d "$SP/skills" ]; then
  echo "ERROR: no Superpowers install found (it is a hard requirement)" >&2
  exit 1
fi
cd "$ROOT"

err=0
# 1) every superpowers:<name> that skills/ references exists upstream
for name in $(grep -rhoE 'superpowers:[a-z-]+' skills | sort -u | cut -d: -f2); do
  if [ ! -f "$SP/skills/$name/SKILL.md" ]; then
    echo "ERROR: skills/ references superpowers:$name, which $SP does not have" >&2
    err=1
  fi
done

# 2) SDD's task-brief extracts Task 1, and only Task 1, from TWP's plan template
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
awk '/^### Body structure/{p=1;next} /^### Deliberately NOT in the body/{p=0} p' \
  skills/thorough-writing-plans/SKILL.md | sed '1,/^```markdown/d' > "$tmp/plan.md"
if ! { bash "$SP/skills/subagent-driven-development/scripts/task-brief" "$tmp/plan.md" 1 "$tmp/task1.md" >/dev/null 2>&1 \
       && grep -q '^### Task 1:' "$tmp/task1.md" && ! grep -q '^### Task 2' "$tmp/task1.md"; }; then
  echo "ERROR: SDD's task-brief can't extract Task 1 from thorough-writing-plans' plan template" >&2
  err=1
fi

# 3) drift: each forked companion file against upstream's
for rel in $(grep -v '^#' "$MANIFEST" | awk 'NF {print $2}' | sed 's#^skills/thorough-brainstorming/##'); do
  cmp -s "skills/thorough-brainstorming/$rel" "$SP/skills/brainstorming/$rel" \
    || echo "UPSTREAM DRIFT: companion $rel differs from $SP/skills/brainstorming/$rel"
done

# 4) drift: installed major.minor against the manifest's target
ver=$(node -e 'try { console.log(JSON.parse(require("fs").readFileSync(process.argv[1], "utf8")).version) } catch (e) {}' "$SP/package.json")
tgt=$(grep -m1 -oE '^# target: [0-9]+\.[0-9]+\.x' "$MANIFEST" | grep -oE '[0-9]+\.[0-9]+')
[ "${ver%.*}" = "$tgt" ] || echo "UPSTREAM DRIFT: installed ${ver:-unknown}, toolkit targets $tgt.x — run the upstream review"

[ "$err" -eq 0 ] || exit 1
echo "superpowers-compat OK (installed ${ver:-unknown}, target $tgt.x)"
