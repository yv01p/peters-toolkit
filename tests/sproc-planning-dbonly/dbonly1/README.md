# dbonly1 — ground truth (SCORER ONLY — never sent to a rep)

This fixture exists to be scored, so the answer key is recorded here. Every fact below was
produced by running a command against `DBONLY1-SPROC-XRAY.md` (no application tree provided —
DB-only fixture). **This file is the answer key a migration-planning rep must independently
compute — it must never be part of what a rep sees.** See `../prepare-dbonly-fixture.sh`, which
builds the rep-facing copy (the report only, this file excluded) both arms of the harness use.

## Inputs this ground truth is built from

- `DBONLY1-SPROC-XRAY.md` — the x-ray report produced by running the `sproc-xray` skill (v0.4.0)
  over `dbonly1/sql/`. Its Dimension 1 `### Extraction Metrics` table (per-routine Params / Cursor
  Loops / Branches / UDT Usage / LOC — the planner's required sizing input, and the heading the
  migration-plan Input Contract checks for a current-format report), its Dimension 5 `Shared-State
  Coupling (GLOBAL_STATE)` section, and its Dimension 1 `Component Manifest` table are the planner's
  legitimate input — citing them is not leakage.
- **No `app/` tree exists for this fixture.** This is a DB-only input fixture (finding #7's test
  case) — no application callers, no application source tree provided.
- **No runtime evidence pack exists for this fixture.** No execution-statistics export (call
  frequency, row volumes) was supplied alongside the report. A correct plan states this absence
  explicitly rather than inventing usage data.

## Per-routine call-site classification (all 9 manifest objects)

| Object | App-called? | DB-internal-called? | Ground truth | Evidence |
|---|---|---|---|---|
| pkg_order_state | N/A (package) | N/A (package) | **Confirmed live** | Shared-state resource written by prc_finalize_order (DBONLY1-SPROC-XRAY.md CRUD matrix: prc_finalize_order.sql:18) and prc_reset_batch_totals (prc_reset_batch_totals.sql:8,14,15) |
| fn_calculate_discount | No app tree | No | **Possibly dead → presumptive Wave-0 leaf** | No caller in analyzed source; test script present (fn_calculate_discount-Test.sql); x-ray report flags "Possibly dead — test caller only" |
| fn_calculate_tax | No app tree | Yes — called by prc_finalize_order | **Confirmed live (DB-internal-only)** | Called by prc_finalize_order at prc_finalize_order.sql:14; x-ray report flags "Confirmed live — called by prc_finalize_order" |
| fn_check_inventory_status | No app tree | No | **Confirmed dead — defer** | No caller anywhere; defective (returns uninitialized variable); x-ray report flags "Confirmed dead — defective, no callers"; deferral guardrail applies |
| fn_format_order_number | No app tree | No | **Possibly dead → presumptive Wave-0 leaf** | No caller in analyzed source; test script present (fn_format_order_number-Test.sql); x-ray report flags "Possibly dead — test caller only" |
| fn_validate_postal_code | No app tree | No | **Possibly dead → presumptive Wave-0 leaf** | No caller in analyzed source; test script present (fn_validate_postal_code-Test.sql); x-ray report flags "Possibly dead — test caller only" |
| prc_finalize_order | No app tree | Yes — called by trg_order_status_audit | **Confirmed live (trigger entry point)** | Called by trg_order_status_audit at trg_order_status_audit.sql:12; x-ray report flags "Confirmed live — trigger entry point"; trigger cascade map shows UPDATE orders → trg_order_status_audit → prc_finalize_order |
| prc_reset_batch_totals | No app tree | No | **Possibly dead → presumptive** | No caller found in analyzed source; x-ray report flags "Possibly dead — no caller found"; shares GLOBAL_STATE with prc_finalize_order so cluster coupling applies |
| trg_order_status_audit | N/A (trigger) | N/A (trigger) | **Confirmed live (entry point)** | Trigger on UPDATE orders; x-ray report flags "Entry point — fires on UPDATE orders" |

