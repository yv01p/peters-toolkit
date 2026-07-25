import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

// --- Pure projection (unit-tested; no I/O) ------------------------------------
export function projectIssue(gh) {
  return {
    id: gh.number,
    title: gh.title,
    body: gh.body,
    comments: (gh.comments ?? []).map((c) => ({
      author: c.author,        // faithful dump: {login, ...} passed through (TA7)
      body: c.body,
      createdAt: c.createdAt,
    })),
    labels: (gh.labels ?? []).map((l) => l.name),
    severity: undefined,       // GitHub has no native severity field (A6)
    attachments: [],           // no native field (A6)
    links: [],                 // no structured field in v1 (A6)
  };
}

// --- Thin I/O wrapper (the only part that shells out) -------------------------
function runGh(args, input) {
  return execFileSync('gh', args, { input, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
}

// --- Error helper: emit contract error JSON on stdout, exit nonzero ----------
// NOTE: Must NOT call process.exit() — it terminates before async pipe writes
// flush, truncating large output (esp. getTicket JSON). Set exitCode and let
// Node flush naturally.
function fail(code, message) {
  process.stdout.write(JSON.stringify({ error: message, code }) + '\n');
  process.exitCode = 1;
}

function ok(obj) {
  process.stdout.write(JSON.stringify(obj) + '\n');
  process.exitCode = 0;
}

// --- Verb handlers (GitHub reference provider) -------------------------------
function getTicket(id) {
  if (!id) return fail('bad_args', 'getTicket requires <id>');
  const out = runGh(['issue', 'view', id, '--json', 'number,title,body,comments,labels']);
  ok(projectIssue(JSON.parse(out)));
}

function assign(id, who) {
  if (!id || !who) return fail('bad_args', 'assign requires <id> <who>');
  runGh(['issue', 'edit', id, '--add-assignee', who]);
  ok({ ok: true });
}

function setStatus(id, name, rest) {
  if (!id || !name) return fail('bad_args', 'setStatus requires <id> <name> [--label <label>]');
  const li = rest.indexOf('--label');
  const label = li !== -1 ? rest[li + 1] : undefined;
  if (label) {
    runGh(['issue', 'edit', id, '--add-label', label]);
    ok({ ok: true, via: 'label' });
  } else {
    runGh(['issue', 'comment', id, '--body-file', '-'], `→ ${name}`);
    ok({ ok: true, via: 'comment' });
  }
}

function comment(id) {
  if (!id) return fail('bad_args', 'comment requires <id> and markdown on stdin');
  const md = readFileSync(0, 'utf8');        // markdown from stdin
  const out = runGh(['issue', 'comment', id, '--body-file', '-'], md);
  ok({ ok: true, url: out.trim() });
}

function linkPullRequest(id, url) {
  if (!id || !url) return fail('bad_args', 'linkPullRequest requires <id> <url>');
  runGh(['issue', 'comment', id, '--body', `Linked PR: ${url}`]);
  ok({ ok: true });
}

// --- Dispatch ----------------------------------------------------------------
function main(argv) {
  const [provider, verb, ...rest] = argv;
  if (provider === 'jira') return fail('not_implemented', "provider 'jira' not implemented");
  if (provider !== 'github') return fail('unknown_provider', `unknown provider: ${provider ?? '(none)'}`);

  try {
    switch (verb) {
      case 'getTicket':       return getTicket(rest[0]);
      case 'assign':          return assign(rest[0], rest[1]);
      case 'setStatus':       return setStatus(rest[0], rest[1], rest.slice(2));
      case 'comment':         return comment(rest[0]);
      case 'linkPullRequest': return linkPullRequest(rest[0], rest[1]);
      case 'listCandidates':  return fail('not_implemented', 'listCandidates is deferred (spec §9)');
      default:                return fail('unknown_verb', `unknown verb: ${verb ?? '(none)'}`);
    }
  } catch (err) {
    // runGh threw → gh exited nonzero; carry its stderr
    const msg = (err.stderr && err.stderr.toString().trim()) || err.message;
    return fail('gh_error', msg);
  }
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  main(process.argv.slice(2));
}
