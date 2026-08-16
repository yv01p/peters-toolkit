# Migration Pattern Catalog (A–E)

One primary migration pattern is assigned to each unit during planning Step 6. The patterns
are language-agnostic; the worked example is the ADempiere PL/SQL → Java migration. A unit may
show traits of several patterns — assign the **primary** one (the dominant shape of its logic)
and note secondaries in the wave brief.

Each pattern below lists the **x-ray-visible indicators** that select it — the report facts a
planner reads to assign it — plus migration notes and the pitfall that most often bites.

---

## Pattern A — CRUD routine → repository

**From:** a routine whose body is straightforward create/read/update/delete against tables,
with little branching. **To:** a repository/DAO method in application code.

**X-ray-visible indicators:**
- CRUD Matrix rows dominated by single-verb access (one INSERT, one SELECT, one UPDATE).
- Extraction Metrics: low `Branches`, `Cursor Loops` = 0.
- Few distinct resources in the Resource Touch Tally.

**Migration notes:** the flattest pattern — maps almost directly onto a repository method.
Good Wave 0 material. Preserve the exact column set and null-handling of the original DML.

**Pitfall:** DDL-layer defaults (`DEFAULT SYSDATE`, `DEFAULT 'ACTIVE'`) the routine relies on
are invisible in the routine body — check Dimension 5 `CONSTRAINT_LOGIC`. The repository must
supply what the DB `DEFAULT` used to.

---

## Pattern B — cursor / nested-loop → stream / iteration

**From:** a routine driven by one or more cursor `FOR` loops (often nested). **To:** a stream
or iterator pipeline in application code.

**X-ray-visible indicators:**
- Extraction Metrics: `Cursor Loops` ≥ 1 (2+ = nested, higher complexity).
- Dimension 2 / Dimension 4 notes on per-row processing inside the loop.

**Migration notes:** translate the outer cursor to a streamed query result and the loop body
to a per-element operation. Nested cursors (depth 2+) become a join or a nested stream —
decide which from the CRUD matrix, not by transcribing the nesting literally.

**Pitfall:** a per-row `SELECT ... INTO` inside the loop is an N+1 waiting to happen. Fold the
inner lookup into the outer query where possible (see `safe-to-fail.md`, N+1 elimination).
Watch for a `NO_DATA_FOUND`/exception swallow wrapping the loop (Dimension 4) — the streamed
version must reproduce the *intended* behavior, not the accidental swallow.

---

## Pattern C — temp table → in-memory collection (VOLUME-GATED)

**From:** a routine that stages rows in a temporary table (Oracle GTT, T-SQL `#temp`) and
later reads them back. **To:** an in-memory collection held across the staging and consuming
steps in application code.

**X-ray-visible indicators:**
- Dimension 5 `GLOBAL_STATE` rows for a temporary table with a writer routine and a reader
  routine (the temp table is the handoff channel).
- The writer and reader form a shared-state cluster (planning Step 5) — they migrate together.

**This pattern is volume-gated.** Holding a staged set in memory is only safe if the set
fits. The gate is a runtime row count:

| Staged rows (from runtime pack) | Verdict |
|---|---|
| ≤ ~10⁴ per invocation | In-memory collection is safe — apply Pattern C |
| ~10⁴ – 10⁶ | Borderline — bounded/streaming collection, or keep a staging table in the target |
| > ~10⁶ | Do **not** hold in memory — retain a staging table (target-side temp/working table) and stream |

**Unknown-without-row-counts rule:** if no runtime pack supplies the staged row count, assign
the unit Pattern C but mark it **"Pattern C viability Unknown"** and record the gap in the
plan's Stated Unknowns. **Never assume the set fits.** The row-count export
(`references/runtime-evidence.md`, priority 2) is what closes this gate; until it exists, the
viability stays Unknown rather than presumed.

**Pitfall:** `ON COMMIT PRESERVE ROWS` GTTs survive across transactions within a session — the
in-memory collection must have the same lifetime as the original temp table's session scope,
or staged data vanishes early.

---

## Pattern D — procedural logic → domain code

**From:** a routine that is mostly business logic — branching, calculations, policy applied to
values — rather than data movement. **To:** a domain method / service in application code, with
the logic expressed as ordinary code and the constants externalized.

**X-ray-visible indicators:**
- Extraction Metrics: high `Branches` relative to CRUD footprint.
- Dimension 5 `HARDCODED_VALUE` rows — pricing multipliers, thresholds, tier adjustments
  embedded as procedural literals.

**Migration notes:** this is where the most *value* is recovered — logic buried in the database
becomes testable, versioned domain code. Externalize every hardcoded business constant
(Dimension 5) to configuration or a rules table as part of the conversion.

**Pitfall:** dialect arithmetic and NULL semantics (Dimension 5 `NULL_SEMANTICS`,
`SYSDATE`-per-call behavior) silently change results if transcribed literally. Reproduce the
*result*, verified by the shadow comparator's decimal tolerance, not the exact expression.

---

## Pattern E — dynamic SQL → query builder

**From:** a routine that assembles and executes SQL at runtime (`EXECUTE IMMEDIATE`,
`sp_executesql`, `EXEC(@sql)`). **To:** a typed query builder / criteria API in application
code.

**X-ray-visible indicators:**
- Dimension 2 reduced-confidence edges flagged `[MEDIUM-CONF]`/`[LOW-CONF]` for dynamic SQL.
- Explicit "this object uses dynamic SQL — graph may be incomplete" notes.

**Migration notes:** the query builder makes the previously-dynamic query surface explicit and
type-checked. Enumerate the actual shapes the dynamic SQL takes (from the source's branch
structure) before building.

**Pitfall:** dynamic SQL is the x-ray's blind spot — its dependency graph is **known to be
incomplete** for these routines. Treat the edge set as a floor, not a complete picture, and
re-scan the routine's inputs for tables/objects the static graph missed before scheduling it.
Dynamic SQL is also the SQL-injection surface; the query-builder rewrite is the moment to
parameterize what was string-concatenated.
