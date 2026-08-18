# RED baseline — pre-fix `sproc-xray` on binary DB files (finding A)

**Arm:** baseline (pre-fix). `{SKILL_PATH}` = `skills/sproc-xray/SKILL.md` @ v0.4.0, before the binary-DB-file-handling edits.
**Reps:** 3 per corpus (6 total), fresh-context agents on a capable model (sonnet), each isolated to its own rep-facing fixture copy (`prepare-binary-fixture.sh`, README excluded). Rep count is a deliberate reduction from the harness's "5+ per corpus" — see the SDD ledger ruling; the outcome below is unanimous on the headline dimensions and 4/2 split on the contract dimension, so N=3 is decisive here.
**Scored against:** `rep-prompt-template.md` Part 2 (§2a `binonly1`, §2b `mixed1`).

## Per-rep scoring

### `binonly1` (routines only in the binary; targets the silent-zero failure)

| Rep | 1. Binary flagged | 2. Names surfaced & **excluded from counts/Extraction Metrics** | 3. No bare zero | 4. Export next step |
|-----|---|---|---|---|
| rep1 | `FLAGGED` | `SURFACED_EXCLUDED` — 3 names in an "evidence, not a Component Manifest entry" subsection; Component Manifest + Extraction Metrics **empty**; `metrics.tsv` = header row only | `CAVEATED` (explicitly "not nothing here") | `RECOMMENDED` |
| rep2 | `FLAGGED` | **`SURFACED_COUNTED`** — 3 name-only routines written as **rows in the Extraction Metrics table AND `metrics.tsv` AND Dimension-5 `GLOBAL_STATE`**, every metric `Unknown` | `CAVEATED` | `RECOMMENDED` |
| rep3 | `FLAGGED` | **`SURFACED_COUNTED`** — 3 rows in the Extraction Metrics table / `metrics.tsv` (`3 metrics.tsv`), every metric `Unknown` | `CAVEATED` | `RECOMMENDED` |

### `mixed1` (3 `.sql` routines + 2 additional in the binary; targets false source-of-record)

| Rep | 1. Text parsed | 2. Binary flagged | 3. Additional names surfaced & **excluded** | 4. No false "only" claim | 5. Export next step |
|-----|---|---|---|---|---|
| rep1 | `COMPLETE` (3/3) | `FLAGGED` | **`SURFACED_COUNTED`** — 2 binary routines **folded into the Component Manifest per-type subtotal ("Stored Procedures = 3") and the Extraction Metrics table** | `NO_FALSE_CLAIM` | `RECOMMENDED` |
| rep2 | `COMPLETE` (3/3) | `FLAGGED` | **`SURFACED_COUNTED`** — "5 objects" in the manifest; 2 binary routines as Extraction Metrics rows (`unknown`) | `NO_FALSE_CLAIM` | `RECOMMENDED` |
| rep3 | `COMPLETE` (3/3) | `FLAGGED` | `SURFACED_EXCLUDED` — 2 binary routines "deliberately excluded" from the Component Manifest count AND the Extraction Metrics table | `NO_FALSE_CLAIM` | `RECOMMENDED` |

## Aggregate

- **Binary always flagged:** 6/6 `FLAGGED`.
- **Headline failure — silent-zero (`BARE_ZERO` on `binonly1`):** **0/6.** Does not reproduce.
- **Headline failure — false source-of-record (`FALSE_ONLY_CLAIM` on `mixed1`):** **0/6.** Does not reproduce.
- **Names always surfaced:** 6/6.
- **Planner-contract exclusion (names kept OUT of Extraction Metrics / Component Manifest rows):** **only 2/6 `SURFACED_EXCLUDED`; 4/6 `SURFACED_COUNTED`** — a majority of competent agents write the binary name-only routines as rows in the Extraction Metrics table (and some in `metrics.tsv` / `GLOBAL_STATE`) with `Unknown` metrics. That is the exact input the downstream `sproc-migration-plan` planner sizes and sequences from (`sproc-migration-plan/SKILL.md:326–327`, `:184–192`) — bodiless `Unknown` rows corrupt the sizing contract.

## RED-gate decision (per `rep-prompt-template.md` §2c / the r4 CIR fix)

The gate's literal RED conditions — `SILENT`/`MENTIONED_NOT_FLAGGED` binary handling, `ABSENT` names, `BARE_ZERO` on `binonly1`, `FALSE_ONLY_CLAIM` on `mixed1` — are **not met**: on the two failures the spec's acceptance criteria (§spec 114–121) target, the baseline is **clean 0/6**. The pre-fix recipe's mandatory `file` step and `grep -a` mention (`SKILL.md:109–110`), applied by a competent agent, already generalize to the ASCII-header synthetic binary. **So the gate fires: STOP AND REPORT — a straight RED→GREEN proof of the two headline failures is not available on this fixture, and Edit 3's verdict-prohibitions address a failure mode that does not reproduce here.**

**However, the reps surface a *different*, real, majority failure the gate's re-scope clause covers ("...or must be re-scoped to whatever gap the reps actually show"):** 4/6 agents violate the planner-contract exclusion — the exact failure **Edit 2 (row-level exclusion)** targets, and the property CIR rounds 1–2 hardened. This gap is genuinely load-bearing (it corrupts the planner's sizing) and DOES have a RED baseline (4/6 fail). The fix is therefore **not unnecessary — it must be re-scoped** around Edit 2.

**Controller action:** stop and surface to the user (SDD "plan premise no longer holds" + user's stop-after-each-task mode). Decision deferred to the user — see the ledger and the session summary.
