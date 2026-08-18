---
name: sproc-migration-plan
version: 0.1.0
description: Use when a sproc-xray report is in hand and the database-logic extraction needs a plan — sequencing, sizing, and clustering stored procedures, functions, and triggers into migration waves, or assembling a database-to-application-code migration backlog. Trigger when handed a {SYSTEM}-SPROC-XRAY.md report to plan against, or asked which DB routines to extract first.
---

# Stored Procedure Migration Plan

## Overview

Turn a `sproc-xray` evidence report into a wave-sequenced migration plan in which **each
wave is a thorough-brainstorming-ready brief**. The x-ray answers *what behavior the
database holds*; this skill answers *in what order, in what clusters, and under what
validation gates that behavior leaves the database.*

**Core principle: facts come from the x-ray, judgment is the planner's, and every
judgment cites its facts.** Complexity scores, priorities, and wave assignments are the
planner's judgments — labeled as such — but every factual input to a judgment cites the
x-ray report, the runtime evidence pack, or the application codebase (`app FILE:LINE`).
A score whose inputs have no citation is not written.

## When to Use

- A `sproc-xray` report exists and the extraction needs to be scoped into work units
- Planning which stored procedures / functions / triggers to migrate first, and together
- Assembling a database-to-application-code migration backlog from discovery evidence
- Turning dozens-to-hundreds of DB routines into scored, clustered, sequenced waves

**When NOT to use:**
- No current-format x-ray report yet — run `sproc-xray` first (this skill consumes its output)
- Designing the target architecture of any one wave (that is the wave's own TB session)
- Deciding microservice/bounded-context boundaries (flagged here, decided downstream)
- Sproc-to-sproc translation or PostgreSQL-as-source analysis (out of scope, as for the x-ray)

## Input Contract

Four inputs. The first two are required; the plan is not written until both are supplied.

### 1. Required — the sproc-xray report (structurally validated before any planning)

Validate the report BEFORE planning. Reject anything that fails, with a clear message.
Generic markers are insufficient: `cobol-xray` reports also carry five numbered `## 1.`–`## 5.`
sections and a "Confidence & Coverage Declaration" heading, so the check must key on markers
unique to `sproc-xray`'s current report format:

| Required marker | Why |
|---|---|
| A `## Coverage Declaration` section | Present in every sproc-xray report |
| At least one unique dimension title — `CRUD Matrix & Trigger Cascade Map` or `Dialect Footguns & Hidden Risks` | These titles appear only in sproc-xray's format, never in cobol-xray's |
| The `### Extraction Metrics` **heading** (the heading, not the words in prose) | Marks a current-format report — carries the params/cursor-loop/branch/UDT/LOC facts the complexity dimensions and pattern assignment need |
| The `-SPROC-XRAY.md` filename suffix (secondary check) | Corroborates provenance |

A report predating the `### Extraction Metrics` table and the `GLOBAL_STATE` category is
**rejected** with **"re-run sproc-xray at the current version"** — not accepted with
degraded planning. Those reports lack the facts that complexity scoring, shared-state /
temp-table cluster detection, and pattern assignment (B/C/D indicators) all require, and
`sproc-xray v0.3.0` never shipped, so regenerating the report is a re-run of a skill the
user already has, not a request for anything new.

### 2. Required — the application codebase path

The tree that calls the database objects. **Often the same repository that contains the
SQL source — pointing both inputs at one tree is valid.** Grep it for object names to
produce app-caller citations (`app FILE:LINE`).

- **The grep is case-insensitive.** Unquoted SQL identifiers are case-insensitive, so
  app-side casings legitimately vary (`PRC_Settlement_Sweep` and `prc_settlement_sweep`
  are the same object).
- **Match on the report's declared/Object-Name column, never on the SQL filename.**
  Declared names diverge from filenames (`C_Currency_Convert.sql` may declare
  `currencyConvert`; `BOM_PriceLimit.sql` may declare `Bompricelimit`). Take each object's
  name from the Component Manifest's **Object Name** column and search the app tree for
  THAT string.
- **Short-name over-match caveat.** Short object names (`round`, `trunc`, `post_batch_totals`)
  over-match in application code. A textual hit is a candidate, not a call site: confirm each
  short-name hit per-hit by reading it for actual invocation syntax
  (`CallableStatement`, `{call ...}`, an ORM/JDBC invocation) before citing it. A field named
  `POST_BATCH_TOTALS_ARCHIVE` or a getter `getPostBatchTotalsRowCount` is name proximity, not
  an invocation.

### 3. Optional — a runtime evidence pack

A directory of query-output exports produced per `references/runtime-evidence.md`. It is
optional and **degrades gracefully**:

| Missing | Effect |
|---|---|
| Execution counts (dead-code triage input) | No deletion candidates; uncalled objects route to deferred/needs-investigation when a caller search could have succeeded (app-present), not on DB-only inputs |
| Row counts (Pattern C volume gate, data-volume dimension) | Data-volume dimension scores Unknown; Pattern C viability flagged Unknown |
| Performance baselines / call-frequency | Shadow-sampling tiers default to the conservative tier |

Whatever the pack does or does not contain is stated in the plan's **Stated Unknowns**
section (see below). Absence is stated, never silently assumed resolved and never filled
with invented usage figures.

### 4. Optional — user constraints (gathered interactively)

Target stack, team size, business-priority domains, deadline pressure. **Business-value
scores come from the user or default to neutral, and the plan states which.** Business
value is never invented from coupling, risk, or size — those are different measures.

## Output Contract & Terminal STOP

Write the plan to **`plans/{SYSTEM}-MIGRATION-PLAN.md`** in the current working directory.
Derive `{SYSTEM}` the same way `sproc-xray` derives its report name: uppercase the
repository/directory name verbatim (so a `FLEETBILL-SPROC-XRAY.md` report yields
`plans/FLEETBILL-MIGRATION-PLAN.md`).

**The plan file is the terminal handoff. The skill STOPS there.** It does NOT auto-invoke
`thorough-brainstorming` or any other skill. Each wave later runs its own
TB → CDR → (UDD) → TWP → CIR → (UIP) → SDD cycle when someone picks it up — that is a
separate, human-initiated step, not something this skill chains into.

## Planning Method

Work these eight steps in order; each builds on the prior.

### Step 1 — Intake & validation

Validate the report structurally (Input 1). Confirm the application-codebase path exists
(Input 2). Detect whether a runtime pack is present and enumerate which exports it
contains. Record the whole intake as the seed of the Stated Unknowns section.

### Step 2 — Consumer analysis

Classify each routine's call surface from cited evidence. **Join the x-ray's routines to
the application code on the Component Manifest's Object Name column (case-insensitive,
schema-qualified when the report name carries a schema), never on the SQL filename** — see
Input 2. Four classes:

