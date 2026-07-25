# Critical Design Review: 2026-07-25-bug-fixing-workflow-design (Round 2)

**Spec:** `~/peters-toolkit/docs/specs/2026-07-25-bug-fixing-workflow-design.md`
**Verified Assumptions section:** present

## 0. Coverage enumeration

**Sections**

| Row | Disposition |
|-----|-------------|
| §1 Purpose & scope | ok — scope bounds unchanged; consistent with §2 |
| §2 Decisions D1–D11 | ok — new D11 (status advisory + comment fallback) consistent with §5/§7/§9; D9 still consistent with §3 |
| §3.1 Stage pipeline | ok — Stage 3 now `using-git-worktrees → test-driven-development`; Stage 6 `implement` only; delegate columns consistent |
| §3.2 Two paths | ok — trivial bullet now states worktree created at Stage 3; numeric sequences unchanged and consistent with the table |
| §3.3 Gates | ok — G1/G2/G8 (+G4/G5) unchanged and consistent |
| §3.4 systematic-debugging relationship | ok — "stages 2/3/6/7 delegate" still holds after Stage 3/6 relabel |
| §4 Bug-info contract | → dropped candidate (mechanical tier "set-status capability" wording vs D11) — see rules |
| §4.1 Needs-info loop | ok — sets needs-info via adapter; now covered by D11 fallback |
| §5 Tracker adapter contract | ok — new advisory-status paragraph consistent with D11/§7; `listCandidates` filters natively (no status round-trip) |
| §6 Build vs reuse | ok — reuse list unchanged; still no `executing-plans` |
| §7 Harness configuration | ok — status-model row rewritten to the D11 mapping; source note narrowed to the one verified label |
| §8 Worked examples | ok — trivial example now "3 isolate (worktree) + failing test → 6 direct fix"; matches §3.1/§3.2 |
| §9 Verified assumptions | → §1 cross-check |
| §10 Generic/harness boundary | ok — boundary rule unaffected by the edits |
| §11 Path to autonomy | ok — unchanged |
| §12 Next steps | ok — unchanged |

**Rules and operands**

| Rule | Both directions checked | Disposition |
|------|-------------------------|-------------|
| R1 Trivial/non-trivial classification | (unchanged from R1) over-/under-ceremony, human-confirmed, downstream gates intact | dropped — no literal break (already dispositioned round 1) |
| R2 Needs-info trigger | (unchanged) false-proceed blocked by reproduce-or-gather / false-ask is annoyance | dropped — no literal break |
| R3 setStatus vocabulary → provider mapping | over: unrepresentable status → now falls back to comment (D11) / under: covered by comment fallback | ok — resolved by D11; no status silently lost |
| R4 Close-on-merge via native PR linkage | GitHub keyword closes issue; done == closed | ok |
| R5 Advisory-status invariant (D11/§5): core never reads status back | read side: `listCandidates` filters via adapter-native query, not the workflow vocabulary; no core branch consumes a status the core set | ok — invariant holds across §0/§3.1/§4.1; no load-bearing read exists |
| §4 mechanical tier lists "comment + **set-status capability**" as adapter-guaranteed | candidate: contradicts D11 (set-status degrades to comment ⇒ not required) ⇒ a builder might exclude a comment-only tracker (D4) | dropped — §5/D11 define `setStatus` as native-or-comment, so "set-status capability" is satisfiable via comments for any tracker; read whole-spec it is consistent, not a literal break. Loose wording only; clarity nits are out of scope |

**Data-flow arrows**

| Arrow (→ operation) | Check | Disposition |
|---------------------|-------|-------------|
| Stage 3 `using-git-worktrees` → `test-driven-development` (write+run failing test) | test now authored inside the worktree created in the same stage ⇒ lands on the fix branch | ok — round-1 §2.1 defect resolved (→ §4) |
| Stage 4 `thorough-brainstorming` → Stage 5 `thorough-writing-plans` | strict-input-contract spec produced upstream (non-trivial path); artifacts commit onto the branch created at Stage 3 | ok |
| Stage 5 → Stage 6 `subagent-driven-development` | consumes the plan (non-trivial only); trivial = direct fix, no plan | ok |
| Stage 0 / 4.1 / 9 `setStatus(in-progress|needs-info|in-review)` | each maps to native mechanism or comment fallback (D11) | ok — round-1 §3.1 forced decision resolved (→ §4) |
| Stage 9 `finishing-a-development-branch` → adapter `linkPullRequest` | skill's option 2 pushes + creates the PR (URL producible); stage 9 selects the PR path per "open PR" | ok at design level (constraining the skill's menu to the PR path is implementation → CIR, not CDR) |

## 1. Verified-assumptions cross-check

- "All delegated skills exist" — **reconfirmed** (superpowers set incl. `subagent-driven-development`; toolkit set; `umb-review` harness-only).
- "`subagent-driven-development` executes plans; `thorough-writing-plans` points to it" — **reconfirmed.**
- "Peter's Toolkit chain holds" — **reconfirmed.**
- "`systematic-debugging` scope" — **reconfirmed** (Stage 3/6 relabel does not disturb the delegation claim).
- "Toolkit repo layout / .gitignore denylist" — **reconfirmed.**
- "No collision" — **reconfirmed.**
- "Umbraco harness config, with the status narrowing" (edited this round) — **reconfirmed.** Only `state/needs-investigation` is a verified GitHub label (grep of `Umbraco-CMS/.github/`); `done → closed` and `in-progress`/`in-review → comment fallback` are design-handled (§5/§7/D11), leaving no verified-label dependency uncovered.

**Span check.** No uncovered dependency. The one dependency that was uncovered in round 1 (GitHub representation of `in-progress`/`in-review`) is now covered by the advisory + comment-fallback rule (D11/§5) and reflected in the §9 assumption. The `finishing-a-development-branch` PR-creation capability that Stage 9 relies on was verified in-round (its option 2 pushes and opens a PR).

## 2. Literal-wrongness findings

No literal-wrongness findings.

## 3. Forced decisions

No forced decisions found.

## 4. Previously addressed

- **Round 1 §2.1 (failing test authored before workspace isolation)** — resolved. Stage 3 now creates the worktree/branch (`using-git-worktrees`) before authoring the failing test (`test-driven-development`); Stage 6 is implement-only; §3.2 and the §8 example were updated to match. The regression test now lands on the branch that becomes the PR.
- **Round 1 §3.1 (GitHub cannot represent `in-progress`/`in-review`)** — resolved generically. `setStatus` is now advisory/one-way with a per-adapter comment fallback (§5, D11); the GitHub mapping is spelled out in §7; the span-check gap is closed in §9. No per-tracker capability API was added (YAGNI).

## 5. Recommendation

✅ **Approve as-is** — §2 and §3 are both empty. The two round-1 findings are resolved and introduced no new literal-wrongness or forced decisions. The spec is ready for implementation planning (build the tracker adapter and the `bugfix` orchestrator, each via its own `thorough-brainstorming` → `thorough-writing-plans` cycle).
