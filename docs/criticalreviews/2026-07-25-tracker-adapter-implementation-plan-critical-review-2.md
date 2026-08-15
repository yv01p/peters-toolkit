# Critical Implementation Review: 2026-07-25-tracker-adapter-implementation-plan (Round 2)

**Plan:** ~/peters-toolkit/docs/plans/2026-07-25-tracker-adapter-implementation-plan.md
**Verified plan-level assumptions section:** present

_No drift note: `git log --oneline 6d36d76..HEAD` is empty (repo HEAD == plan-write SHA `6d36d76`)._

_Coverage re-derived from scratch this round (per the iterative-review discipline). Round 1's `maxBuffer` fix is a single §0 row below, not the search area. Round 1's findings — the §2.1 `maxBuffer`/`ENOBUFS` issue and the dropped `process.exit` stdout-flush candidate — are not re-raised (never-re-raise rule)._

## 0. Coverage enumeration

**Task 1 — surfaces**

- T1 Interfaces (Produces CLI contract + `projectIssue`) — `ok — matches Step 4 impl; contract cross-checked against Task 2 docs (C1)`.
- T1 Step 1 whitelist code + prose — `ok — re-read .gitignore: whitelist block is lines 16–28, slot after !/skills/tma/ (26) before !/skills/update-design-doc/ (27); alphabetical order holds (tma < tracker-adapter < update-design-doc)`.
- T1 Step 2 fixture JSON — `ok — parses; 2 comments, labels in asserted order, comment author is object {login}; unchanged since Round 1 where values were validated`.
- T1 Step 3 test code — `ok — 4 test() calls; every assertion matches projectIssue output (see C2)`.
- T1 Step 4 `adapter.mjs`: `projectIssue` — `ok — id/title/body/comments/labels/empty-fields as tested`; `runGh` — `ok — now sets maxBuffer: 64*1024*1024 (line 202); Round 1 fix in place, covered by assumption #15`; `fail`/`ok` — `ok — write-then-exit; process.exit truncation was examined and dropped in Round 1, not re-raised`; verb handlers — `ok — getTicket/assign/setStatus/comment/linkPullRequest + listCandidates stub all present; comment's readFileSync(0,'utf8') stdin read verified working on all realistic paths (Probe E)`; dispatch/`main` try-catch — `ok — five error codes each reachable; exit-based handlers never fall through to the catch`.
- T1 Step 5 command (`node --test <file>`) — `ok — explicit-file form exits 0 on v24.18.0; 4 tests → "pass 4"`.
- T1 Step 6 command (git add specific paths + commit) — `ok — whitelist (Step 1) precedes this add so skill paths are tracked; no -A/-f`.
- T1 Step 7 deferred manual smoke test — `ok — explicitly out of the shipped suite; write-scope-gated`.

**Task 2 — surfaces**

- T2 Interfaces (Consumes Task 1 CLI, verb-for-verb) — `ok — see C1`.
- T2 Step 1 `SKILL.md` frontmatter + 6 body sections — `ok — frontmatter (name/version/description) matches sproc-xray/SKILL.md:1-5; status rule, needs-info checklist, error codes trace to spec §4/§6 and umbrella §4`.
- T2 Step 2 `references/github.md` — `ok — transcribes spec §5; verb→gh table matches impl`.
- T2 Step 3 `references/jira.md` — `ok — transcribes spec §8; provider=jira exits not_implemented per dispatch`.
- T2 Step 4 git — `ok — three paths under whitelisted subtree`.
- T2 Step 5 `bash tests/run-tests.sh` — `ok — read both guards in full this round: lockstep compares only plugin.json/README/CHANGELOG version markers + Superpowers-target string (does NOT enumerate skills or read skill version: frontmatter), and provenance sha256-checks only 6 thorough-brainstorming files + greps skills/ for removed tokens (new skill contains none). A new skill at version 1.0.0 keeps the suite green — confirms assumption #4`.

**Cross-task interface contracts**

- C1 (Task 1 CLI contract → Task 2 docs) — `ok — six verbs, gh commands, success shapes ({ok:true}, {ok,via}, {ok,url}) and the {error,code} failure JSON match verb-for-verb`.
- C2 (fixture file → test, **persistence boundary**) — `ok — Step 2 writes exactly the keys Step 3 reads; asserted counts/order/values satisfied`.

**Rule-like content (both directions)**

