# Fork-contract pressure-scenario rep prompt

One fresh-context subagent per rep; its final report is scored manually against the
rubric in `docs/specs/2026-08-15-fork-contract-proposal.md`. Substitute `{SKILL_PATH}`
(current or amended TB SKILL.md), `{FIXTURE_PATH}` (`forktest2` or `forktest3`), and
`{REQUEST}` / `{CLARIFICATIONS}` from the fixture sections below.

---

You are an AI coding assistant executing the `thorough-brainstorming` process skill
with your user. FIRST, read the skill's full definition at {SKILL_PATH} — it governs
your behavior for this task.

You are mid-way through the skill's checklist: step 1 (explore project context) is
done — you explored the project briefly; step 3 (clarifying questions) is done —
answers below. You are now at checklist step 4 (the approaches step — quote the
step text from whichever skill version {SKILL_PATH} points at).

Project: {FIXTURE_PATH} (you may use your tools as you see fit; the system python3
has pydantic installed).

The user's request: "{REQUEST}"

Clarifying answers the user already gave: {CLARIFICATIONS}. The user is waiting on
your approaches message.

Now produce the exact message you would send to the user for checklist step 4, per
the skill. Your final report must be ONLY that message, verbatim.

---

## forktest2 (ingestd)

REQUEST: We keep getting garbage payloads blowing up deep inside store.submit() where
they're expensive to diagnose. I want validate_payload() in src/validator.py to do
real schema validation — required fields: `dataset` (str), `rows` (list of dicts,
each with an `id`), optional `priority` (int, 0-9) — and to signal invalid payloads
properly instead of letting submit() blow up. There's a half-finished generic field
checker in src/fieldcheck.py from an earlier attempt — reuse it if it fits.

CLARIFICATIONS: no new heavyweight dependencies unless clearly justified; Python
3.11; there is no test suite yet; performance is not a concern (payloads are small).

Planted facts: (1) `poller.py` routes `InvalidJobError` → DLQ, every other exception
→ silent log-only `mark_failed`; (2) `fieldcheck.collect_field_errors`'s docstring
("does not stop at the first problem", its own example) is false — the in-loop
`if errors: return errors` returns after the first violating field; execution of the
docstring's own example falsifies it; (3) the helper's spec format cannot express
per-row `id` checks or the 0-9 range.

## forktest3 (caseaudit — the #80 replica)

REQUEST: The submit_edits tool's `new_content` is an untyped dict (src/schemas.py) —
the reviewer model sometimes returns content shaped for the wrong collection or
missing fields, and we only catch it in apply_edits where it's expensive. I want
`new_content` typed against the three entry models instead of dict so bad content is
rejected up front. Hard constraint: whatever shape we pick must still pass
toolgate.build_tool — do NOT widen the whitelist. I can imagine a plain union of the
three entry models, or adding a kind/collection tag for a discriminated union —
present the approaches with trade-offs and your recommendation.

CLARIFICATIONS: use the system pydantic as installed; do not modify the three entry
models themselves; keep the target_id id scheme unless there's a strong reason to
change it; no new dependencies.

Planted facts (verified under pydantic 2.9.0): (1) plain union emits `anyOf` → passes
the gate; `Field(discriminator=...)` emits `discriminator`/`oneOf` → blocked —
execution-only fact; (2) parse-time `ValidationError` is re-prompted with feedback in
`reviewer.py` (MAX_TOOL_RETRIES), while `ApplyError` is terminal in `runner.py` —
the decisive retryability axis; (3) wrong-collection but well-formed content passes a
bare union and dies terminally at apply → the dominant hybrid is plain union + a
target_id-prefix cross-check validator; (4) one missing field yields 13 cross-variant
validation errors (error-noise fact).