| Class | Evidence |
|---|---|
| **DB-internal-called** | A caller is cited inside the x-ray (its dependency graph / CRUD matrix) |
| **App-called** | A confirmed invocation found by grepping the application codebase, cited `app FILE:LINE` |
| **Both** | Cited in both sources |
| **No-caller-found** | Neither source cites a caller |

**DB-only inputs.** When the grep finds no confirmed app caller for any routine (zero
App-called / Both rows) **and** no runtime pack is supplied, the inputs are **DB-only** and
the absent-app no-caller signal does **not** route to deferral — it is not evidence of
dead code when the application codebase that would call those routines is not part of the
evidence set. Instead, classify from x-ray DB-internal evidence: **confirmed-live**
(trigger, or cited DB-internal caller — the existing DB-internal-called class);
**x-ray-confirmed-dead** (the x-ray's Dead/Orphan "confirmed dead — no reference anywhere
in the corpus" verdict → deferred/drop, the *only* class that defers on this basis);
**presumptive-live-unconfirmed** (any other routine, including the x-ray's "possibly dead —
insufficient evidence" sub-class → wave-assigned, sequenced structurally from the x-ray's
dependency graph, liveness stated unconfirmed in Stated Unknowns).

- A **no-caller-found** routine corroborates dead-code triage *when the runtime pack agrees
  it has zero executions*; without a pack it routes to deferred/needs-investigation **only
  when a caller search could have succeeded** (app-present or pack-present), never to
  silent migration and never to silent deletion.
- A runtime execution with **no** citation in either source indicates a **non-app external
  caller** (scheduler, DB link, DB job) — flag it for investigation rather than calling it
  dead.
- **DB-internal callers create dual-path objects.** When a routine is called from inside the
  database (e.g., a view or another function calls it), its SQL must be **retained** even
  after the application path cuts over — the DB-internal caller still needs it. Real
  precedent: ADempiere Wave 3, where `RV_OPENITEM` / `RV_BPARTNEROPEN` / `RV_PAYMENT` views
  call SQL functions inside PostgreSQL; migrating those functions for the *view* path was
  architecturally unnecessary. A routine with *only* DB-internal callers may not need
  migration at all until its callers do — it is a **retained-in-DB** object, not a wave unit,
  unless a caller of it migrates.

### Step 3 — Dead-code triage (runtime pack only)

With a runtime pack, a routine with **zero executions in the observation window** becomes a
**deletion candidate**, never a migration unit. A verification checklist travels with each
candidate: scheduled jobs, triggers, business-owner confirmation. (App-code references are
already covered by Step 2's grep.) **Without a runtime pack there are no deletion candidates**
— uncalled routines are deferred/needs-investigation **when a caller search could have
succeeded** (app-present) with "what evidence would resolve this" stated; on DB-only inputs
they route per Step 2's three-way DB-internal classification instead.

### Step 4 — Complexity scoring

Score each routine on the 10-dimension matrix. **Each dimension is fed from a cited x-ray
fact or runtime-pack value; a dimension with no evidence scores Unknown, is scored `2`, and
is flagged.** Each dimension is 1–3.

| # | Dimension | Fed from (cited) | 1 | 2 | 3 |
|---|---|---|---|---|---|
| 1 | LOC | Extraction Metrics LOC | < 50 | 50–150 | > 150 |
| 2 | Branching | Extraction Metrics `Branches` | 0–3 | 4–10 | 11+ |
| 3 | Tables accessed | CRUD Matrix distinct resources for the object | 1–2 | 3–5 | 6+ |
| 4 | Parameters | Extraction Metrics `Params` | 0–2 | 3–5 | 6+ |
| 5 | Cursor loops | Extraction Metrics `Cursor Loops` | 0 | 1 | 2+ (nested) |
| 6 | Dynamic SQL | Dimension 2 reduced-confidence edges | none | Unknown | present |
| 7 | Global state | Dimension 5 `GLOBAL_STATE` rows for the object | none | reads shared / single-toucher | writes shared state / cluster member |
| 8 | External calls | Dimension 2 External/Unresolvable Edges | none | 1–2 | 3+ |
| 9 | Non-standard data types | Extraction Metrics `UDT Usage` | none | one construct | multiple |
| 10 | Data volume | Runtime pack row counts | small | Unknown (no pack) or medium | large |

Sum the ten scores. Classification bands (from the validated manual methodology):

| Band | Sum |
|---|---|
| Simple | 10–15 |
| Medium | 16–22 |
| Complex | 23–30 |

The band is a judgment; the ten inputs are cited facts. In each unit's row, cite the x-ray
fact behind each non-trivial dimension so a reader can re-derive the score.

### Step 5 — Cluster detection

Clusters are sets of routines that must migrate together, or in a fixed order. Detect them
from cited x-ray facts, not from intuition:

| Cluster kind | Detected from | Constraint |
|---|---|---|
| **Shared-state / temp-table** | Dimension 5 `GLOBAL_STATE` rows — two routines citing the **same** temp table or package variable is a cluster edge | Migrate together (same wave) |
| **Transaction** | Dimension 4 atomic groups / transaction boundaries | Migrate together (same wave) |
| **Data-flow** | Dimension 2 dependency graph (caller → callee) | Migrate in order |
| **Trigger cascade** | Dimension 3 Trigger Cascade Map | Always a cluster — the whole chain migrates as one unit |

Shared-state edges are transitive: if routine B shares a package variable with A and a temp
table with C, then {A, B, C} is one cluster and lands in one wave — even when no call edge
connects them. This is the coupling the dependency graph cannot see, and it is why Dimension
5 is read before waves are assembled.

### Step 6 — Pattern assignment

Assign one primary migration pattern per unit, language-agnostic (catalog with x-ray-visible
indicators and pitfalls in `references/patterns.md`):

| Pattern | From | To |
|---|---|---|
| **A** | CRUD routine | repository |
| **B** | cursor / nested-loop | stream / iteration |
| **C** | temp table | in-memory collection — **volume-gated** |
| **D** | procedural logic | domain code |
| **E** | dynamic SQL | query builder |

**Pattern C is volume-gated:** it requires runtime row counts to confirm the staged set fits
in memory. Without row counts, assign the unit Pattern C but mark it **"Pattern C viability
Unknown"** and record the gap in Stated Unknowns — never assume it fits.

### Step 7 — Wave assembly

- **Wave 0 is the Safe-to-Fail harness plus simple leaf functions from the x-ray's structure**
  — the learning wave. Draw its leaves from the x-ray's Extraction Sequencing (dependency-graph
  leaves ∩ low complexity), not from caller evidence. The validated real-world Wave 0 held
  infrastructure + ~8 simple functions; "~8" is illustrative (the actual validated count), not
  a quota — take as many simple leaves as the corpus has, else just the harness. Its point is
  to stand up the validation framework in `references/safe-to-fail.md` against low-risk units
  before anything hard moves.
- **Subsequent waves** are ordered by a priority score:

  `priority = (BusinessValue×3) + (Simplicity×2) + (Independence×2) + (RiskReduction×1) + (LearningValue×1)`

  Assemble waves respecting cluster constraints (Step 5) and **leaves-first / hubs-later /
  triggers-last** ordering from the x-ray's Extraction Sequencing. A cluster never splits
  across waves; a whole cluster's priority is its members' aggregate.
- **State every cross-wave dependency edge explicitly**, e.g. "Wave 3 blocked by
  `paymentTermDiscount` in Wave 2."

### Step 8 — Validation stamping

Stamp each wave brief with its validation requirements (see the Wave-Brief Contract below):
the E2E-tests-first hard gate, the shadow-sampling tier, comparator needs, the variable
performance thresholds, the 5-gate progression, and the rollback expectation.

## Wave-Brief Contract

Every wave section is self-contained and TB-ready, and every wave has the **same** shape so
a downstream consumer can parse any wave the same way. In order:

1. **Theme & rationale** — why these units, why now.
2. **Unit table** — one row per unit, with exactly these columns:

   | Object | Complexity (sum + band) | Per-dimension evidence | Pattern | SQL retained? | x-ray FILE:LINE |
   |---|---|---|---|---|---|

   The `Per-dimension evidence` cell cites the x-ray fact behind each non-trivial dimension
   score. `SQL retained?` is `yes (reason)` for a dual-path unit, else `no`.
3. **Cluster constraints** — must-migrate-together and ordered-within-wave sets, each naming
   the Dimension-5/Dimension-4/Dimension-2 fact that binds it.
4. **Blocking dependencies** — the explicit cross-wave edges this wave waits on.
5. **Validation requirements:**
   - **E2E-tests-first hard gate:** before any unit converts, end-to-end tests capturing its
     observable behavior must exist and **pass against the SQL implementation**; the same
     tests are the cutover evidence. E2E tests are the only failsafe verification of a
     migration.
   - **Shadow-mode sampling tier** by call frequency (from the runtime pack; conservative
     default without one).
   - **Comparator needs** — timestamp tolerance, decimal tolerance, order-insensitive
     collections.
   - **Variable performance thresholds:** absolute per-call overhead governs, not ratio alone
     — sub-millisecond overhead permits relaxed ratios; ≥1ms overhead requires tight ratios.
   - **The 5-gate progression:** Gate 1 Code Complete → Gate 2 SQL-only baseline → Gate 3
     Shadow validation (99.9% match, 7 consecutive days) → Gate 4 Cutover (stakeholder
     sign-off, rollback drill executed) → Gate 5 Post-cutover monitoring (7 days; SQL
     retained ≥ 30 days).
6. **Rollback expectation** — the drill required before Gate 4.

Details of the validation framework these requirements reference live in
`references/safe-to-fail.md`.

## Plan-Level Sections (outside the waves)

Every plan carries these sections, each present even when its answer is "none":

- **Deletion candidates** — dead code (runtime pack only), each with its verification-checklist
  status. "None (no runtime pack supplied)" when there is no pack.
- **Retained-in-DB objects** — not migrated because their only callers are DB-internal; the
  cited reason travels with each.
- **Deferred / needs-investigation** — with **what evidence would resolve each**.
- **Inherited coverage** — x-ray coverage gaps, missing references, and any runtime-pack rows
  that failed to join propagate into the plan as explicit Unknowns, never silently dropped.
- **Candidate bounded contexts** — **flagged only.** Microservice/bounded-context extraction
  is a wave's TB decision, not this plan's (manual-methodology Phase 3 is out of scope).
- **Stated Unknowns / runtime-data availability** — see below (required).

## Output-Contract Rules

These are positive recipes for the plan's shape and self-consistency — state what the output
IS, then check it against itself before finalizing.

### Self-consistency (reconcile, and show the reconciliation)

- **Wave unit counts equal unit-table lengths.** A wave that says "5 units" has a 5-row unit
  table. The count is the table's length, written after the table exists.
- **Every routine lands in exactly one partition class.** The partition domain is the set of
  migratable routines — the rows of the x-ray's `### Extraction Metrics` table (equivalently,
  the procedure/function/trigger rows of the Component Manifest). Supporting objects (tables,
  sequences, types, the package container) are storage/structure, not migration units, and
  are not partitioned. Every routine appears in exactly one of: **{assigned to a wave,
  deletion candidate, retained-in-DB, deferred/needs-investigation}**.