- R1 `setStatus` label-else-comment — `ok — --label present → add-label; absent → comment "→ <name>"; missing value degrades to comment`.
- R2 `projectIssue` projection (label flatten / comment shape / empty fields) — `ok — over/under-inclusion both hold against fixture; no fields added`.
- R3 `import.meta.url === pathToFileURL(process.argv[1]).href` dispatch gate — `ok — main() runs only on direct execution; test import does not trigger it`.
- R4 error-code classification — `ok — each of the five codes has a reachable trigger; the ENOBUFS→gh_error mislabel path (Round 1) is now unreachable via getTicket since maxBuffer prevents the throw`.
- R5 `comment` stdin read (`readFileSync(0)`) — `ok — Probe E: reads correctly via shell pipe, execFileSync input option, and multi-line heredoc`.

## 1. Verified-plan-assumptions cross-check

Fresh read of the cited evidence for each of the 15 listed assumptions (14 unchanged from Round 1 + new #15):

1. `skills/tracker-adapter/` absent — **still holds** (`ls -d` → No such file or directory).
2. `.gitignore` whitelist block lines 16–28; slot after `!/skills/tma/` (26) before `!/skills/update-design-doc/` (27) — **still holds** (re-read `.gitignore`).
3. Ordering hazard — skill files ignored until whitelist exists — **still holds** (`.gitignore:15` = `/skills/*`).
4. Consumer impact — `tests/run-tests.sh` stays green — **still holds**, now fully grounded: read `check-version-lockstep.sh` in full (compares only plugin/README/CHANGELOG version + Superpowers-target; no skill enumeration) and `check-companion-provenance.sh` + manifest (6 `thorough-brainstorming` files; removed-token grep). New skill affects neither.
5. `node --test <dir>` fails; explicit-file form works — **still holds** (Probe B, Round 1).
6. ESM export importable + `import.meta.url` dispatch gate — **still holds** (standard ESM on v24.18.0).
7. `.mjs` runs as ESM without `package.json "type"` — **still holds**.
8. `execFileSync('gh', args, {input, encoding})` pipes input + throws on nonzero exit with `.status`/`.stderr`/`.stdout` — **still holds** (now paired with #15 which covers the output-size dimension it was silent on).
9. `comments[].author` object `{login}`; `labels[].name` — **still holds** (fixture-replicated).
10. `gh issue comment --body-file -` reads stdin, prints comment URL to stdout — **still holds** as stated (help-verified for `--body-file -`; URL-to-stdout deferred to the Step 7 smoke test, as the plan says).
11. Six verbs map to dispatch branches — **still holds** (read impl dispatch).
12. Five error codes each have a trigger — **still holds**.
13. Eight `Ticket` fields sourced/empty + tested — **still holds** (fixture-replicated).
14. Four statuses through label-else-comment — **still holds**.
15. `execFileSync` default `maxBuffer` is 1 MiB; `runGh` sets `maxBuffer: 64*1024*1024` so `getTicket` stays a complete dump — **still holds**: the plan's `runGh` (line 202) carries `maxBuffer: 64 * 1024 * 1024`; the cited probe (1024 KiB OK / 1100 KiB `ENOBUFS` without it) is reconfirmed from Round 1.

**Span check.** One load-bearing dependency has no dedicated assumption row: `comment`'s adapter-side stdin read (`readFileSync(0, 'utf8')`) — assumptions #8/#10 cover the `gh` side of `--body-file -` but not the adapter reading fd 0. Verified in-round (Probe E: correct read via shell pipe, `execFileSync` input, and heredoc), so it holds — no finding. No other uncovered dependency found.

## 2. Literal-wrongness findings

No literal-wrongness findings.

## 3. Forced decisions

No forced decisions found.

## 4. Previously addressed

- **Round 1 §2.1 — `runGh` omitted `maxBuffer`; `getTicket` failed (ENOBUFS) on issues >1 MiB.** Resolved: Task 1 Step 4's `runGh` now passes `maxBuffer: 64 * 1024 * 1024` (line 202), and the span-check dependency it surfaced is now recorded as assumption #15. The ENOBUFS-mislabeled-as-`gh_error` secondary effect is consequently unreachable via `getTicket`.

## 5. Recommendation

✅ **Approve as-is.** §1 reconfirms all 15 verified plan-level assumptions and the span check found no uncovered dependency (the one surfaced was verified in-round). §2 and §3 are both empty. Round 1's finding is resolved (§4). The plan is ready for `subagent-driven-development`.
