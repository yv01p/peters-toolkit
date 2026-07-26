# Critical Implementation Review: 2026-07-25-tracker-adapter-implementation-plan (Round 1)

**Plan:** ~/peters-toolkit/docs/plans/2026-07-25-tracker-adapter-implementation-plan.md
**Verified plan-level assumptions section:** present

_No drift note: `git log --oneline 6d36d76..HEAD` is empty (repo HEAD == plan-write SHA `6d36d76`)._

## 0. Coverage enumeration

**Task 1 — surfaces**

- T1 prose (Interfaces: Produces CLI contract + `projectIssue`) — `ok — matches impl in Step 4; contract fields cross-checked against Task 2 docs (see C1)`.
- T1 Step 1 prose + code (whitelist `.gitignore`) — `ok — slot after !/skills/tma/ (line 26) before !/skills/update-design-doc/ (line 27) confirmed correct alphabetical position; block is lines 16–28`.
- T1 Step 2 code (fixture `issue-view.json`) — `ok — JSON parses (validated); 2 comments, labels [state/needs-investigation, area/backoffice], comment author is object {login} — all consistent with A2/#9`.
- T1 Step 3 code (`project.test.mjs`) — `ok — 4 tests; every assertion replicated against the fixture and matches projectIssue output byte-for-byte (see C2)`.
- T1 Step 4 code (`adapter.mjs`): `projectIssue` — `ok — id/title/body/comments/labels/empty-fields all as tested`; `fail`/`ok` — `ok — write-then-process.exit; stdout-flush truncation probed and dropped, see below`; verb handlers + dispatch — `ok — six verbs + jira stub + five error codes all present`; `runGh` — `→ §2.1 (default maxBuffer 1 MiB breaks getTicket's faithful-dump promise for large issues)`.
- T1 Step 5 command (`node --test <file>`) — `ok — explicit-file form exits 0 on v24.18.0 (Probe B); expected "pass 4" matches the 4 tests in Step 3`.
- T1 Step 6 command (`git add` specific paths + commit) — `ok — whitelist (Step 1) precedes this add, so skill paths are no longer ignored; no -A/-f`.
- T1 Step 7 commands (deferred manual smoke test) — `ok — explicitly out of the shipped suite; manual, correctly gated on write scope`.

**Task 2 — surfaces**

- T2 prose (Interfaces: Consumes Task 1 CLI contract, must match verb-for-verb) — `ok — see C1`.
- T2 Step 1 prose (`SKILL.md`: frontmatter + 6 body sections) — `ok — frontmatter shape matches sproc-xray/SKILL.md:1-5 (name/version/description); status rule + needs-info checklist + error codes trace to spec §4/§6 and umbrella §4`.
- T2 Step 2 prose (`references/github.md`) — `ok — transcribes spec §5; verb→gh table matches impl exactly`.
- T2 Step 3 prose (`references/jira.md`) — `ok — transcribes spec §8; provider=jira exits not_implemented per impl dispatch`.
- T2 Step 4 command (git add/commit) — `ok — all three paths under whitelisted subtree`.
- T2 Step 5 command (`bash tests/run-tests.sh`) — `ok — provenance guard checks only the 6 companion files + removed-path grep; new skill contains none of the removed tokens; lockstep ignores skills/ (guards read directly)`.

**Cross-task interface contracts**

- C1 (Task 1 CLI contract → Task 2 docs): `ok — all six verbs, their gh commands, success-output shapes ({ok:true}, {ok,via}, {ok,url}), and the {error,code} failure JSON match impl verb-for-verb`.
- C2 (fixture file → test, **persistence boundary**): `ok — Step 2 writes exactly the keys Step 3 reads; test asserts comments.length===2, exact labels order, comment[0] {author,body,createdAt}, typeof comment[1].author==='object' — all satisfied by the written fixture`.

**Rule-like content (both directions)**

