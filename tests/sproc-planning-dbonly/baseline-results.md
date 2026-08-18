# RED baseline — pre-fix `sproc-migration-plan` collapses on DB-only inputs (finding #7)

**Arm:** RED (pre-fix skill). **Fixture:** `tests/sproc-planning-dbonly/dbonly1` (DB-only x-ray report,
no `app/` tree, no runtime pack). **Reps:** 5, fresh context each, **model pinned: Sonnet**
(the GREEN arm, Task 5, MUST use the same model — else the RED↔GREEN contrast is model-confounded).
**Skill under test:** a staged, neutral copy of the **pre-fix** `skills/sproc-migration-plan/SKILL.md`
(HEAD `62961a6`, before Task 4). **Verdict: RED gate FIRES — 4/5 reps collapse. Finding #7 confirmed;
the fix is justified.**

## Fixture note (why this file supersedes an earlier RED run)

The first RED run (5 reps) was **discarded**: the committed report initially lacked the mandatory
`### Extraction Metrics` section, so the skill's Input Contract rejected it at intake for some reps
(strict) and degraded complexity scoring for others (lenient) — an inconsistent arm that confounds
the collapse signal with a format-rejection signal. The fixture was corrected in
`6cfb3b9` (added the per-routine Extraction Metrics table; report now passes the skill's intake
contract), and this baseline is the **re-run on the corrected fixture** — every rep reaches
wave-assembly, so the collapse (or non-collapse) is the skill's genuine DB-only planning behavior,
not an artifact of report format. (Even on the broken fixture, 4/5 reps had already exhibited the
collapse — the corrected re-run confirms it cleanly.)

## REP-ISOLATION attestation (Ruling 14 + anti-installed-skill)

- **Neutral sandbox:** each rep ran in an opaque `/tmp/tmp.XXXXXXXX/dbonly1` path (no segment naming
  the repo, branch, or skill); fixture built by `prepare-dbonly-fixture.sh` (report only, README
  excluded, no `app/`).
- **Confinement preamble:** every rep received the ENVIRONMENT block scoping it to `{FIXTURE_PATH}`.
- **Staged skill:** `{SKILL_PATH}` pointed at a copy of the pre-fix skill placed **inside** each
  rep's fixture dir (`.../dbonly1/skill-under-test.md`) — never the in-checkout skill path.
- **Anti-installed-skill TASK-CONSTRAINTS block:** every rep prompt forbade invoking the Skill tool's
  `sproc-migration-plan` / `peters-toolkit:*` and pinned the rep to the staged file as sole authority.

**Tell-scan (behavioral):** all 5 plans exhibit the staged skill's methodology fingerprints
(Safe-to-Fail harness, Wave 0, 5-gate progression, 10-dimension complexity matrix, Pattern D,
partition reconciliation) — consistent with having READ the staged `{SKILL_PATH}`. The 4 collapses
are the pre-fix skill's own no-caller→deferred behavior, and every rep's complexity scores cite the
report's `### Extraction Metrics` columns (Params/Branches) — confirming reps planned from the staged
pre-fix skill against the corrected report, not from an installed/fixed version. No plan shows a
divergent (fixed-skill) methodology that would indicate installed-skill contamination.

## Per-rep scoring (8 dimensions; see rep-prompt-template.md Part 2)

| # | Dimension | Rep 1 | Rep 2 | Rep 3 | Rep 4 | Rep 5 |
|---|---|---|---|---|---|---|
| 1 | Executable plan not near-empty | **NEAR_EMPTY** | **NEAR_EMPTY** | **NEAR_EMPTY** | **NEAR_EMPTY** | POPULATED |
| 2 | Wave 0 populated from structural leaves | **EMPTY_OR_MISSING** | **EMPTY_OR_MISSING** | **EMPTY_OR_MISSING** | **EMPTY_OR_MISSING** | POPULATED |
| 3 | Possibly-dead routines wave-assigned | **WRONGLY_DEFERRED** | **WRONGLY_DEFERRED** | **WRONGLY_DEFERRED** | **WRONGLY_DEFERRED** | WRONGLY_DEFERRED (partial: fn_calculate_discount) |
| 4 | Confirmed-dead routine deferred/dropped | DEFERRED | DEFERRED | DEFERRED | DEFERRED | DEFERRED |
| 5 | GLOBAL_STATE cluster kept in one wave | RESPECTED | RESPECTED | **SPLIT** | **SPLIT** | RESPECTED (nominal) |
| 6 | Trigger cascade clustered; trigger live | RESPECTED | RESPECTED | RESPECTED | RESPECTED | RESPECTED |
| 7 | Stated-Unknowns (DB-only + pack gap) | STATED | STATED | STATED | STATED | STATED |
| 8 | Partition reconciliation | base=8 ✓ | base=8 ✓ | base=8 ✓ | base=8 ✓ | base=8 ✓ |

