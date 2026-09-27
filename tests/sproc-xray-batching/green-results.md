# GREEN-arm results — sproc-xray 0.7.0, batched runs (coordinator + Batch Workers)

**Arm:** GREEN for #8. `skills/sproc-xray/SKILL.md` 0.7.0 at commit `b90ced3`: the Task 3 commit `975bcd7` plus the batch limit `LIMIT=128000`.
**Model:** `claude-opus-5-5` for every session, coordinator and workers (the workers inherit it; the coordinator's `Agent` calls set no model). The plan's commands say `--model sonnet`; four Sonnet 5 runs of T2 are recorded under **Model and batch-size runs** and explain the change.
**Corpora:** ADempiere at commit `59557cc2ee85ac938cd4f31a246d891bc2b15b8f`. T2: `db/ddlutils/oracle/functions`, 50 files, 122,831 bytes. T3: functions + procedures + views, 250 files, 579,953 bytes. T5: a copy of `tests/sproc-planning-dbonly/dbonly1/sql` with `EXECUTE IMMEDIATE 'BEGIN prc_reset_batch_totals; END;'` added to `prc_finalize_order.sql`, 12 files, 5,677 bytes. Fixtures from `prepare-fixture.sh`.
**Runs:** 2026-09-27, Claude Code 2.1.283, headless, launched by the user.

```bash
# T2 (T3: ./o3-corpus in /tmp/sproc-green/t3)
cd /tmp/sproc-green/t2 && uuidgen > session-id && CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS=0 \
claude -p "/peters-toolkit:sproc-xray ./o1-corpus" --model claude-opus-5-5 --plugin-dir /home/peter/peters-toolkit \
  --session-id "$(cat session-id)" --autocompact 1000000 \
  --permission-mode dontAsk --allowedTools "Agent,Skill,Bash,Read,Write,Edit,Glob,Grep,TodoWrite" \
  --output-format json > run.json 2> run.err

# T5: same, in /tmp/sproc-green/t5, with "./dbonly1" and --plugin-dir /tmp/sproc-green/plugin-3400 (LIMIT=3400)

# T4: planner on T2's report
mkdir -p /tmp/sproc-green/t4 && cp /tmp/sproc-green/t2/reports/O1-CORPUS-SPROC-XRAY.md /tmp/sproc-green/t4/ && cd /tmp/sproc-green/t4 && \
claude -p "/peters-toolkit:sproc-migration-plan ./O1-CORPUS-SPROC-XRAY.md — the application codebase is this directory (it holds no application code)" \
  --model claude-opus-5-5 --plugin-dir /home/peter/peters-toolkit \
  --permission-mode dontAsk --allowedTools "Agent,Skill,Bash,Read,Write,Edit,Glob,Grep,TodoWrite" \
  --output-format json > run.json 2> run.err
```

**Outcome: every session of T2, T3, T4 and T5 stayed at or below 400K tokens with no compaction.** The largest was the T2 worker at 356,088.

## Changes from the plan

- **Model.** `claude-opus-5-5` instead of `sonnet`, decided after the Sonnet runs below: Sonnet 5 failed at least one check in 3 of 4 runs, and the 45,000 run passed all of them. One run per size cannot separate model from batch size; the user chose Opus.
- **Batch limit.** 128,000 bytes. The plan's 15,000 was set against the earlier 160K-per-context target; the target is now 400K (40% of a 1M window).
- **T3 batch count.** 5 at 128,000, derived with Step 4.2's command (the plan's 43 was at 15,000). The run's `Agent` briefs list 37 / 43 / 80 / 64 / 26 files, the same as the command. No file exceeds 128,000 bytes, so the oversize-batch exception does not apply.
- **T2 `UDT Usage`, 3 rows.** SKILL.md says `UDT Usage` lists the signature's type constructs "copied verbatim". Every GREEN run, on both models, wrote the anchor verbatim (`C_BPartner.C_BPartner_ID%TYPE`); the baseline wrote a bare `` `%TYPE` ``. Ruled a baseline error.
- **Wall-clock time** comes from the first and last transcript timestamps. `duration_ms` in `run.json` counts only the coordinator's last turn when its workers run in the background (T2: 7m08s reported, 33m43s actual).

## Measurement method

Step 2's command: per transcript, one context value per unique assistant message id (first occurrence), context = `input_tokens + cache_read_input_tokens + cache_creation_input_tokens`. A transcript passes when its peak is ≤ 400,000 and the value never drops between consecutive turns (a drop can only be a compaction). On the baseline transcript it gives 346,584 (102 turns, 0 drops).

## T2 — 50 functions, 1 batch