- R1 `setStatus` label-else-comment rule — `ok — --label present → add-label branch; absent → comment "→ <name>" branch; missing value degrades to comment (harmless)`.
- R2 `projectIssue` projection (label flatten / comment shape / empty enriching fields) — `ok — over/under-inclusion both checked against fixture; extra comment keys dropped, no fields added`.
- R3 `import.meta.url === pathToFileURL(process.argv[1]).href` dispatch gate — `ok — runs main() only when executed directly; test import does not trigger main (#6, standard ESM)`.
- R4 error-code classification (which throw → which code) — `→ §2.1 — over-inclusion: a non-gh ENOBUFS throw from runGh is classified code:"gh_error" though gh itself succeeded (folded into §2.1)`.

_Dropped candidate (not promoted):_ `fail`/`ok` do `process.stdout.write(...)` then `process.exit()`. Probe D confirms the classic POSIX-pipe truncation *mechanism* exists (a deliberately slow reader received only one 64 KiB pipe buffer of a 600 KiB write). But the plan's actual consumer is the orchestrator capturing output via `child_process`, which drains eagerly — Probe A showed a 552 KB payload (well past the 64 KiB buffer) survived intact across 5 piped runs. `dropped — does not break the spec's outcome on the real consumer path (eager reader); flagging it would be speculation about a slow-reader that the plan's consumer isn't`.

## 1. Verified-plan-assumptions cross-check

Fresh read of the cited evidence for each of the 14 listed assumptions:

1. `skills/tracker-adapter/` absent — **still holds** (`ls -d skills/tracker-adapter` → No such file or directory).
2. `.gitignore` whitelist block lines 16–28; slot after `!/skills/tma/` (26), before `!/skills/update-design-doc/` (27) — **still holds** (read `.gitignore`; positions and alphabetical order confirmed: `tma` < `tracker-adapter` < `update-design-doc`).
3. Ordering hazard — skill files ignored until whitelist exists — **still holds** (`.gitignore:15` = `/skills/*`; whitelist made Task 1 Step 1).
4. Consumer impact — `tests/run-tests.sh` stays green — **still holds** (read both guards: provenance `sha256sum -c` covers only the 6 companion files in the manifest, none in this skill; removed-path grep matches none of `spec-reviewer-prompt|code-quality-reviewer|config/superpowers/worktrees` in the new skill's text; lockstep does not enumerate `skills/`).
5. `node --test <dir>` fails on v24.18.0; explicit-file form works — **still holds** (Probe B: dir form exit 1 `Cannot find module …/tests`; file form exit 0).
6. ESM `export`/import + `import.meta.url` dispatch gate — **still holds** (standard ESM on v24.18.0; consistent with the plan's probe).
7. `.mjs` runs as ESM with no `package.json "type"` — **still holds**.
8. `execFileSync('gh', args, {input, encoding:'utf8'})` pipes `input` to stdin and throws on nonzero exit with `.status`/`.stderr`/`.stdout` — **still holds for what it states**, but it is silent on `maxBuffer`; see the span check below and §2.1.
9. `comments[].author` is object `{login}`; `labels[]` objects with `.name` — **still holds** (fixture-replicated projection matches; consistent with A2).
10. `gh issue comment --body-file -` reads stdin and prints the created comment URL to stdout — **still holds** as the plan states it (help-verified for `--body-file -`; URL-to-stdout is standard `gh` behavior and the plan explicitly defers final confirmation to the Step 7 smoke test).
11. Six contract verbs all map to a dispatch branch — **still holds** (read impl dispatch: `getTicket/assign/setStatus/comment/linkPullRequest` implemented; `listCandidates`/`jira` → `not_implemented`).
12. Five error codes each have a concrete trigger — **still holds** (each code is emitted by a reachable branch). _Note: the `gh_error` branch is also reachable by a non-gh throw — see §2.1 — but the assertion "each code has a trigger" is not itself false._
13. Eight `Ticket` fields each sourced/empty and covered by a test — **still holds** (fixture-replicated).
14. Four statuses resolve through the single label-else-comment rule — **still holds** (read `setStatus`).

**Span check — one uncovered dependency:** `getTicket`'s faithful-complete-dump outcome (spec TA7 — "returns all comments and fields raw") depends on `runGh` being able to capture arbitrarily large `gh issue view` output. Assumption #8 verifies `execFileSync`'s input-piping and throw-on-nonzero-exit, but **not its output-size limit**. That limit is load-bearing and unverified by any listed item. Verified in-round (Probe C, below): the default is 1 MiB and it is exceeded by realistic issues → routed to §2.1 (not left as a §1-only note).

## 2. Literal-wrongness findings

### 2.1 `runGh` omits `maxBuffer`; `getTicket` fails (ENOBUFS) on any issue whose `gh issue view` JSON exceeds 1 MiB — breaking the spec's "faithful, complete dump"

**Description.** Task 1 Step 4's `runGh` is:

```js
function runGh(args, input) {
  return execFileSync('gh', args, { input, encoding: 'utf8' });
}
```

`execFileSync` with no `maxBuffer` uses Node's default of **exactly 1 MiB**. When `gh issue view <id> --json number,title,body,comments,labels` prints more than 1 MiB (a heavily-discussed issue: `--json comments` inlines every comment's full body, plus a large `body` with logs/stack traces), `execFileSync` throws `ENOBUFS` even though `gh` itself exited 0. `getTicket` then falls into `main`'s catch and returns `{error, code:"gh_error"}` with a nonzero exit — so the orchestrator receives an error instead of the ticket. This directly breaks the locked outcome TA7 ("`getTicket` is a faithful, complete dump … returns all comments and fields raw") for large issues, and violates the determinism rationale TA1 explicitly names ("a dropped comment at ingest silently corrupts RCA downstream" — here the entire ingest is lost). The reference harness is `umbraco/Umbraco-CMS`, a large active project where 1 MiB of issue JSON is reachable.

Secondary effect (same root cause): the failure is mis-classified. `main`'s catch comments "runGh threw → gh exited nonzero," but here `gh` **succeeded**; the orchestrator is told `code:"gh_error"` for what is actually a Node buffer-limit error, so any error-code-based branching it does is misled.

**Evidence.**
- Probe C (Node v24.18.0), `execFileSync` with the plan's exact `runGh` option set (`{input, encoding:'utf8'}`, no `maxBuffer`): `512 KiB → OK`, `1024 KiB → OK`, `1100 KiB → THREW code=ENOBUFS errno=-105`, `2048/5120 KiB → ENOBUFS`. Default limit = 1 MiB (1048576 bytes), confirmed exact.
- Mislabeling probe: a child that writes 1100 KiB and exits 0 makes `execFileSync` throw with `err.status === null` (child succeeded); the plan's catch would still emit `{code:"gh_error"}`.
- Plan location: Task 1 Step 4, `runGh` definition (plan lines ~200–202); consumed by `getTicket` (plan lines ~216–220). No listed assumption covers the output-size limit (§1 span check).

**Proposed fix.** Set an explicit, generous `maxBuffer` in `runGh` so ingest is not capped, e.g.:

```js
function runGh(args, input) {
  return execFileSync('gh', args, { input, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
}
```

(Any ceiling comfortably above the largest expected issue JSON works; `64 MiB` leaves wide headroom while still bounding memory. Optionally, distinguish `ENOBUFS`/non-gh throws from real `gh` nonzero exits in `main`'s catch — check `err.status` — so `code:"gh_error"` isn't reported when `gh` actually succeeded; the `maxBuffer` change alone removes this specific path.)

## 3. Forced decisions

No forced decisions found. (§2.1 has an obvious single resolution — raise `maxBuffer` — so it is a literal-wrongness fix, not a codebase-or-product-forced either/or.)

## 5. Recommendation

⚠️ **Approve with literal-wrongness fixes.** §1 reconfirms all 14 listed assumptions but the span check surfaces one uncovered, load-bearing dependency (`execFileSync` output-size limit) that is verified to break the spec's outcome — carried as §2.1. §3 is empty. Address §2.1 (a one-line `maxBuffer` addition to `runGh`, optionally plus the catch's `err.status` disambiguation) before `subagent-driven-development`; proceed afterward via `update-implementation-plan` or a manual edit.