- **Totals reconcile against the manifest, and the reconciliation is shown.** Write the
  addition inline, e.g. `Extraction Metrics lists 6 routines = 3 wave-assigned + 0 deletion
  candidates + 1 retained-in-DB + 2 deferred (= 3 + 0 + 1 + 2 = 6)`. A plan whose partition
  counts do not sum to the routine count is corrected before it is finalized.
- **Dual-path is an attribute, not a partition class.** A wave-assigned unit whose SQL is
  retained carries `SQL retained: yes (reason)` in its row — it stays counted as
  wave-assigned. Dual-path gets its **own** reconciliation line listing every wave-assigned
  unit whose SQL is retained, so the retained set is auditable without disturbing the
  partition totals.

### Business value

Business value is **user-supplied or neutral, and the plan states which** — never invented
from coupling, risk position, or size.

### Stated Unknowns / runtime-data availability (required slot)

Every plan carries a **Stated Unknowns** section that names, explicitly:

- Whether a runtime evidence pack was supplied, and which exports it contained.
- That call-frequency and row-volume evidence was **or was not** available — stated as its
  own fact, mirroring the x-ray report's own "Optional runtime evidence pack" note. Without
  the pack, say so plainly; do not leave the reader to infer it, and do not substitute an
  invented usage characteristic ("rarely called", "hot path") for the missing fact.
