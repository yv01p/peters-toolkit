# Population-closure micro-test — prompts

Task 1 (spec `888l#96` R-a). Tests the wording of Task 3's `## Population closure`
section (verbatim, from `.superpowers/sdd/2026-08-22-review-round-completion-implementation-plan/task-3-brief.md`,
Step 1 blockquote) against a no-guidance control (the current `**And the family:**`
sentence at `skills/critical-design-review/SKILL.md:53`).

Each arm's block below is the complete, self-contained text sent verbatim to a
fresh-context rep (no file access; scenario fully embedded). Reps see ONLY their
arm's block — never both.

**Round 1 (original scenario below this note) did not discriminate: 5/5 Arm A AND
5/5 Arm B reps produced the target enumeration.** Root cause, found on reading the
transcripts: the shared scenario text used the population-closure clause's OWN
vocabulary ("Rule R applies to each handler's `process()` the same way...", "the
same Rule R, restated per field") and explicitly flagged the two sites as
unchecked — handing the connection to every rep regardless of which arm's clause
they received. Per Step 3's failure rule, the scenario (not the clause text, which
converged cleanly for Arm A) was revised to state the same underlying facts as
neutral spec excerpts, with no editorializing that ties them to Rule R or flags
them as outstanding. **Round 2, below the original, is the scenario actually used
for the pass/fail convergence call.** Round 1 is kept for the record — see
`microtest-results.md` for both rounds' per-rep verdicts.

## Round 1 scenario (superseded — see note above)

```
You are acting as a reviewer using an adversarial design-review methodology.
Before generating findings, the review produces a "§0 coverage enumeration": one
row per checked item, each row given a disposition: `ok — <evidence>` (checked, no
problem), `→ §2.n` (became a finding), `dropped — <reason>` (considered, doesn't
apply), or `UNVERIFIED: <why>` (couldn't be checked this round). "Rule R governs
population X" means: X is a set of items, and R is a check you can run against
each item in X, yielding pass/fail per item.

You are reviewing a design spec for a billing pipeline. Your §0 sweep so far:

**Rule R:** "Every amount-bearing field must be clamped to `MAX_AMOUNT` before it
is persisted to the ledger."

**Population P1 — the 6 record types listed in spec §2.3 ("Record Types"):**
`Invoice`, `Refund`, `Adjustment`, `CreditMemo`, `Chargeback`, `Payout`. You
already checked Rule R against each record type's write path. Two are confirmed
failing:
- `Refund.amount` is written directly to the ledger; no call to `clamp_to_max()`
  exists anywhere in its write path. **FAIL.**
- `Adjustment.amount` — same defect, same missing call. **FAIL.**
- `Invoice`, `CreditMemo`, `Chargeback`, `Payout` all call `clamp_to_max()` before
  the ledger write. **OK** (verified by reading each write function).

This P1 sweep is done — 6/6 dispositioned, 2 findings raised (`Refund`,
`Adjustment` → §2).

Two more places in the same spec are visibly governed by the same Rule R. Your
sweep has not touched them yet:

**A roster the rule iterates over.** Spec §4.1 defines a `HANDLER_ROSTER`: a list
of 11 named payment-provider handlers (`stripe_handler`, `ach_handler`,
`wire_handler`, `paypal_handler`, `venmo_handler`, `zelle_handler`,
`check_handler`, `wallet_handler`, `giftcard_handler`, `crypto_handler`,
`manual_handler`). The pipeline's generic amount-processing loop is
`for handler in HANDLER_ROSTER: handler.process(amount)`. Rule R applies to each
handler's `process()` the same way it applies to each record type's write path —
does `process()` clamp before it persists? You have not checked any of the 11
handlers.

**A validator's constraint set.** Spec §5.2 describes `LedgerValidator`, which
gates a spec-permitted "manual override" branch (a code path support staff use to
post manual ledger entries). `LedgerValidator` enforces 9 named constraints on the
manual-entry form, one per amount-bearing field on that form (`c_refund_amt`,
`c_fee_amt`, `c_tax_amt`, `c_surcharge_amt`, `c_adjustment_amt`, `c_writeoff_amt`,
`c_credit_amt`, `c_chargeback_amt`, `c_payout_amt`) — each constraint's stated
rule is "this field's value must be clamped to MAX_AMOUNT before the validator
signs off," i.e., the same Rule R, restated per field. You have not checked
whether the manual-override branch's write path actually satisfies any of these 9
constraints before persisting.
```

## Round 2 scenario (revised — this is the scenario used for the convergence call)

