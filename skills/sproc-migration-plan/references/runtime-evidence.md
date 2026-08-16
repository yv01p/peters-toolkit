# Runtime Evidence Pack

The optional fourth input. Static source shows what a routine *can* do; it cannot show how
often it runs, how much data it touches, or whether it runs at all. A runtime evidence pack
supplies those facts. It is optional — the planner degrades gracefully without it (see the
skill's input contract) — but supplying it unlocks dead-code triage, the Pattern C volume
gate, and non-conservative shadow-sampling tiers.

## What actually helps, in value order

Export in this order and stop wherever effort runs out — the top rows carry the most planning
value per unit of effort:

| Priority | Export | Feeds | Without it |
|---|---|---|---|
| 1 | Per-object execution counts (90 days) | Dead-code triage; shadow sampling tiers | No deletion candidates; conservative sampling |
| 2 | Row counts of the tables each object touches | Pattern C volume gate; complexity dim 10 (data volume) | Pattern C viability Unknown; data-volume dimension scores Unknown |
| 3 | Performance baselines (avg / p95 / p99 per object) | Gate 2 SQL-only baseline; cutover latency gates | Baselines captured later, during Wave 0 |
| 4 | Call-frequency peaks | Shadow sampling tier refinement | Conservative default tier |

## Every export carries OWNER and OBJECT_NAME — the join rule

**Every file in the pack MUST include an `OWNER` column and an `OBJECT_NAME` column.** The
planner joins pack rows to x-ray report objects **case-insensitively on object name** —
schema-qualified when the report's object name carries a schema, otherwise name-only against
the user-confirmed schema.

Case-insensitivity is not optional politeness: **name forms provably diverge across
artifacts.** A source file `db/ddlutils/oracle/functions/BOM_PriceLimit.sql` may declare
`CREATE OR REPLACE FUNCTION Bompricelimit`, while the catalog export returns the canonical-case
`OBJECT_NAME` `BOMPRICELIMIT`. A case-sensitive join drops the row; a case-insensitive join on
the declared name (never the filename — see the skill's consumer-analysis step) matches it.

**Unjoined rows are never silently dropped.** A pack row that matches no report object, and a
report object that matches no pack row, are both listed in the plan's **Inherited Coverage**
section as explicit Unknowns. A silently discarded execution-count row could hide a live
routine the x-ray missed, or a dead one the plan should delete.

## Per-dialect export queries

Source dialects are Oracle and SQL Server (matching `sproc-xray`). Run the queries for your
dialect; each already selects `OWNER`/`OBJECT_NAME` (or the SQL Server equivalent) so the pack
joins cleanly.

### Oracle

**Inventory (routine list, joins `all_objects` to `all_source`):**

```sql
SELECT o.owner, o.object_name, o.object_type,
       MAX(s.line) AS source_lines
FROM   all_objects o
JOIN   all_source  s
       ON s.owner = o.owner AND s.name = o.object_name AND s.type = o.object_type
WHERE  o.object_type IN ('PROCEDURE','FUNCTION','PACKAGE','PACKAGE BODY','TRIGGER')
  AND  o.owner = :app_schema
GROUP BY o.owner, o.object_name, o.object_type;
```

**Execution stats — current cache (`v$sql`):**

```sql
SELECT parsing_schema_name AS owner, executions, elapsed_time, cpu_time, sql_text
FROM   v$sql
WHERE  parsing_schema_name = :app_schema
ORDER BY executions DESC;
```

**Execution stats — historical (`dba_hist_sqlstat`, 90-day window):**

```sql
SELECT ss.parsing_schema_name AS owner,
       SUM(ss.executions_delta) AS executions_90d
FROM   dba_hist_sqlstat ss
JOIN   dba_hist_snapshot sn ON sn.snap_id = ss.snap_id
WHERE  sn.begin_interval_time > SYSDATE - 90
  AND  ss.parsing_schema_name = :app_schema
GROUP BY ss.parsing_schema_name, ss.sql_id;
```

> **AWR licensing note:** `dba_hist_*` views are part of the Diagnostics Pack and require a
> license. If AWR is not licensed, use `v$sql` (current cache only — shorter horizon) and
> state the reduced observation window in the pack's README. Do not query AWR views on an
> unlicensed instance.

**Row-count volumes (`all_tables.num_rows`):**

```sql
SELECT owner, table_name, num_rows, last_analyzed
FROM   all_tables
WHERE  owner = :app_schema;
```

> `num_rows` is optimizer-statistics data — as fresh as the last `DBMS_STATS` gather. Note
> `last_analyzed` in the export so the planner can judge staleness.

### SQL Server

**Execution stats (`sys.dm_exec_procedure_stats`):**

```sql
SELECT DB_NAME(ps.database_id)                 AS [database],
       OBJECT_SCHEMA_NAME(ps.object_id, ps.database_id) AS [owner],
       OBJECT_NAME(ps.object_id, ps.database_id)        AS [object_name],
       ps.execution_count,
       ps.total_elapsed_time, ps.total_worker_time,
       ps.last_execution_time
FROM   sys.dm_exec_procedure_stats ps
ORDER BY ps.execution_count DESC;
```

> **Cached-plans-only caveat:** `sys.dm_exec_procedure_stats` reports only procedures whose
> plans are **currently cached**. Its counters reset on plan recompile, cache eviction, and
> server restart — so a low or absent `execution_count` can mean "recently evicted," not
> "rarely run." A procedure missing from this DMV is **not** evidence of dead code.
> **Durable alternative:** enable **Query Store**, which persists execution statistics across
> restarts and recompiles, and export from `sys.query_store_runtime_stats` for a trustworthy
> 90-day count. Prefer Query Store when dead-code triage is the goal.

**Row-count volumes (`sys.dm_db_partition_stats`):**

```sql
SELECT  OBJECT_SCHEMA_NAME(p.object_id) AS [owner],
        OBJECT_NAME(p.object_id)        AS [object_name],
        SUM(p.row_count)                AS [row_count]
FROM    sys.dm_db_partition_stats p
WHERE   p.index_id IN (0,1)          -- heap or clustered index
GROUP BY p.object_id;
```

## Sample pack layout

A pack is a directory of named exports. Text or CSV, one row per object, header row naming the
columns (`OWNER`, `OBJECT_NAME`, … ). Expected shape:

```
runtime-pack/
  README.md                 # dialect, instance, observation window, licensing notes, staleness
  execution-counts.csv      # OWNER, OBJECT_NAME, EXECUTIONS_90D, LAST_EXECUTION
  table-row-counts.csv      # OWNER, TABLE_NAME, NUM_ROWS, LAST_ANALYZED
  perf-baselines.csv        # OWNER, OBJECT_NAME, AVG_MS, P95_MS, P99_MS
  call-frequency-peaks.csv  # OWNER, OBJECT_NAME, PEAK_CALLS_PER_MIN, PEAK_WINDOW
```

Only priority-1 (`execution-counts.csv`) is needed to unlock dead-code triage; the rest sharpen
scoring and sampling as available. The README states the dialect, the instance, the observation
window, any licensing constraint on the source view, and statistics staleness — everything the
planner needs to weigh how much each number can bear.