| Transcript | Turns | Peak | Drops | Result |
|---|---|---|---|---|
| coordinator `0475b8a8…` | 62 | 149,780 | 0 | PASS |
| worker batch 01 `agent-ac888f75…` | 50 | 356,088 | 0 | PASS |

Batch count 1. `total_cost_usd` $10.50. Wall clock 33m43s. Report 366,303 bytes.

| Criterion | Outcome | Evidence |
|---|---|---|
| Measurement rule, every transcript | PASS | table above; base directory `/home/peter/peters-toolkit/skills/sproc-xray` |
| Required headings | PASS | 3 of 3 |
| Extraction Metrics identical to baseline | PASS (47 of 50 rows identical; 3 `UDT Usage` cells are the baseline error above) | every Params, Cursor Loops, Branches, File and LOC cell matches |
| `calls.tsv` 28 vs 29 | explained | the baseline records the call at `C_Currency_Base.sql:29` twice, once per `currencyBase` definition; the call passes 6 arguments and matches only the 6-parameter definition |
| `crud.tsv` 133 vs 133 | same | |
| `findings.tsv` 114 vs 24 | explained | one row per hit site: HARDCODED_VALUE 30, NULL_SEMANTICS 27, OTHER 56, GLOBAL_STATE 1. Includes the `99999` sentinel and `±0.00999` tolerance rows the baseline did not record; the baseline's hazards are present (ROWNUM before ORDER BY, BOM recursion without a depth guard, `ProductAttribute.sql:56`) |
| Re-verify differing commands | 0 | "commands: 82, differing: 0" |
| `ext.tsv` lists `Nextid` and `getdate` | PASS | 12 rows; targets `DBMS_OUTPUT.PUT_LINE`, `Nextid`, `getdate` |
| No `ext.tsv` target matches a manifest name | PASS | none of the 3 targets is a manifest object |
| Dimension 5, one line per production findings row | PASS | 114 lines, 114 rows |
| Executive Summary error-swallowing flag | PASS | 2 matches |
| Extraction Sequencing places all 49 names | PASS | |
| Worker writes stay in the batch dir | PASS | only `/dev/stderr` redirects outside `batch-01/` |

Cost: $10.50 against the single-context baseline's $6.59 (Sonnet 5).

## T5 — dbonly1 at a 3,400-byte limit, 2 batches

| Transcript | Turns | Peak | Drops | Result |
|---|---|---|---|---|
| coordinator `550cfe08…` | 51 | 146,194 | 0 | PASS |
| worker batch 01 `agent-a4023158…` | 13 | 125,902 | 0 | PASS |
| worker batch 02 `agent-ae1c7541…` | 11 | 111,602 | 0 | PASS |

Batch count 2 (01: the eight `fn_*` files, three of them `-Test.sql`, plus `pkg_order_state.sql`, 3,397 bytes; 02: `prc_finalize_order`, `prc_reset_batch_totals`, `trg_order_status_audit`, 2,280 bytes). `total_cost_usd` $5.94. Wall clock 11m40s. Base directory `/tmp/sproc-green/plugin-3400/skills/sproc-xray`.

| Criterion | Outcome | Evidence |
|---|---|---|
| `pkg_order_state.sql` in a different batch from both touchers | PASS | `Agent` briefs: batch 01 vs batch 02 |
| Both touchers have GLOBAL_STATE rows for `g_current_batch_id` / `g_batch_total` | PASS | 6 rows: `prc_finalize_order.sql:18` (read, write), `prc_reset_batch_totals.sql:8, :14, :15` (read, write); names from `state.tsv`, declarations outside batch 02 |
| `-Test.sql` files: only `Scope=test` findings, no metrics, calls or crud rows | PASS | 0 `-Test.sql` lines in Extraction Metrics, CRUD matrix, graph; batch 01 wrote 3 findings rows, all `test` (`DBMS_OUTPUT.PUT_LINE`) |
| Dynamic call is a `MEDIUM`/`LOW` edge, graph label tagged | PASS | `prc_finalize_order.sql:21 [MEDIUM-CONF]` → `prc_reset_batch_totals` |

## T3 — 250 objects, 5 batches

| Transcript | Batch bytes | Turns | Peak | Drops | Result |
|---|---|---|---|---|---|
| coordinator `f4c5812a…` | | 94 | 213,622 | 0 | PASS |
| worker batch 01 `agent-a4e914a1…` | 127,030 | 48 | 304,831 | 0 | PASS |
| worker batch 02 `agent-a2d4b39f…` | 126,633 | 62 | 343,216 | 0 | PASS |
| worker batch 03 `agent-a4662bc9…` | 127,322 | 52 | 336,728 | 0 | PASS |
| worker batch 04 `agent-a6df23bb…` | 126,721 | 40 | 312,747 | 0 | PASS |
| worker batch 05 `agent-a5d41759…` | 72,247 | 52 | 282,324 | 0 | PASS |