Same underlying facts as Round 1 (same rule, same P1 findings, same
`HANDLER_ROSTER`, same `LedgerValidator` constraints), restated as neutral spec
excerpts with no "Rule R governs this" / "you haven't checked this" framing —
that recognition is now left entirely to whichever clause the rep receives.

```
You are acting as a reviewer using an adversarial design-review methodology.
Before generating findings, the review produces a "§0 coverage enumeration": one
row per checked item, each row given a disposition: `ok — <evidence>` (checked, no
problem), `→ §2.n` (became a finding), `dropped — <reason>` (considered, doesn't
apply), or `UNVERIFIED: <why>` (couldn't be checked this round).

You are reviewing a design spec for a billing pipeline against one particular
rule.

**Rule R:** "Every amount-bearing field must be clamped to `MAX_AMOUNT` before it
is persisted to the ledger."

Three excerpts from the spec:

**Spec §2.3 — Record Types.**
> The pipeline persists six record types to the ledger: `Invoice`, `Refund`,
> `Adjustment`, `CreditMemo`, `Chargeback`, `Payout`. Each type's write function is
> responsible for calling `clamp_to_max()` on its `amount` field before the ledger
> write, per Rule R.

**Spec §4.1 — Handler dispatch.**
> Payment intake is dispatched through a fixed roster of provider handlers:
> ```
> HANDLER_ROSTER = [stripe_handler, ach_handler, wire_handler, paypal_handler,
>                    venmo_handler, zelle_handler, check_handler, wallet_handler,
>                    giftcard_handler, crypto_handler, manual_handler]
> ```
> The intake loop is `for handler in HANDLER_ROSTER: handler.process(amount)`.
> Each handler owns its own persistence call.

**Spec §5.2 — Manual override.**
> Support staff may post manual ledger entries through a form gated by
> `LedgerValidator`, which enforces the following named constraints before
> sign-off: `c_refund_amt`, `c_fee_amt`, `c_tax_amt`, `c_surcharge_amt`,
> `c_adjustment_amt`, `c_writeoff_amt`, `c_credit_amt`, `c_chargeback_amt`,
> `c_payout_amt`. Each constraint's rule text reads: "this field's value must be
> clamped to MAX_AMOUNT before the validator signs off."

**Your §0 sweep so far (Rule R against §2.3's six record types):**
- `Refund.amount`: no call to `clamp_to_max()` anywhere in its write path.
  **FAIL.**
- `Adjustment.amount`: same defect. **FAIL.**
- `Invoice`, `CreditMemo`, `Chargeback`, `Payout`: each calls `clamp_to_max()`
  before the ledger write. **OK** (verified by reading each write function).

6/6 dispositioned, 2 findings raised (`Refund`, `Adjustment` → §2). §4.1 and §5.2
have not been part of any §0 row yet.
```

## Question (identical wording, both arms, both rounds)

> List the §0 rows you must still produce before this round can close.

## Arm A — clause (Task 3 `## Population closure`, verbatim)

Full text sent to Arm A reps (Round 2; Round 1 used the Round 1 scenario above):

```
This is a self-contained reasoning exercise. Do not use any tools — do not read,
write, or search for files, do not run commands, do not look anything up.
Everything you need is given below. Reason through it and give your final answer
as the text of your final report; that final message is your only graded output.

<Round 2 scenario, embedded verbatim as above>

Your project's review discipline includes the following binding rule. Apply it
exactly as written:

> ## Population closure
>
> When any §0 row confirms a **rule-vs-population mismatch** — a rule that fails
> against a member of a population it governs — the round cannot close until the
> full (rule × every population it governs) matrix is enumerated: as individual
> §0 rows, or as one row naming the matrix with a disposition per cell
> (`ok — <evidence>` / `→ §2.n` / `dropped — <reason>` / `UNVERIFIED: <why>`).
> "Population" is read expansively:
>
> - The **roster a rule iterates over is itself a governed population** — the
>   outer matrix (rule × roster) needs cells dispositioned, not only the inner
>   matrix the first finding came from.
> - The **constraint set of a validator gating a spec-permitted branch** is a
>   population that branch is checked against.
> - **Both failure directions apply per cell**, not per rule — a cell checked for
>   over-inclusion only is half-dispositioned (per-direction grammar above).
>
> "Two instances found" triggers full enumeration, never a stop. A population too
> large to close in-round is not silently sampled: the residual cells get one
> `UNVERIFIED: <the uncovered remainder>` row, which flows to §3 as a forced
> decision (verify empirically / accept the risk / defer) — exactly like an
> unverifiable negative claim.

List the §0 rows you must still produce before this round can close.
```