- Any complexity dimension scored Unknown, any Pattern C marked viability-Unknown, and any
  runtime-pack row that failed to join.
- **When the inputs are DB-only** (no confirmed app caller for any routine, no runtime pack),
  that the application codebase supplied no callers for any routine, that caller-based
  liveness could not be established, that every presumptive wave-assigned unit's liveness is
  unconfirmed (established from x-ray DB-internal evidence only), and that an app-caller grep
  or runtime pack would resolve it. Never treat DB-only migration as caller-confirmed.

### Terminal STOP

The plan is the handoff. When it is written, stop — no auto-invocation of any downstream skill.

## Maintainer note — why this skill is contract + method, not discipline

This skill deliberately carries **no** anti-fabrication prohibitions, rationalization tables,
red-flag lists, cluster-split prohibitions, or dead-code-triage discipline prose. Its RED
baseline (`tests/sproc-planning/baseline-results.md`) recorded **six independent unaided reps
that all planned the fixture cleanly** — zero fabricated complexity scores, zero invented
business value, zero split shared-state clusters, zero silently-migrated dead code, the
short-name decoy caught every time, every object in exactly one partition class. Per the
Iron Law of skill authoring (no skill text without a failing test) and the "match the form to
the failure" rule, authoring counters for failures that never occurred is not permitted. The
one thing the baseline justified was structural, not disciplinary: the six reps produced six
different plan *formats*, so the output-contract recipes above (the wave-brief shape, the
plan-level sections, the self-consistency reconciliations) are the skill's core value; and
3 of 6 reps did not explicitly state the runtime-data gap, which is why **Stated Unknowns**
is a required slot. A future maintainer adding discipline prose here should first record a
baseline failure that justifies it.