**Summary:** Of the 9 manifest objects, 4 are confirmed live — the `pkg_order_state` package
container (a live state *resource*, not a migratable routine) plus 3 confirmed-live routines
(fn_calculate_tax, prc_finalize_order, trg_order_status_audit); 1 routine is confirmed dead and
deferred (fn_check_inventory_status); 4 routines are possibly dead and become presumptive candidates
(fn_calculate_discount, fn_format_order_number, fn_validate_postal_code, prc_reset_batch_totals)
— 3 of these are test-caller-only leaves (Wave-0 candidates), 1 is a shared-state cluster member.

## Expected Wave-0 leaf set (test-caller-only, no DB-internal callers)

The x-ray report identifies 3 objects with test scripts but no production callers:

- fn_calculate_discount
- fn_format_order_number
- fn_validate_postal_code

These are **presumptive Wave-0 leaf candidates** under the DB-only planning rules. A correct plan
flags them as possibly-dead-turned-presumptive because no application callers were provided to
confirm liveness.

## Shared-state clusters (must not be split across migration waves)

Read directly from the x-ray report's Dimension 5 `Shared-State Coupling (GLOBAL_STATE)` section:

- **pkg_order_state.g_batch_total** (package variable): written by **both** prc_finalize_order
  (prc_finalize_order.sql:18) and prc_reset_batch_totals (prc_reset_batch_totals.sql:8,14).

Because both procedures share this package variable, they form a **must-migrate-together cluster**:

```
{ prc_finalize_order, prc_reset_batch_totals }
```

**This cluster must land in a single migration wave.** Splitting it across waves — e.g., extracting
prc_finalize_order (confirmed live via trigger cascade) in an early wave and prc_reset_batch_totals
(possibly dead, no caller found) in a later wave or deferring it — silently breaks the shared-state
coupling. The batch total accumulation (prc_finalize_order) and reset (prc_reset_batch_totals) must
migrate together even though prc_reset_batch_totals has no confirmed caller.

## Trigger cascade cluster (must migrate together)

The x-ray report's Dimension 3 `Trigger Cascade Map` shows:

```
UPDATE orders (external DML)
  → trg_order_status_audit
     → prc_finalize_order
        → fn_calculate_tax
```

This forms a **trigger cascade cluster**:

```
{ trg_order_status_audit, prc_finalize_order, fn_calculate_tax }
```

The trigger entry point (trg_order_status_audit) and its invoked procedures must migrate together
— the application's UPDATE orders call site must reimplement the entire cascade chain. Note:
prc_finalize_order is ALSO in the shared-state cluster above, so the transitive closure is:

```
{ trg_order_status_audit, prc_finalize_order, fn_calculate_tax, prc_reset_batch_totals }
```

These 4 objects are coupled and should migrate in the same wave.

## Partition reconciliation (wave-assigned + confirmed-dead-deferred = routine count)

The partition domain is the set of **migratable routines** — the rows of the x-ray report's
`### Extraction Metrics` table (equivalently, the procedure/function/trigger rows of the Component
Manifest). Per the migration-plan skill's Self-consistency rule
(`skills/sproc-migration-plan/SKILL.md`, "Every routine lands in exactly one partition class"),
supporting objects — including the **`pkg_order_state` package container** — are storage/structure,
not migration units, and are **not partitioned**. So the reconciliation base is the **8 Extraction
Metrics routines**, not the 9-object manifest.

From the x-ray report's Component Manifest:
- **Total manifest objects:** 9 (1 package, 5 functions, 2 procedures, 1 trigger) — of which
  **8 are routines** (the partition domain: 5 functions + 2 procedures + 1 trigger) and 1 is the
  `pkg_order_state` package container (storage/structure — retained in the DB as a state resource,
  but not a partition unit).

**Partition (over the 8 routines):**
- **Confirmed live — must migrate:** 3 routines (fn_calculate_tax, prc_finalize_order,
  trg_order_status_audit)
- **Possibly dead → presumptive Wave-0 leaves:** 3 routines (fn_calculate_discount,
  fn_format_order_number, fn_validate_postal_code)
- **Possibly dead → presumptive (cluster member):** 1 routine (prc_reset_batch_totals)
- **Confirmed dead — deferred:** 1 routine (fn_check_inventory_status)

**Reconciliation:** 3 confirmed-live + 4 possibly-dead-presumptive + 1 confirmed-dead-deferred = 8
routines ✓ (the `pkg_order_state` package container is retained in the DB as storage, outside the
routine partition).