`total_cost_usd` $34.32. Wall clock 31m43s. Report 907,590 bytes; required headings 3 of 3; Extraction Metrics 64 rows = 50 functions + 14 procedures (the 186 views are not routines), 0 blank cells. Re-verify: "commands re-run: 218, differing: 1"; the coordinator repaired the differing command and it reproduced.

## T4 — sproc-migration-plan on T2's report

| Transcript | Turns | Peak | Drops | Result |
|---|---|---|---|---|
| planner `6fd87922…` | 16 | 255,029 | 0 | PASS |

Input: the T2 report above (366,303 bytes). `total_cost_usd` $4.61. Wall clock 16m08s. Output `plans/O1-CORPUS-MIGRATION-PLAN.md`, 61,728 bytes: 44 functions in waves W0–W7, 6 deferred for investigation.

| Criterion | Outcome | Evidence |
|---|---|---|
| Intake accepts the report | PASS | a plan, not a rejection |
| "Tables accessed" scored for every routine | PASS for the 44 wave units | each unit's evidence cites the CRUD matrix (`GETUUID`: DUAL excluded, scored 1). The 6 deferred routines carry no complexity score at all, which is planner behavior independent of batching |
| Extraction Sequencing used for Wave 0 | PASS | 9 units, all in the report's Layer 1, then filtered to no finding above MEDIUM and not recursive |

## Model and batch-size runs (T2, Sonnet 5)

Before the Opus runs, T2 ran four times on `claude-sonnet-5` at different batch limits (the first at the plan's `--autocompact 200000`, the rest at `1000000`):

| Limit | Workers (peak) | Coordinator | Wall clock | Cost | F6 | F7 | F8 | F12 | F13 | F15 |
|---|---|---|---|---|---|---|---|---|---|---|
| 15,000 | 9 (145–163K) | 166K, 2 forced compactions | 37m45s | $20.42 | ✗ | ✗ | ✗ | ✓ | ✓ | ✓ |
| 128,000 | 1 (344K) | 231K | 131m45s | $10.36 | ✗ | ✓ | ✓ | ✗ | ✗ | ✗ |
| 45,000 | 3 (223–245K) | 288K | 30m19s | $14.72 | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 86,000 | 2 (207K, 284K) | 313K | 31m20s | $12.35 | ✗ | ✗ | ✗ | ✗ | ✓ | ✓ |

- F6 `UDT Usage` differs from baseline (the baseline error above; not a run failure).
- F7 Extraction Sequencing not in the `- Layer N: a, b` form, so the check places 0 names.
- F8 a worker wrote files outside its batch dir (`/tmp/manifest_names.txt` and similar).
- F12 LOC from whole-file `wc -l` instead of the `CREATE` → `/` span (off by one without a trailing newline; `get_Sysconfig` 45 instead of 25).
- F13 findings missed: 6 CRITICAL ROWNUM-before-ORDER-BY rows and the BOM recursion rows.
- F15 the coordinator skipped the proof re-verify.

The failures move between runs and are not explained by batch size (F12 hit the 207K worker at 86,000). The 128,000 run's 61-minute single reply (10,037 output tokens, no API error logged) made it the slowest. On Opus at 128,000 every check passed.

## Known issues carried forward

- **Report size** (#10): batched reports are 4–5× the single-context size (T2 366,303 vs 78,581 bytes; T5 108,794 vs the golden 26,578), mostly proof blocks pasted inline. T3's 907,590-byte report has not been run through the planner.
- **Worker headroom:** the T2 worker used 356,088 tokens on 122,831 bytes, about 44K under the limit; the largest T3 worker used 343,216 on 126,633 bytes.
- **Proof commands that depend on shell variables:** re-verify catches and repairs them (T3: 1 of 218).

## Evidence location

Session scratch, not committed. Transcripts under `~/.claude/projects/-tmp-sproc-green-tN/`, run dirs under `/tmp/sproc-green/tN/`:

```
T2 (Opus)  0475b8a8-ad87-463d-b1fc-f6367fd52467
T5         550cfe08-aba1-4ae2-8081-ebca0024328b
T3         f4c5812a-f6fe-4980-9abe-117b6aa1956c
T4         6fd87922-084c-4e18-b958-c6c45cc319c7
T2 Sonnet  121f3155-4a4b-44f2-97dd-2c21816d9ed6 (15,000), 835d8ecb-0fe8-4b1e-b49b-9ff330bad727 (128,000),
           94e3ed9d-2e81-4bea-87ad-93db06f7d4dd (45,000), 54a2f064-ace8-4967-b66d-2231580a82f5 (86,000)
```