**Finding #7 (DB-only inputs) recorded the failure that justified the DB-only method text.**
The pre-fix skill routed any no-app-caller routine to deferred/needs-investigation. On a
DB-only corpus (no app callers anywhere, no runtime pack) EVERY routine was no-app-caller,
so the presumptive-live leaves all got deferred, Wave 0 emptied, and the plan collapsed to
a near-empty output — the skill's own rules collided and contradicted each other. The RED
baseline (`tests/sproc-planning-dbonly/baseline-results.md`) empirically confirmed the
collapse. The fix scoped the "no-caller → deferral" rule so it only applies when a caller
search could have succeeded (app-present or pack-present), and added the explicit
three-way DB-only classification (confirmed-live, x-ray-confirmed-dead,
presumptive-live-unconfirmed) so DB-only inputs produce a real wave-sequenced plan.

## Reference Files

- **`references/safe-to-fail.md`** — the validation framework each wave brief points to:
  three-mode routing, shadow executor with circuit breaker, dual-write replay for stateful
  functions, the 7-day / 99.9% rule, variable performance thresholds, N+1 elimination,
  rollback drills, cutover and 30-day retention.
- **`references/patterns.md`** — the A–E pattern catalog with x-ray-visible indicators,
  migration notes, pitfalls, and the Pattern C volume gate.
- **`references/runtime-evidence.md`** — how to build the optional runtime evidence pack:
  the value-ordered "what actually helps" table, per-dialect Oracle and SQL Server export
  queries, the sample pack layout, and the case-insensitive object-name join rule.
