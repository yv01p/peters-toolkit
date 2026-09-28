# #10 proof companion file — results

Proof blocks — each command with its raw output — move out of the report into a companion
file, `{SYSTEM}-SPROC-XRAY-PROOFS.md`, beside it. The report keeps one pointer line per run of
them. #10 is for the human reader: the planner's peak does not follow report size (T6, below),
so the move trims what a person scrolls past, not what the planner reads.

## Planner probe (T6)

| Run | Report | Planner peak | Duration | Routines covered |
|---|---|---|---|---|
| T4 (T2's report, from #8) | 366 KB | 255,029 | 16 min | 50/50 |
| T6a | 908 KB | 263,568 | 16 min | 64/64 (28 wave-assigned + 36 deferred) |
| T6b | 534 KB | 257,159 | 15 min | 64/64 (29 + 35) |

The planner greps the heading list, reads sections by offset, and pulls table rows with awk. In
T6a, 10 of its 12 reads on the report returned proof-block lines (31 distinct blocks), so T6b is
the direct measure of the planner on a report without proofs. Sessions
`d9f017df-79fa-41c4-84d9-dd209f12626a` (T6a), `5d0cb40e-dd57-4b32-9736-4ef1507c41a3` (T6b).

## Split on the #8 GREEN reports

| Report | Before | After | Proofs file | Blocks moved | Pointer lines |
|---|---|---|---|---|---|
| T2 | 366 KB | 116 KB | 258 KB | 80 | 29 |
| T3 | 908 KB | 543 KB | 389 KB | 216 | 169 |
| T5 | 109 KB | 53 KB | 61 KB | 68 | 35 |

In all three, the proof blocks in the proofs file are byte-identical to the originals (`cmp`),
no report line starts `$ `, and all three required headings are present. T3's split report
differs from T6b only by the 169 pointer lines and 28 whitespace-only lines.

## GREEN: T5

Run command (`claude-opus-5-5`, plugin-3400 fixture, launched by Peter):

```bash
#!/usr/bin/env bash
# #10 GREEN: T5 on the proof-split skill (LIMIT=3400 copy), claude-opus-5-5
cd /tmp/sproc-green10/t5 && uuidgen > session-id && CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS=0 \
claude -p "/peters-toolkit:sproc-xray ./dbonly1" --model claude-opus-5-5 --plugin-dir /tmp/sproc-green10/plugin-3400 \
  --session-id "$(cat session-id)" --autocompact 1000000 \
  --permission-mode dontAsk --allowedTools "Agent,Skill,Bash,Read,Write,Edit,Glob,Grep,TodoWrite" \
  --output-format json > run.json 2> run.err
```

| Criterion | Result |
|---|---|
| 1. Both files exist, report has pointers and no `$ ` lines, all headings present | PASS — `DBONLY1-SPROC-XRAY.md` 51,589 bytes, `DBONLY1-SPROC-XRAY-PROOFS.md` 63,252 bytes, both under `reports/`; 47 pointer lines; 0 lines starting `$ `; all three required headings present (Coverage Declaration, Extraction Metrics, CRUD Matrix & Trigger Cascade Map) |
| 2. Proof heading count matches pointer ranges | PASS — 77 proof headings; pointer ranges cover 1..77 with no gap |
| 3. Split command ran as written, exit 0; re-verify ran | PASS (O9) — split ran once (`toolu_01MVzYZj8NkoZChVpKDuaKp9`), `is_error=false`, exit 0, printed `77 proof blocks moved, 47 pointer lines`; re-verify ran once. The plan's normalization check found no match: the coordinator's Bash call set `W=/tmp/tmp.FN1jcZWFx9` unquoted on the call's first line, which dropped the `W="<WORK>"; ` prefix from the `D=` line, and it appended `; echo "exit=$?"` after the awk command. The awk program itself (lines 2–18) is byte-identical to SKILL.md. Peter accepted the result as passing (O9) |
| 4. Every context ≤ 400K tokens, no compaction | PASS — coordinator `8bff4bd9…` turns=49 peak=155,370 drops=0; worker `agent-a1a8cf34…` turns=14 peak=125,441 drops=0; worker `agent-a41ad87f…` turns=15 peak=135,425 drops=0 |

Session ID: `8bff4bd9-771f-468e-a515-64853cd351aa`. Duration 14 min 30 s
(`2026-09-28T01:18:28.598Z` – `2026-09-28T01:32:58.324Z`). `total_cost_usd` $7.0343892 (a
list-price estimate; the run bills to Peter's Max subscription, not pay-per-token).
