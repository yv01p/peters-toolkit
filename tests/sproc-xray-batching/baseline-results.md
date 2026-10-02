# Baseline-arm results — sproc-xray v0.6.0, single context, ADempiere 50-function corpus

**Arm:** baseline (RED for #8). `skills/sproc-xray/SKILL.md` at v0.6.0 (installed plugin 2.5.1, commit `98de507`), unmodified.
**Corpus:** ADempiere `db/ddlutils/oracle/functions` at commit `59557cc2ee85ac938cd4f31a246d891bc2b15b8f` — 50 files, 122,831 bytes, Oracle PL/SQL.
**Run:** 2026-09-26, Claude Code 2.1.283, headless, top-level session (not a subagent), model `claude-sonnet-5`, one run:

```bash
claude -p "/peters-toolkit:sproc-xray ./o1-corpus" --model sonnet \
  --session-id <uuid> --autocompact 1000000 \
  --permission-mode dontAsk --allowedTools "Agent,Skill,Bash,Read,Write,Edit,Glob,Grep,TodoWrite" \
  --output-format json
```

**Outcome: one context carried the whole run and peaked at 347,128 tokens.** That is 174% of a 200K window. No subagents were started (`subagent_stats.spawned = 0`), although Step 4 suggests them for Dimensions 3–5.

## Measurement method

Context size per API turn = `input_tokens + cache_read_input_tokens + cache_creation_input_tokens` from the transcript's `usage` fields, one value per unique assistant message id. Totals for output and thinking come from the run's `--output-format json` result. Bytes on disk are not a proxy for context: they miss thinking and command output.

## Results

| Measure | Value |
|---|---|
| Peak context | 347,128 tokens (102 API turns) |
| First-turn context | 62,360 (harness ~38K + injected skill 63,231 chars ≈ 24K) |
| `oracle.md` read | +19,184 |
| Output tokens | 145,773, of which thinking 58,379 |
| Subagents | 0 |
| Cost | $6.59 |
| Report | 78,581 bytes, all required headings present |

Context growth by phase (from the per-turn series, phases by tool-call descriptions):

| Phase | Turns | Context at end | Growth |
|---|---|---|---|
| Start | 1 | 62,360 | — |
| Dimension 1 (intake, manifest, metrics) | 1–57 | ~199K | +137K |
| Dimensions 2–3 (calls, CRUD) | 58–81 | ~259K | +60K |
| Dimensions 4–5 | 82–97 | ~295K | +36K |
| Report write, re-verify, cleanup | 98–102 | 347K | +52K |

Notes:
- Dimension 1's growth splits roughly into thirds: the model writing and debugging its own metrics parser (~57K chars), reading `oracle.md` and source (~72K chars), and other commands (~64K chars).
- The model rendered the CRUD table by command, printed it, then retyped it into the report Write (+40K in that turn), so the table passed through context twice.
- The final re-verify pass cost under 2K tokens.

## Report facts (for the GREEN comparison)

| Fact | Baseline value |
|---|---|
| Objects / LOC | 50 objects, 3,221 LOC |
| `metrics.tsv` rows | 50 |
| `calls.tsv` edges | 29 |
| `crud.tsv` rows | 133 |
| `findings.tsv` rows | 24 |

Extraction Metrics table, verbatim from the baseline report. The GREEN run's table must match it row for row, since every cell is computed by command:

Exception: the three `%TYPE` cells (`bpartnerRemitLocation`, `documentNo`, `get_Sysconfig`) are a baseline error. SKILL.md says `UDT Usage` copies the signature's type construct verbatim (e.g. `C_BPartner.C_BPartner_ID%TYPE`); see `green-results.md`, "Changes from the plan".

| Object | Params | Cursor Loops | Branches | UDT Usage | File | LOC |
|--------|--------|--------------|----------|-----------|------|-----|
| acctBalance | 3 | 0 | 4 | none | Acct_Balance.sql | 64 |
| ADDWEEKS | 2 | 0 | 0 | none | addweeks_oracle.sql | 34 |
| ADDYEARS | 2 | 0 | 0 | none | addyears_oracle.sql | 34 |
| Bompricelimit | 2 | 1 | 2 | none | BOM_PriceLimit.sql | 53 |
| Bompricelist | 2 | 1 | 2 | none | BOM_PriceList.sql | 54 |
| Bompricestd | 2 | 1 | 2 | none | BOM_PriceStd.sql | 54 |
| bomQtyAvailable | 3 | 0 | 0 | none | BOM_Qty_Available.sql | 21 |
| BomqtyavailableASI | 4 | 0 | 0 | none | BOM_Qty_AvailableASI.sql | 22 |
| Bomqtyonhand | 3 | 1 | 11 | none | BOM_Qty_OnHand.sql | 125 |
| BomqtyonhandASI | 4 | 1 | 11 | none | BOM_Qty_OnHandASI.sql | 128 |
| Bomqtyordered | 3 | 1 | 12 | none | BOM_Qty_Ordered.sql | 131 |
| BomqtyorderedASI | 4 | 1 | 12 | none | BOM_Qty_OrderedASI.sql | 134 |
| Bomqtyreserved | 3 | 1 | 12 | none | BOM_Qty_Reserved.sql | 130 |
| BomqtyreservedASI | 4 | 1 | 12 | none | BOM_Qty_ReservedASI.sql | 133 |
| bpartnerRemitLocation | 1 | 1 | 1 | `%TYPE` | C_BPartner_RemitLocation.SQL | 34 |
| currencyBase | 5 | 0 | 0 | none | C_Currency_Base.sql | 31 |
| currencyBase | 6 | 0 | 2 | none | C_Currency_Base_Type.sql | 48 |
| currencyConvert | 7 | 0 | 3 | none | C_Currency_Convert.sql | 51 |
| currencyRate | 6 | 1 | 14 | none | C_Currency_Rate.sql | 174 |
| currencyRound | 3 | 0 | 3 | none | C_Currency_Round.SQL | 49 |
| invoiceDiscount | 3 | 0 | 4 | none | C_Invoice_Discount.sql | 74 |
| invoiceOpen | 2 | 2 | 5 | none | C_Invoice_Open.sql | 115 |
| InvoiceopenToDate | 3 | 2 | 5 | none | C_Invoice_OpenToDate.sql | 118 |
| invoicePaid | 3 | 1 | 1 | none | C_Invoice_Paid.sql | 60 |
| InvoicepaidToDate | 4 | 1 | 1 | none | C_Invoice_PaidToDate.sql | 62 |
| paymentTermDiscount | 5 | 1 | 4 | none | C_PaymentTerm_Discount.sql | 66 |
| paymentTermDueDate | 2 | 1 | 2 | none | C_PaymentTerm_DueDate.sql | 52 |
| paymentTermDueDays | 3 | 1 | 8 | none | C_PaymentTerm_DueDays.sql | 110 |
| paymentAllocated | 2 | 1 | 1 | none | C_Payment_Allocated.sql | 57 |
| paymentAvailable | 1 | 1 | 2 | none | C_Payment_Available.sql | 62 |
| DBA_ConstraintCmd | 1 | 0 | 2 | none | DBA_ConstraintCmd.sql | 58 |
| DBA_DisplayType | 1 | 0 | 24 | none | DBA_DisplayType.sql | 46 |
| dailySalaryToDateByHRProcess | 3 | 0 | 0 | none | DailySalaryToDateByHrProcess.sql | 53 |
| ProcessReportSource | 5 | 1 | 4 | none | ProcessReportSource_Oracle.sql | 69 |
| productAttribute | 1 | 1 | 5 | none | ProductAttribute.sql | 84 |
| PRODQTYRESERVED | 3 | 0 | 6 | none | Product_Qty_Reserved.sql | 85 |
| dailySalary | 1 | 0 | 0 | none | dailySalary.sql | 35 |
| dailySalaryToDate | 2 | 0 | 1 | none | dailySalaryToDate.sql | 64 |
| documentNo | 1 | 1 | 7 | `%TYPE` | documentNo.sql | 45 |
| financialRateToDate | 2 | 0 | 0 | none | financialRateToDate.sql | 41 |
| GETUUID | 0 | 0 | 0 | none | getUUID.sql | 37 |
| get_Sysconfig | 4 | 0 | 0 | `%TYPE` | get_Sysconfig.sql | 25 |
| linenetamtrealinvoiceline | 1 | 0 | 1 | none | linenetamtrealinvoiceline.sql | 15 |
| linenetamtrealorderline | 1 | 0 | 1 | none | linenetamtrealorderline.sql | 15 |
| maxpaydate | 1 | 0 | 0 | none | maxpaydate.sql | 17 |
| monthlySalary | 1 | 0 | 0 | none | monthlySalary.sql | 35 |
| monthlySalaryToDate | 2 | 0 | 1 | none | monthlySalaryToDate.sql | 64 |
| nextBusinessDay | 2 | 1 | 3 | none | nextBusinessDay.sql | 55 |
| nextidfunc | 2 | 0 | 0 | none | nextIDFunc.sql | 14 |
| prodqtyordered | 2 | 0 | 4 | none | prodQtyOrdered.sql | 63 |

## Evidence location

The transcript and report are session scratch and are not committed:

```
~/.claude/projects/-tmp-claude-1000--home-peter-peters-toolkit-6378a657-0e49-467e-be0b-b87d38f71626-scratchpad-top-run/dc8c209a-c37c-4d39-b551-4371badfd364.jsonl
/tmp/claude-1000/-home-peter-peters-toolkit/6378a657-0e49-467e-be0b-b87d38f71626/scratchpad/top-run/reports/O1-CORPUS-SPROC-XRAY.md
```
