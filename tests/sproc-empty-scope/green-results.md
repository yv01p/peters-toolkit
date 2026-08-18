# GREEN evidence — post-fix sproc-xray on the empty-scope case (finding B)

**Arm:** GREEN (post-fix). x-ray cells run against `skills/sproc-xray/SKILL.md` **after** the Edit A empty-scope short-circuit (commit `d8b3f0a`; body under test carries the gate + Empty-Scope Compact Report — the frontmatter version bump is Task 4, cosmetic, not under test here).
**Scope (re-scoped, Edit-A-only):** only the two **x-ray** cells are GREEN-tested. The `planning-empty` / `planning-binary` migration-plan GREEN cells are **dropped** along with Edit B — Task 1's RED baseline proved those failures do not reproduce (see `baseline-results.md`), so there is no RED→GREEN to demonstrate for the planner. `sproc-migration-plan` is unchanged.
**Reps:** fresh-context, blind agents on a capable model (sonnet), each isolated to its own README-excluded rep-facing fixture copy under a neutral sandbox, reading a neutrally-staged copy of the post-fix skill. Counts: **`empty` N=2** (N-for-N with the RED `empty` cell) + **`viewlogic` N=2** (over-fire guard; no RED counterpart — a no-regression confirmation). Same documented deviation from the rubric's "5+ per arm" as the baseline.
**Scored against:** `rep-prompt-template.md` Part 2a, ground truth in `empty1/README.md` / `viewlogic1/README.md` (never sent to a rep).

## Per-cell scoring

### `empty` cell — x-ray on `empty1` (RED→GREEN; the load-bearing proof)

| Rep | 1. Report shape | Validator markers kept | Balloon sections (Dim 2 / Dim 4 / CRUD rows) | Terminal STOP + charter note | App-layer analysis |
|-----|---|---|---|---|---|
| green-empty-1 | **`COMPACT`** (136 lines) | 4/4 (`## Coverage Declaration`, `### Extraction Metrics`, `## 3.`, `## 5.`) | **0** — none present | `PRESENT` | `ABSENT` |
| green-empty-2 | **`COMPACT`** (95 lines) | 4/4 | **0** — none present | `PRESENT` | `ABSENT` |

**RED→GREEN transition:** baseline `empty` was `BALLOONED` 2/2 (~244–251 lines, full five-dimension template); post-fix is `COMPACT` 2/2 (95–136 lines, no Dimension 2/4, no CRUD-matrix rows, no injection enumeration). The compact report keeps all four downstream-validator markers, so `sproc-migration-plan` still accepts it at intake (verified: 4/4 markers both reps). This is the fix delivering the user's framing — empty-scope reads as **"analyzed successfully, found 0 DB-resident routines,"** short and honest, not a 250-line report and not the wrong-dialect decline.

### `viewlogic` cell — x-ray on `viewlogic1` (over-fire guard; no-regression confirmation, NOT a fixed failure)

| Rep | 1. Short-circuit correctly withheld | 2. View logic captured (both `CASE` arms) | 3. `CONSTRAINT_LOGIC` captured (3 CHECK + 2 logic-bearing DEFAULT) | 4. No app-layer balloon |
|-----|---|---|---|---|
| green-viewlogic-1 | **`CORRECT_NO_SHORTCIRCUIT`** (346-line full five-dimension report; Dim 2 + Dim 4 present) — the report's own "Scope note" cites the over-fire guard by name and explains why the compact path was not taken | `COMPLETE` (`DiscountedTotal` + `AgingBucket`) | `COMPLETE` (`CK_Customers_Tier`, `CK_Orders_Subtotal`, `CK_Orders_Status`, `DEFAULT SUSER_SNAME()`, `DEFAULT SYSUTCDATETIME()`) | `ABSENT` (no `app/` tree in this corpus) |
| green-viewlogic-2 | **`CORRECT_NO_SHORTCIRCUIT`** (301-line full report; Dim 2 + Dim 4 present) | `COMPLETE` | `COMPLETE` | `ABSENT` |

State plainly: this cell has **no RED counterpart** — the pre-fix skill had no short-circuit to over-fire. It is a no-regression guard proving Edit A's gate does NOT collapse a corpus that has 0 routines but real DB-resident logic (a logic-bearing view + CONSTRAINT_LOGIC) into the compact skeleton.

## Aggregate

- **`empty` (RED→GREEN):** `COMPACT` **2/2**, validator markers kept **2/2**, balloon sections **0/2**. The BALLOONED-2/2 RED is fixed; the compact report is emitted unaided by blind agents reading the post-fix skill, and remains a valid `sproc-migration-plan` input.
- **`viewlogic` (over-fire guard):** `CORRECT_NO_SHORTCIRCUIT` **2/2**, view logic `COMPLETE` **2/2**, `CONSTRAINT_LOGIC` `COMPLETE` **2/2**. The gate's over-fire guard holds; no regression on the one negative case the operand set was hardened for (CDR r2/r3).

## Verdict

Edit A is proven GREEN on both x-ray cells: the empty-scope balloon (the one genuine RED from Task 1) is fixed, and the over-fire guard correctly withholds the short-circuit when logic-bearing views or `CONSTRAINT_LOGIC` are present. No migration-plan change was made or needed (Edit B dropped per the Task-1 RED gate + user direction).