## Arm B — control (current CDR:53 "And the family" sentence, verbatim, no other guidance)

Full text sent to Arm B reps (Round 2; Round 1 used the Round 1 scenario above):

```
This is a self-contained reasoning exercise. Do not use any tools — do not read,
write, or search for files, do not run commands, do not look anything up.
Everything you need is given below. Reason through it and give your final answer
as the text of your final report; that final message is your only graded output.

<Round 2 scenario, embedded verbatim as above>

Your project's review discipline includes the following binding rule. Apply it
exactly as written:

> **And the family:** a confirmed finding additionally obligates a recurrence
> sweep — enumerate the structurally similar siblings of the defective instance
> and check each for the same failure shape, bounded to the enclosing surface: the
> remaining checks in the same validator/file span, the sibling tests in the same
> module, the other outbound seams of the same test, the other fields under the
> same constraint kind, the sentences that follow in the same spec/plan paragraph.
> The family lives in the codebase as much as in the artifact. Record it as one §0
> row per family member, or one row naming the family with a per-member
> disposition.

List the §0 rows you must still produce before this round can close.
```

## Round 3 — tool-mediated (controller-directed, on-disk fixtures)

Controller ruling: Round 2's diagnosis (no grep restriction is possible inside a
no-tool, fully-embedded prompt) was accepted, and Round 3 removes that ceiling.
Same underlying facts as Round 2 — not re-tuned — relocated to real files:
- `round3-fixture/popclosure/spec.md` (Rule R, §2.3/§4.1/§5.2 excerpts, the §0
  sweep-so-far)
- `round3-fixture/popclosure/handler_roster.py` (real source: `HANDLER_ROSTER`
  + the intake loop)
- `round3-fixture/popclosure/ledger_validator.py` (real source: `LedgerValidator`
  with the 9 named constraints)

Reps get file paths instead of embedded text, and are explicitly told they may
use Read/Grep/Bash (read-only) as they see fit. Question and both arms' clause
texts are byte-identical to Round 2.

Full text sent to Arm A reps (Round 3):

```
You are acting as a reviewer using an adversarial design-review methodology.
Before generating findings, the review produces a "§0 coverage enumeration": one
row per checked item, each row given a disposition: `ok — <evidence>` (checked, no
problem), `→ §2.n` (became a finding), `dropped — <reason>` (considered, doesn't
apply), or `UNVERIFIED: <why>` (couldn't be checked this round).

You are reviewing a design spec for a billing pipeline against one particular
rule. The spec and its referenced source files are on disk at:
- <repo>/tests/round-completion/microtest/round3-fixture/popclosure/spec.md
- <repo>/tests/round-completion/microtest/round3-fixture/popclosure/handler_roster.py
- <repo>/tests/round-completion/microtest/round3-fixture/popclosure/ledger_validator.py

You may use Read and Grep on these files as needed to investigate. This is a
read-only investigation — do not edit any files anywhere. Start by reading
spec.md, then investigate further as your review discipline (below) directs.

Your project's review discipline includes the following binding rule. Apply it
exactly as written:

> ## Population closure
> [same clause text as Round 1/2, above — verbatim, unchanged]

This is a single-shot exercise: investigate the fixture files as you see fit,
then give one final answer.

Before your final answer, list every tool call you made (tool name + target
file/query), in the order you made them.

Then answer: List the §0 rows you must still produce before this round can close.
```

Full text sent to Arm B reps (Round 3) is identical except the clause block is
replaced with the verbatim "And the family" control text (same as Round 1/2,
above), unchanged.

## Target behavior (scoring rubric)

- **Arm A (target: HIT):** enumerates the full rule × {P1, P2, P3} matrix — P1
  already closed (6/6), PLUS explicit §0 rows (or one matrix row with per-cell
  dispositions) covering the 11-member `HANDLER_ROSTER` and the 9-member
  `LedgerValidator` constraint set, since Rule R visibly governs both. An
  `UNVERIFIED: <remainder>` residue row for a too-large population also counts as
  a HIT (the clause explicitly allows this) — a bare "sample a few and move on,"
  or omitting P2 or P3 entirely, does not.
- **Arm B (target: MISS):** stops at the 6 P1 rows already done, or at most extends
  to items reachable by "bounded to the enclosing surface" (i.e., stays within
  §2.3's record types / their immediate file span) — without recognizing
  `HANDLER_ROSTER` (§4.1) or `LedgerValidator`'s constraint set (§5.2) as
  populations the SAME rule governs, since the control text has no "population" or
  "roster" framing at all.
