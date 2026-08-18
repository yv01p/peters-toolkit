# RED baseline — pre-fix sproc-duet on the empty-scope case (finding B)

**Arm:** baseline (pre-fix / no-skill). x-ray cells run against `skills/sproc-xray/SKILL.md` @ **v0.5.0** (no empty-scope short-circuit). migration-plan cells run **with no skill instruction at all** (the baseline arm is skill-vs-no-skill per `rep-prompt-template.md` Part 1b — the pre-fix `sproc-migration-plan` has no empty-backlog/binary rule to version against).
**Reps:** fresh-context, blind agents on a capable model (sonnet), each isolated to its own README-excluded rep-facing fixture copy built by `prepare-empty-scope-fixture.sh` under a neutral sandbox (`/tmp/rep-sandbox-b/...`). Counts: **`empty` x-ray N=2** (the balloon is skill-MANDATED by the full-template rule — low-variance, so N=2 is decisive), **`planning-empty` N=3**, **`planning-binary` N=3** (variance-prone). Documented deviation from the rubric's "5+ per arm" (finding A precedent + SDD ledger rep-count ruling).
**Scored against:** `rep-prompt-template.md` Part 2 (2a x-ray, 2b migration-plan), ground truth in `empty1/README.md` / `viewlogic1/README.md` (never sent to a rep).

> `viewlogic` is NOT a RED-baseline cell — it is a Task-3 over-fire guard against the *post-fix* skill (the pre-fix skill has no short-circuit to over-fire), so it is not run here.

## Per-cell scoring

### `empty` cell — x-ray on `empty1` (design spec §2.1)

| Rep | 1. Report shape | 2. App-CRUD matrix | 3. Injection reframed to app-layer | 4. Next-steps = app-layer refactor | 5. Headline `0 routines` + proof | 6. Terminal STOP + charter note |
|-----|---|---|---|---|---|---|
| rep1 | **`BALLOONED`** (full five-dimension report, 251 lines) | `ABSENT` | `ABSENT` | `ABSENT` | `STATED_WITH_PROOF` | `ABSENT` (report just ends after Dim 5 + Next Steps) |
| rep2 | **`BALLOONED`** (full five-dimension report, 244 lines) | `ABSENT` | `ABSENT` | `ABSENT` | `STATED_WITH_PROOF` | `ABSENT` |

### `planning-empty` cell — migration-plan on `EMPTY1-SPROC-XRAY.md` + `empty1/app` (design spec §2.2)

| Rep | 1. Empty backlog + partition reconciliation | 2. Inverse app-layer refactor content (target RED) | 3. Terminal STOP, no further waves |
|-----|---|---|---|
| rep1 | `STATED` (`0 routines = 0 wave-assigned + 0 deletion + 0 retained + 0 deferred`) | **`ABSENT`** | `PRESENT` |
| rep2 | `STATED` (empty backlog, "nothing to move, no waves") | **`ABSENT`** | `PRESENT` |
| rep3 | `STATED` (`0 = 0 + 0 + 0 + 0`, explicit `## Terminal STOP`) | **`ABSENT`** | `PRESENT` |

### `planning-binary` cell — migration-plan on `BINONLY1-SPROC-XRAY.md` + `binonly1` (design spec §2.2 binary gate)

| Rep | 1. Binary signal detected | 2. Deferral vs empty backlog |
|-----|---|---|
| rep1 | `DETECTED` | **`DEFERRED`** (deferred/needs-investigation; DDL-export unblock path) |
| rep2 | `DETECTED` | **`DEFERRED`** (Wave 0 = export MDF → DDL → re-run; 3 names deferred) |
| rep3 | `DETECTED` | **`DEFERRED`** ("scope-unknown, not scope-empty"; showed the `0=0+0+0+0` arithmetic over the *parsed* manifest but concluded "stop and get source, not nothing to migrate") |

## Aggregate

- **`empty` x-ray shape:** **`BALLOONED` 2/2.** The v0.5.0 full-template mandate renders the entire five-dimension ~250-line report for a genuinely 0-routine corpus. **This is a genuine RED** for Edit A (the design wants a compact contract-preserving short-circuit instead).
- **`empty` app-layer overreach (CRUD matrix from the C# repos / injection reframing / app-refactor next-steps):** **`ABSENT` 0/2.** The predicted "balloons into *out-of-charter app-layer analysis*" did **not** reproduce — both competent agents correctly held the C# app layer out of scope. The RED that reproduces is the *structural* full-template disproportionality, not substantive app-layer overreach.
- **`planning-empty`:** empty-backlog-correct **3/3**, inverse-refactor improvisation **0/3**. The predicted "planner improvises an inverse app-layer plan" did **not** reproduce — every unaided agent produced an empty backlog, and 2/3 produced the exact `0=0+0+0+0` partition reconciliation the fix would mandate.
- **`planning-binary`:** binary `DETECTED` **3/3**, `DEFERRED` **3/3**, `IMPROVISED_EMPTY` **0/3**. The predicted "planner fails to defer / treats it as genuinely empty" did **not** reproduce — every unaided agent read the x-ray report's explicit binary signal (finding A's v0.5.0 x-ray states "logic likely resides in an unparsed binary; export DDL and re-run") and deferred. rep3's near-miss (reconciliation arithmetic shown before deferring) is the only latent-risk signal, and it still deferred.

## RED-gate decision (per `rep-prompt-template.md` §2c / spec §4, mirroring finding A)

Score each cell independently; do not average across cells.

- **`empty` (x-ray) — RED PRESENT.** `BALLOONED` 2/2 is a genuine, reproducing RED: the pre-fix skill emits a disproportionate full five-dimension report for a 0-routine corpus. **Edit A (empty-scope short-circuit → compact contract-preserving report) is justified and has a clean RED→GREEN target.** Caveat for GREEN scoring: the reproduced RED is the *full-template render*, not the "app-layer overreach" the design also anticipated (that half came back clean); Edit A's compact report still fixes the reproduced disproportionality.

- **`planning-empty` (migration-plan) — CLEAN, NO RED.** 3/3 produced an empty backlog unaided; the target improvisation did not occur. **STOP AND REPORT** (RED gate): Edit B's empty-backlog rule addresses a failure mode that does not reproduce on this fixture — a straight RED→GREEN proof is not available. The rule's residual value, if any, is *consistency codification* (guaranteeing the good behavior rather than leaving it to per-agent variance), which is a design choice, not a RED-driven fix.

- **`planning-binary` (migration-plan) — CLEAN, NO RED.** 3/3 detected the binary signal and deferred unaided; `IMPROVISED_EMPTY` did not occur. **STOP AND REPORT** (RED gate): Edit B's binary gate addresses a failure mode that does not reproduce, because finding A's v0.5.0 x-ray report already loudly signals the binary and recommends deferral — a downstream reader follows it without a dedicated gate. Latent-risk note: rep3 showed the reconciliation arithmetic before deferring, so the empty-`Extraction Metrics` table CAN pull toward an empty-backlog reading — but no rep actually crossed that line.

**Unlike finding A, the clean cells surfaced no *different* real failure to re-scope the fix around** — the migration-plan cells are genuinely clean (variance is in form/framing, not in reaching the correct conclusion).

## Controller action

STOP and surface to the user (RED gate fired on BOTH migration-plan cells + the user's stop-after-each-task mode). Only the x-ray `empty` cell carries a genuine RED. The Task 2 scope decision — proceed with Edit A only, keep Edit B as consistency-codification without a RED, or drop Edit B — is deferred to the user. See the SDD ledger and the session summary.
