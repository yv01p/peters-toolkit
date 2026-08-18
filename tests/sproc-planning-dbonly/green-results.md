# GREEN evidence — fixed `sproc-migration-plan` plans DB-only inputs correctly (finding #7)

**Arm:** GREEN (fixed skill). **Fixture:** `tests/sproc-planning-dbonly/dbonly1` (DB-only x-ray report,
no `app/` tree, no runtime pack) — the SAME corrected fixture the RED arm used. **Reps:** 5, fresh
context each, **model pinned: Sonnet** (identical to the RED arm — so the RED↔GREEN contrast isolates
the skill-version variable and is not model-confounded). **Skill under test:** a staged, neutral copy
of the **fixed** `skills/sproc-migration-plan/SKILL.md` (HEAD `0038744`, the finding-#7 method
correction — the version that scopes the no-caller→deferral rule to non-DB-only mode, adds the
three-way DB-only classification, and populates Wave 0 from structural leaves). **Verdict: GREEN bar
CLEARED — 5/5 reps POPULATED on all 8 dimensions. The finding-#7 fix removes the collapse from the
SKILL itself; even rule-following reps now produce populated plans.**

## What this arm demonstrates (contrast with RED)

RED (`baseline-results.md`, pre-fix skill, same fixture, same model) fired the collapse gate: 4/5 reps
went `NEAR_EMPTY` with `EMPTY_OR_MISSING` Wave 0 and the 3 test-caller-only leaves `WRONGLY_DEFERRED`
(reps 3–4 also SPLIT the GLOBAL_STATE cluster). Only RED rep 5 populated a plan, and only by reasoning
*around* the pre-fix rule (the documented `trgplan1`-style outlier). GREEN reverses this at the skill
level: with the fixed skill's rule as written, **all 5 reps** wave-assign the 3 structural leaves and
the 4-object trigger/shared-state cluster, keep the GLOBAL_STATE pair together (0 splits, vs RED's
2/5), classify the trigger live, and defer only the x-ray-confirmed-dead routine. The behavior the
outlier had to override the pre-fix rule to achieve is now the rule's default output.

## REP-ISOLATION attestation (Ruling 14 + anti-installed-skill)

- **Neutral sandbox:** each rep ran in an opaque `/tmp/tmp.XXXXXXXX/dbonly1` path (no segment naming
  the repo, branch, or skill); fixture built by `prepare-dbonly-fixture.sh` (report only, README/answer
  key excluded — verified absent in every sandbox, no `app/` tree).
- **Confinement preamble:** every rep received the ENVIRONMENT block scoping it to `{FIXTURE_PATH}`.
- **Staged skill:** `{SKILL_PATH}` pointed at a copy of the **fixed** skill placed **inside** each rep's
  fixture dir (`.../dbonly1/skill-under-test.md`, so `{SKILL_PATH} ⊂ {FIXTURE_PATH}`) — never the
  in-checkout skill path.
- **Anti-installed-skill TASK-CONSTRAINTS block:** every rep prompt forbade invoking the Skill tool's
  `sproc-migration-plan` / `peters-toolkit:*` and pinned the rep to the staged file as sole authority.

