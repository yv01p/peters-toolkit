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
| 1. Both files exist, report has pointers and no `$ ` lines, all headings present | PASS — `DBONLY1-SPROC-XRAY.md` 48,214 bytes, `DBONLY1-SPROC-XRAY-PROOFS.md` 64,059 bytes, both under `reports/`; 23 pointer lines; 0 lines starting `$ `; all three required headings present (Coverage Declaration, Extraction Metrics, CRUD Matrix & Trigger Cascade Map) |
| 2. Proof heading count matches pointer ranges | PASS — 76 proof headings; pointer ranges cover 1..76 with no gap |
| 3. Split command ran as written, exit 0; re-verify ran | PASS (O9) — split calls: 2. Call 1 matched SKILL.md except `; echo "exit=$?"` appended and the two checks after it in the same call. After call 1, the coordinator rewrote `cmd-N` mentions in part prose to `Proof K` and ran assembly and the split again. Both calls: 76 blocks, 23 pointers, exit 0. Re-verify ran (79 commands reproduced). Delivered skill text kept `$(0)`. Passes under Peter's O9 standard |
| 4. Every context ≤ 400K tokens, no compaction | PASS — coordinator `07a435ad…` turns=49 peak=150,869 drops=0; worker `agent-a13adc9a…` turns=17 peak=128,494 drops=0; worker `agent-a1da75e4…` turns=17 peak=124,165 drops=0 |

Session ID: `07a435ad-c12a-46ba-b1ee-c6a88e298e14`. Duration 12 min 25 s
(`2026-09-28T02:32:25.869Z` – `2026-09-28T02:44:51.016Z`). `total_cost_usd` $6.595395 (a
list-price estimate; the run bills to Peter's Max subscription, not pay-per-token).

### Run 1 (before the $(N) fix)

Session `8bff4bd9-771f-468e-a515-64853cd351aa`, 14 min 30 s, $7.03. Criteria 1, 2 and 4 passed
(47 pointer lines, 77 proofs, peaks 155,370 / 125,441 / 135,425, 0 drops). The skill text this
run received had `$0` replaced by the argument (`buf = ./dbonly1 "\n"`, `first = ./dbonly1`, `if
(./dbonly1 ~ /^#+ /)`); the coordinator repaired those tokens by hand before running the
command, and said so in its final message. That finding led to the `$(N)` fix. The coordinator
also edited the report by hand after the split (one `sed -i` on a LOC phrase).