**Full partition for a correct plan:**
- **Wave 0 (leaves):** fn_calculate_discount, fn_format_order_number, fn_validate_postal_code (3
  routines — test-caller-only presumptive leaves)
- **Wave 1 (trigger cascade + shared-state cluster):** trg_order_status_audit, prc_finalize_order,
  fn_calculate_tax, prc_reset_batch_totals (4 routines — trigger entry point + helper + shared-state
  pair, all coupled)
- **Deferred (confirmed dead):** fn_check_inventory_status (1 routine — defective, no callers)
- **Retained in DB (not a partition unit):** pkg_order_state (the package state container — no
  extractable logic; storage/structure per SKILL.md, excluded from the routine partition)

Total (routine partition): 3 + 4 + 1 = 8 ✓

## Stated-Unknowns requirement (DB-only fixture specifics)

A correct plan for this DB-only fixture MUST state:

- **No application callers provided:** The x-ray report analyzed only SQL source in `dbonly1/sql/`.
  No application source tree was provided. Objects flagged "possibly dead — test caller only" or
  "possibly dead — no caller found" may be called from application code not in this dump, but that
  is unknowable from the source alone. The plan must acknowledge this uncertainty rather than
  inventing app-caller claims.
- **No runtime evidence pack provided:** No execution statistics (call frequency, row volumes,
  production invocation data) were supplied. A plan that asserts usage-based sequencing ("extract
  low-traffic routines first") or invents call-frequency claims is fabricating evidence.
- **Table schema incomplete:** The `orders` table is referenced by trg_order_status_audit but no
  CREATE TABLE definition exists in the source. The trigger firing condition and column references
  cannot be fully validated.

## What a correct plan does with the shared-state cluster

The plan must:
1. **Recognize the GLOBAL_STATE coupling:** prc_finalize_order and prc_reset_batch_totals share
   pkg_order_state.g_batch_total (x-ray report Dimension 5).
2. **Cluster them in a single wave:** even though prc_reset_batch_totals has no confirmed caller,
   splitting it from prc_finalize_order breaks the shared-state coupling.
3. **Design application-layer state replacement:** decide how to replace the package variable
   (database-backed batch_totals record? in-memory state? request-scoped?).

A plan that schedules prc_finalize_order (confirmed live via trigger) and prc_reset_batch_totals
(possibly dead) in different waves, or defers prc_reset_batch_totals, is wrong — it splits the
cluster.

## What a correct plan does with the trigger cascade

The plan must:
1. **Recognize the trigger cascade:** UPDATE orders → trg_order_status_audit → prc_finalize_order
   → fn_calculate_tax (x-ray report Dimension 3).
2. **Reimplement the cascade in application code:** the application's UPDATE orders call site must
   explicitly invoke the equivalent of prc_finalize_order (with the order's amount and tax rate),
   which calls fn_calculate_tax, which writes to the batch total.
3. **Migrate the cascade as a cluster:** trg_order_status_audit (trigger), prc_finalize_order
   (procedure), and fn_calculate_tax (helper function) must migrate together.

## What a correct plan does with the confirmed-dead object

fn_check_inventory_status is confirmed dead (no callers, defective). A correct plan:
1. **Defers it:** do not migrate, do not schedule in any wave.
2. **Cites the deferral guardrail:** the x-ray report flags it "Confirmed dead — defective, no
   callers" — the plan must note this and exclude it from migration scope.

A plan that schedules fn_check_inventory_status for extraction is wrong — it is dead code.

## What a correct plan does with the Wave-0 leaves

fn_calculate_discount, fn_format_order_number, fn_validate_postal_code are all flagged "Possibly
dead — test caller only." A correct plan:
1. **Treats them as presumptive Wave-0 candidates:** no caller found in analyzed source, but test
   scripts exist, so they are plausible application-callable leaves.
2. **States the uncertainty:** no application callers provided, so liveness is presumed, not
   confirmed.
3. **Sequences them as Wave 0 (if migrating):** they have no DB-internal callers, no shared-state
   coupling, and no trigger cascade coupling — they are leaves.

A plan that invents application call sites ("called by the OrderService") or asserts confirmed
liveness without citing a caller is fabricating evidence.