**Answer-key channel note (GREEN-arm-specific).** The fixed skill's Maintainer note cites
`tests/sproc-planning-dbonly/baseline-results.md` (this fixture's RED answer-key/scoring file) and
`tests/sproc-planning/baseline-results.md` by relative path. Reps run via the Agent tool with `cwd` =
the repo root, so those relative paths would resolve to the real files from a rep's shell — a wander
channel to an answer key. The confinement preamble (do not read outside `{FIXTURE_PATH}`, no `..`, no
repo root) closed it behaviorally, and the tell-scan below confirms no rep exercised it.

## Tell-scan: 5/5 CLEAN

The GREEN tell-scan (like the sibling `tests/sproc-planning/green-results.md`) looks for the **inverse**
signal from the RED arm: skill-methodology vocabulary (waves, Pattern A–E, 5-gate progression,
10-dimension complexity, partition reconciliation) is **expected** here — every rep read the staged
skill — so it is not a contamination tell. The scan instead hunts for answer-key/rubric vocabulary
("RED gate", "GREEN bar", "WRONGLY_DEFERRED", "NEAR_EMPTY", "verdict" in the scoring sense) or any
disclosure of reading a repo path outside the sandbox.

- **Zero answer-key/rubric vocabulary** in any of the 5 plans. Every "verdict" occurrence is the phrase
  *"x-ray verdict"* / *"liveness verdict"* — a reference to the x-ray report's Dead/Orphan
  classification, not the scorer's rubric. No plan cites `baseline-results.md`, `green-results.md`,
  `.superpowers`, `peters-toolkit`, `tests/sproc`, `docs/`, or the README answer key.
- **Zero out-of-sandbox disclosure.** One phrase was inspected and cleared: rep 3 writes that its
  "application codebase search path (`/tmp/tmp.IVSiBnjvFy/dbonly1`)" held no app source — that is the
  rep naming *its own sandbox*, not the real checkout; every citation resolves to a fixture file.
- **Decisive blindness signal — base=8, not the answer key's 9.** All 5 reps independently reconciled
  their partition against the **8 routines** in the report's `### Extraction Metrics` table, explicitly
  treating `pkg_order_state` as a non-routine state resource. The committed answer key
  (`dbonly1/README.md`) counts **9** (package = retained-in-DB). A rep that had wandered into the README
  or the RED file would have inherited the 9-count; all 5 landed on 8, matching each other and the RED
  arm and blind to the answer key.
- **Fixed-skill fingerprints present.** All 5 use the fix's new DB-only vocabulary
  (`presumptive-live-unconfirmed`, `x-ray-confirmed-dead`, `confirmed-live` from DB-internal evidence)
  and every complexity score cites the report's Extraction Metrics columns — confirming reps planned
  from the staged **fixed** skill, not a pre-fix or installed version.

No discards this round.

## Per-rep scoring (8 dimensions; see rep-prompt-template.md Part 2)

| # | Dimension | Rep 1 | Rep 2 | Rep 3 | Rep 4 | Rep 5 |
|---|---|---|---|---|---|---|
| 1 | Executable plan not near-empty | POPULATED | POPULATED | POPULATED | POPULATED | POPULATED |
| 2 | Wave 0 populated from structural leaves | POPULATED | POPULATED | POPULATED | POPULATED (2/3 + cited move) | POPULATED |
| 3 | Possibly-dead routines wave-assigned | WAVE_ASSIGNED | WAVE_ASSIGNED | WAVE_ASSIGNED | WAVE_ASSIGNED | WAVE_ASSIGNED |
| 4 | Confirmed-dead routine deferred/dropped | DEFERRED | DEFERRED | DEFERRED (as deletion candidate) | DEFERRED (as deletion candidate) | DEFERRED |
| 5 | GLOBAL_STATE cluster kept in one wave | RESPECTED | RESPECTED | RESPECTED | RESPECTED | RESPECTED |
| 6 | Trigger cascade clustered; trigger live | RESPECTED | RESPECTED | RESPECTED | RESPECTED | RESPECTED |
| 7 | Stated-Unknowns (DB-only + pack gap) | STATED | STATED | STATED | STATED | STATED |
| 8 | Partition reconciliation | base=8 ✓ | base=8 ✓ | base=8 ✓ | base=8 ✓ | base=8 ✓ |

**GREEN bar (§2d): every dimension at 5/5 (bar is ≥4/5). CLEARED.**

### Wave structures produced (all populated; the fix does not mandate one shape)

The 8 behavioral dimensions — not an exact wave layout — are what the GREEN bar checks. The 5 reps
produced 4 distinct valid wave schemes, all populated:

- **Rep 1** (3 waves): W0 = {discount, format, postal, **tax**}; W1 = {finalize_order, reset_batch_totals}; W2 = {trigger}.
- **Rep 2** (3 waves): W0 = {**tax**, discount, format, postal}; W1 = {finalize_order, reset_batch_totals}; W2 = {trigger}.
- **Rep 3** (3 waves): W0 = {discount, format, postal}; W1 = {**tax**, finalize_order, reset_batch_totals}; W2 = {trigger}.
- **Rep 4** (5 waves): W0 = {format, postal}; W1 = {tax}; W2 = {discount}; W3 = {finalize_order, reset_batch_totals}; W4 = {trigger}.
- **Rep 5** (2 waves): W0 = {discount, format, postal}; W1 = {tax, finalize_order, reset_batch_totals, trigger} — matches the answer key's wave structure exactly (3 leaves + the 4-object cascade/shared-state cluster).

In every scheme the 3 test-caller-only leaves are wave-assigned (never deferred), the GLOBAL_STATE pair
migrates together, the trigger cascade is clustered or explicitly dependency-sequenced with the trigger
classified live, and only `fn_check_inventory_status` is excluded.

## Definitional variations (recorded honestly; none breaches the GREEN bar)

Scored on the same basis as RED, per the RED-arm watch items:

1. **Dim 4 — "deferred" vs "deletion candidate."** Reps 1, 2, 5 place `fn_check_inventory_status` in a
   *Deferred / Needs-Investigation* section; reps 3, 4 place it in a *Deletion Candidates* section (drop
   it). Both dispositions **exclude the confirmed-dead defective routine from every migration wave** — the
   rubric's `DEFERRED` verdict is "correctly excluded, deferred, or flagged do not migrate," and the
   fixed skill routes x-ray-confirmed-dead to "deferred/drop." All 5 = correct exclusion; none migrates it.
2. **Dim 2 — rep 4's leaf placement.** Rep 4 puts 2 of the 3 leaves in Wave 0 and moves
   `fn_calculate_discount` to a later wave **with a cited reason** (externalize its hardcoded discount
   tiers before extraction). The rubric scores `POPULATED` when Wave 0 "carries all 3, **or** explains why
   one is moved elsewhere with a cited reason." Rep 4 satisfies the cited-reason clause; its Wave 0 still
   carries 2 leaves (not zero), so it is nowhere near `EMPTY_OR_MISSING`. The other 4 reps carry all 3
   leaves in Wave 0.
3. **Dim 8 — base=8 vs the answer key's 9.** All 5 reps reconciled against the 8 Extraction-Metrics
   routines, treating the `pkg_order_state` package as a non-routine state resource (retained/replaced),
   not a partition unit — consistently, and each rep's own partition sums correctly (no object lost). The
   answer key counts 9 (package as retained-in-DB). This is the same routine-count-vs-object-count
   definitional difference recorded in the RED arm, scored on the identical base=8 basis for a clean
   contrast — not a lost-object under-count.

## GREEN-bar verdict

Per rep-prompt-template.md §2d, the GREEN arm passes when, across ≥5 reps, all 8 dimensions hold at
≥4/5: `POPULATED` (crit 1), `POPULATED` Wave 0 (crit 2), `WAVE_ASSIGNED` (crit 3), `DEFERRED` (crit 4),
`RESPECTED` GLOBAL_STATE (crit 5), `RESPECTED` trigger cascade (crit 6), `STATED` (crit 7), `RECONCILED`
(crit 8). **Observed: 5/5 on every dimension. GREEN bar CLEARED.** Against the RED baseline (4/5 collapse
on crits 1–3, 2/5 cluster split on crit 5), the finding-#7 fix is validated: on DB-only inputs the fixed
skill classifies presumptive-live leaves into waves and populates Wave 0 from structural leaves instead
of deferring for want of an application caller. Rep artifacts lived in ephemeral `/tmp` sandboxes (not
committed); this narrative is the durable record. Sandboxes cleaned.
