# GREEN evidence — post-fix `sproc-xray` on binary DB files (finding A)

**Arm:** GREEN (post-fix). `{SKILL_PATH}` = `skills/sproc-xray/SKILL.md` amended with the four binary-DB-file edits, committed `e5cb3b6` ("fix(sproc-xray): keep binary DB routine names out of parsed-inventory rows/counts; flag binary sources").
**Reps:** 3 per corpus (6 total), fresh-context agents on the same capable model as the RED arm (sonnet), each isolated to its own rep-facing fixture copy (`prepare-binary-fixture.sh`, README excluded).
**Scored against:** `rep-prompt-template.md` Part 2 (§2a `binonly1`, §2b `mixed1`).

**Cadence deviation (documented — CIR round 6 §3.1 → option b).** GREEN deliberately runs **3 reps/corpus**, matching the RED baseline (`baseline-results.md:4`) for N-for-N comparability of the transition, rather than the rep-prompt rubric's nominal "5+ per corpus" (`rep-prompt-template.md:198`). This is the same SDD-ledger cadence ruling that governed RED. The transition is decisive at N=6: a 6/6 all-`SURFACED_EXCLUDED` GREEN against the baseline's ≈2/6 (0.33) exclusion rate is ≈0.33⁶ ≈ 0.0014 under a no-effect null.

## Per-rep scoring

### `binonly1` (routines only in the binary; the silent-zero / planner-leak corpus)

| Rep | 1. Binary flagged | 2. Names surfaced & **excluded from counts/Extraction Metrics** | 3. No bare zero | 4. Export next step |
|-----|---|---|---|---|
| rep1 | `FLAGGED` | `SURFACED_EXCLUDED` — 3 names (sp_calculate_driver_payout, fn_apply_late_fee, trg_audit_vehicle_status), "names only, bodies unrecovered"; Component Manifest + Extraction Metrics **empty**; `metrics.tsv` 0 rows; names only in intake row + Coverage Declaration | `CAVEATED` ("must not be read as 'no DB logic exists' … logic likely resides in an unparsed binary") | `RECOMMENDED` |
| rep2 | `FLAGGED` | `SURFACED_EXCLUDED` — 3 names, excluded from Component Manifest / Extraction Metrics / `metrics.tsv` (0 rows) | `CAVEATED` ("Do not read '0 objects' as 'no DB logic exists'") | `RECOMMENDED` |
| rep3 | `FLAGGED` | `SURFACED_EXCLUDED` — 3 names, excluded from Component Manifest / Extraction Metrics / `metrics.tsv` (0 rows) | `CAVEATED` ("Logic likely resides in an unparsed binary — DDL export required") | `RECOMMENDED` |

### `mixed1` (3 `.sql` routines + 2 additional in the binary; the false-source-of-record / planner-leak corpus)

| Rep | 1. Text parsed | 2. Binary flagged | 3. Additional names surfaced & **excluded** | 4. No false "only" claim | 5. Export next step |
|-----|---|---|---|---|---|
| rep1 | `COMPLETE` (3/3) | `FLAGGED` | `SURFACED_EXCLUDED` — 2 binary names (sp_apply_damage_charge, trg_sync_fleet_inventory) excluded; Extraction Metrics table = **exactly** the 3 `.sql` routines; binary names absent | `NO_FALSE_CLAIM` ("does not assert that DB logic 'lives only in' … the .sql files") | `RECOMMENDED` |
| rep2 | `COMPLETE` (3/3) | `FLAGGED` | `SURFACED_EXCLUDED` — 2 binary names "not rendered as rows in the Component Manifest, the Extraction Metrics table, or `metrics.tsv`"; Extraction Metrics = the 3 `.sql` routines only | `NO_FALSE_CLAIM` ("does not and cannot assert that the two .sql files are the complete set") | `RECOMMENDED` |
| rep3 | `COMPLETE` (3/3) | `FLAGGED` | `SURFACED_EXCLUDED` — 2 binary names "excluded from every count in this report"; Extraction Metrics = the 3 `.sql` routines only | `NO_FALSE_CLAIM` ("Do not treat '3 routines found in .sql files' as the inventory") | `RECOMMENDED` |

## Aggregate

- **Binary always flagged:** 6/6 `FLAGGED`.
- **Planner-contract exclusion (PRIMARY GREEN criterion — the behavior with a genuine RED baseline):** **6/6 `SURFACED_EXCLUDED`; 0/6 `SURFACED_COUNTED`.** No binary name-only routine appears as a row in the Extraction Metrics table, the Component Manifest, `metrics.tsv`, or a per-type subtotal in any rep. For `mixed1`, all 3 reps' Extraction Metrics rows equal exactly the 3 `.sql` text routines; the 2 binary-only names are absent.
- **Names always surfaced:** 6/6 (in the intake row + Coverage Declaration only).
- **Export next step:** 6/6 `RECOMMENDED`.
- **Secondary confirmations (no-regression, not RED→GREEN — these failures were already clean 0/6 at baseline, see `baseline-results.md:28–30`):** `binonly1` `BARE_ZERO` 0/3 (`CAVEATED` 3/3); `mixed1` `FALSE_ONLY_CLAIM` 0/3 (`NO_FALSE_CLAIM` 3/3). Stated plainly: (c)/(d) confirm the Edit-3 insurance behaviors did not regress; they are **not** proof of a fixed failure, because the failure did not reproduce pre-fix.

## GREEN-gate decision (per `rep-prompt-template.md` §2c and the re-scoped Task 3, CIR r6 §3.1 → b)

**The primary GREEN gate is MET: the `SURFACED_COUNTED → SURFACED_EXCLUDED` transition is proven — 4/6 fail (RED, `baseline-results.md:31`) → 0/6 fail (GREEN).** The fix (Edit 2 row-level exclusion + Edit 1/Edit 4 surfacing destinations) keeps binary routine names out of the exact planner-sizing input `sproc-migration-plan` consumes (`sproc-migration-plan/SKILL.md:326–327`, `:184–192`), while still surfacing them for the human. Every rep also satisfies the rubric's §2c GREEN pass-set (`FLAGGED` / `SURFACED_EXCLUDED` / `CAVEATED` / `NO_FALSE_CLAIM`). The re-scoped fix is proven on the failure that had a genuine RED baseline.
