#!/usr/bin/env node
// Deterministic, offline resume signal for the bugfix orchestrator (spec §4.1).
// Pure computeStage() (unit-tested) + thin git/fs I/O, mirroring the adapter's
// projectIssue()/runGh() split.
import { execFileSync } from 'node:child_process';
import { readdirSync } from 'node:fs';

// branches: raw `git branch --list <glob>` lines (may carry `* `/`+ `/`  ` prefixes)
// artifacts: { specs: string[], plans: string[] } — filenames in the configured dirs
export function computeStage({ branches, artifacts }) {
  return branches
    .map((line) => line.replace(/^[*+]?\s+/, '').trim())   // strip current/worktree markers
    .filter(Boolean)
    .map((branch) => ({ branch, id: parseId(branch) }))
    .filter((b) => b.id !== null)
    .map(({ branch, id }) => {
      const hasDesign = artifacts.specs.some((f) => f.includes(id));
      const hasPlan = artifacts.plans.some((f) => f.includes(id));
      const phase = !hasDesign ? 'branch cut' : !hasPlan ? 'design done' : 'plan done';
      return { id, branch, phase };
    });
}

// id = leading digits of the branch's last '/'-segment (GitHub numeric ids).
// Jira-style keys (PROJ-123) are deferred with the Jira provider (spec §18).
function parseId(branch) {
  const seg = branch.split('/').pop() ?? '';
  const m = seg.match(/^(\d+)/);
  return m ? m[1] : null;
}

export function gatherInputs(glob, specsDir, plansDir) {
  const branches = execFileSync('git', ['branch', '--list', glob], { encoding: 'utf8' })
    .split('\n').filter(Boolean);
  return { branches, artifacts: { specs: safeReaddir(specsDir), plans: safeReaddir(plansDir) } };
}

function safeReaddir(dir) {
  try { return readdirSync(dir); } catch { return []; }   // dirs created on first write (spec Finding 3)
}

// CLI: node status.mjs <branch-glob> <specs-dir> <plans-dir> [id]
if (import.meta.url === `file://${process.argv[1]}`) {
  const [glob, specsDir, plansDir, id] = process.argv.slice(2);
  let results = computeStage(gatherInputs(glob, specsDir, plansDir));
  if (id) results = results.filter((r) => r.id === id);
  console.log(JSON.stringify(results, null, 2));
}
