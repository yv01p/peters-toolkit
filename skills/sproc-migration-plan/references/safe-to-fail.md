# Safe-to-Fail Migration Framework

The validation framework each wave brief stamps onto its units. It is language-agnostic;
the worked example throughout is the ADempiere PL/SQL-and-Java migration, where SQL functions
moved into Java services one wave at a time under exactly these gates. Read "Java" as "the
target application language" everywhere.

The framework's whole premise: **a migrated routine must be able to fail without taking
production with it.** Every mechanism below exists to make the failure of a converted unit
observable, reversible, and cheap.

## Three-mode routing

Every migrated routine sits behind a runtime switch with three positions. The switch is a
per-routine configuration value, flippable without redeploy:

| Mode | Behavior | When |
|---|---|---|
| **SQL_ONLY** | Calls the original database routine only. The application code exists but is dormant. | Gates 1–2, and the instant rollback target forever after |
| **SHADOW** | Calls the database routine for the real result AND the application code in parallel; returns the SQL result, compares the two, logs divergence. | Gate 3 |
| **APP_ONLY** (ADempiere: `JAVA_ONLY`) | Calls the application code only; the SQL routine is retained but no longer invoked on this path. | Gates 4–5 |

The routing key is the routine's declared name — the same name the planner joined on. A
routine is never in more than one mode at a time, and flipping SHADOW → APP_ONLY → back to
SQL_ONLY is a config change, not a deploy.

## Shadow executor with circuit breaker

In SHADOW mode the shadow (application) path runs alongside the authoritative (SQL) path.
Two hard rules:

1. **The SQL result is always the returned result in SHADOW mode.** The shadow path's output
   is compared and logged, never returned to the caller. A shadow bug cannot corrupt a
   response.
2. **A circuit breaker wraps the shadow call.** If the shadow path throws, times out, or
   trips the breaker's error-rate threshold, the breaker opens: the shadow path is skipped
   entirely (the SQL path still returns normally) and an alert fires. A broken shadow
   implementation degrades to plain SQL_ONLY behavior automatically — it never adds latency
   or failure to the live path.

The shadow call is dispatched so its latency does not serialize in front of the SQL result
where the platform allows it (e.g., fire the comparison from the returned SQL result rather
than blocking on both).

## Async divergence logging

Comparisons in SHADOW mode are written to a divergence log **asynchronously** — off the
request path. Each divergence record carries: routine name, mode, input key, SQL result,
app result, comparison verdict, and timestamp. The log is the raw material for the 99.9%
match measurement below and for debugging every mismatch. Because it is async, logging a
divergence never slows the caller and never fails the request.

## Dual-write async replay for stateful functions

Read-only functions are safe to shadow directly. **Stateful** routines — those that write
rows, advance sequences, or mutate shared state (the x-ray's Dimension 5 `GLOBAL_STATE`
findings mark these) — cannot naively run both paths: two live paths would double-write.

For a stateful routine, SHADOW mode uses **dual-write async replay**:

- The SQL path performs the real writes and returns.
- The application path is replayed **against a shadow/scratch context** — a separate schema,
  a rolled-back transaction, or an in-memory fixture — so its writes are captured and
  compared but never committed to production.
- **Sequences are the classic trap:** a naive dual run calls `seq.NEXTVAL` twice and
  double-consumes the sequence, so every downstream id is off by one. The replay path must
  read the sequence value the SQL path already consumed rather than drawing its own. Any
  routine the x-ray flags as a sequence consumer (`.NEXTVAL` / `NEXT VALUE FOR`) gets this
  treatment explicitly — the comparator checks that both paths would have produced the *same*
  id, without the app path advancing the real sequence.

## The 7-day / 99.9% rule

A routine does not advance from Gate 3 (Shadow) to Gate 4 (Cutover) until:

- Its shadow-vs-SQL match rate is **≥ 99.9%** on the divergence log, AND
- That rate has held for **7 consecutive days** of real production traffic.

Seven days is not arbitrary: it captures the weekly cycle — weekday peaks, weekend batch,
month-boundary jobs that only a full week surfaces. A routine that matches 100% for three
days and then diverges on the Saturday settlement run has not passed; the clock restarts on
any qualifying regression.

## Variable performance thresholds

Cutover latency gates are governed by **absolute per-call overhead, not ratio alone.** A
naive "app path must be within 2× of SQL" rule punishes fast routines and waves through slow
ones:

- **Sub-millisecond overhead → relaxed ratios.** A routine that runs in 40µs in SQL and 90µs
  in the app is "2.25× slower" but 50µs of added absolute cost is invisible at any realistic
  call rate. Pass it.
- **≥ 1ms overhead → tight ratios.** A routine adding a full millisecond or more per call is
  measured strictly, because at scale that absolute cost dominates.

Encode the governing threshold in the wave brief so later waves do not relearn it: state the
absolute overhead budget, and the ratio only as a secondary check inside it.

## N+1 elimination for recursive / hierarchical SQL

Recursive SQL (tree walks, BOM explosions, org-chart traversals — ADempiere's BOM functions
are the worked example) becomes an **N+1 query storm** if translated one-row-at-a-time into
application code: one query per node, thousands of round-trips.

The framework's pattern is two-part:

1. **Batch CTE tree loading** — pull the entire subtree in **one** query using a recursive
   CTE (`WITH RECURSIVE`), returning all nodes and edges at once.
2. **Iterative in-app traversal** — walk the loaded tree **in memory** in the application,
   with no further database round-trips.

A recursive routine migrated without this pattern will pass correctness shadowing and then
fail the performance gate; the wave brief for any recursive unit names the batch-load query
as a required part of its conversion.

## Rollback drills as tests

Rollback is not a runbook paragraph — it is an **executed test** before Gate 4. For each
routine (or cluster) about to cut over:

- A rollback drill flips the routing switch APP_ONLY → SQL_ONLY under load and asserts the
  system returns to the SQL baseline cleanly, with no orphaned state.
- The drill is run and its result recorded as cutover evidence. A cutover whose rollback
  drill has not actually been executed does not proceed.

Because rollback is a config flip (three-mode routing), the drill is fast and repeatable —
which is the point: the team has *done* the rollback before it ever needs it in anger.

## Cutover and post-cutover

- **Gate 4 — Cutover:** flip the routine to APP_ONLY after stakeholder sign-off and a passed
  rollback drill. The SQL routine is now dormant on this path but **retained**.
- **Gate 5 — Post-cutover monitoring:** watch the routine in APP_ONLY for **7 days**. SQL_ONLY
  remains one config flip away the entire time.
- **30-day source retention before deletion.** The original SQL routine is **not deleted at
  cutover.** It is retained for **≥ 30 days** after successful post-cutover monitoring, so a
  latent divergence discovered weeks later still has an instant, tested fallback. Deletion is
  a deliberate, separate step after the retention window — and never applies at all to a
  **dual-path** routine whose SQL a DB-internal caller still needs.