**Collapse (crit 1+2+3):** Rep 1 ✓ · Rep 2 ✓ · Rep 3 ✓ · Rep 4 ✓ · Rep 5 ✗ (reasoned around the rule).

### The collapse (reps 1–4), in the reps' own words

- **Wave 0 empty:** "infrastructure only — no migration units"; "no simple leaf functions available
  for a learning wave (all simple functions are deferred)"; Rep 4: Wave 0 "BLOCKED — cannot proceed."
- **Leaves wrongly deferred:** the 3 test-caller-only leaves (`fn_calculate_discount`,
  `fn_format_order_number`, `fn_validate_postal_code`) routed to "Deferred / needs-investigation" for
  "no production caller found" / "no application code to confirm callers" — exactly the pre-fix skill's
  no-caller→deferred rule firing on a corpus where NO app caller can exist.
- **Near-empty plan:** only the confirmed-live trigger/shared-state cluster (3–4 units) scheduled.
- **Shared-state split (reps 3, 4):** `prc_reset_batch_totals` deferred while `prc_finalize_order`
  migrates — splitting the GLOBAL_STATE cluster (a worse, secondary failure the collapse induces).

### Rep 5 — the honest outlier (no collapse)

Rep 5 overrode the rule with judgment: it placed `fn_format_order_number` and `fn_validate_postal_code`
in Wave 0 as structural leaves and wave-assigned 6 routines, deferring only `fn_calculate_discount`.
This mirrors the sibling `trgplan1` baseline finding that some capable reps reason around a skill's
rule. It does not weaken the result: the RED gate requires the collapse at ≥3/5, and the pre-fix
skill's RULE, when followed (4/5 reps), collapses the plan. The finding-#7 fix removes the collapse
from the SKILL ITSELF, so even rule-following reps will produce populated plans (Task 5 GREEN bar).

### Secondary observations (not finding-#7 signals; GREEN-arm watch items)

- **Dimension 8 (partition base):** all 5 reps reconciled against the **8 routines** in the
  `### Extraction Metrics` table (5 functions + 2 procedures + 1 trigger), consistently treating the
  `pkg_order_state` **package** as a non-routine state resource (retained/dropped), not a partition
  unit. Each rep's own partition sums correctly (no object lost). The answer key
  (`dbonly1/README.md`) counts **9**, including `pkg_order_state` as retained-in-DB. This is a
  consistent definitional difference (routine-count vs. object-count), not a lost-object under-count
  — noted so the GREEN arm can be scored on the same basis.
- Reps 3 & 4 split the GLOBAL_STATE cluster (deferring `prc_reset_batch_totals`); reps 1, 2, 5 kept
  the pair together. The fix should also stabilize this by classifying the no-caller shared-state
  member as presumptive-live (wave-assigned) rather than deferred.

## RED-gate verdict

Per rep-prompt-template.md §2c, the RED arm fires when, across ≥3/5 reps, the plans exhibit
`NEAR_EMPTY` (crit 1) and/or `EMPTY_OR_MISSING` Wave 0 (crit 2) and/or `WRONGLY_DEFERRED`
possibly-dead routines (crit 3). Observed: **4/5 on all three** criteria. **RED gate FIRES.**
Finding #7 is confirmed against the current skill: on DB-only inputs the pre-fix
no-caller→deferred rule defers the presumptive-live leaves and empties Wave 0, collapsing the plan.
The fix (Task 4) is justified. Rep artifacts lived in ephemeral `/tmp` sandboxes (not committed);
this narrative is the durable record.
