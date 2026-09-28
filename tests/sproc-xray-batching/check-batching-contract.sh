#!/usr/bin/env bash
# Hermetic: asserts sproc-xray SKILL.md carries the batched-run contract (#8): the coordinator's
# plan / dispatch / combine steps, the Batch Worker section, absolute paths, and the proof
# command-file rule. Spec test T1. No network / install.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/sproc-xray/SKILL.md"

err=0
need(){ grep -qF "$1" "$SKILL" || { echo "FAIL (missing): $2" >&2; err=1; }; }
absent(){ grep -qF "$1" "$SKILL" && { echo "FAIL (present): $2" >&2; err=1; }; }

need '## Batch Worker'                                        'Batch Worker section'
need "Follow SKILL.md's Batch Worker section"                 'dispatch brief'
need '**Dispatch (MANDATORY when the harness has a subagent tool).**' 'MANDATORY dispatch wording'
need 'batches.tsv'                                            'batch plan file'
need 'always go in the same batch'                            'package spec/body grouping rule'
for f in '<WORK>/batch-NN/done' 'ext.tsv' 'proof-metrics.md' 'proof-findings.md' 'd2.md' 'd4.md' 'd5.md'; do
  need "$f" "batch-NN/ file name $f"
done
need '**Completeness gate, per batch, by command.**'          'completeness gate'
need '<WORK>/parts/00-exec.md'                                'part-file assembly'
need '**Absolute paths only:**'                               'absolute-path rule'
need "<<'EOF'"                                                'proof command-file rule (quoted heredoc)'
need 'cmd-K.out'                                              'proof command-file rule (stored output)'
absent 'Format as indented tree or Mermaid diagram'            'dependency graph must be Mermaid only'
absent 'every bare-filename proof-block command resolves here' 'cwd-reliant Step 1 text must be gone'
absent 'Use subagents to parallelize where dimensions are independent' 'old Step 4 suggestion must be gone'
grep -n '\$[0-9]' "$SKILL" >&2 && { echo 'FAIL (present): $N field reference; Claude Code substitutes skill arguments for $0, $1, ... in SKILL.md, write $(N)' >&2; err=1; }

if [ "$err" -ne 0 ]; then echo "sproc-xray batching contract: FAIL" >&2; exit 1; fi
echo "sproc-xray batching contract OK"
