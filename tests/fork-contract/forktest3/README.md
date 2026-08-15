# caseaudit

LLM-assisted audit pass for case files. A reviewer model reads a review packet
and emits edits through a strict tool call; edits are applied to the stored
case collections.

Layout:

- `src/runner.py` — per-case entry point (called by the batch driver)
- `src/reviewer.py` — LLM call loop for the `submit_edits` tool
- `src/toolgate.py` — strict tool-schema gate (whitelist walker); every LLM
  tool surface in this repo is built through it
- `src/schemas.py` — tool input models (`EditBatch`, `ReviewEdit`)
- `src/entries.py` — the three stored collection entry models
- `src/applyedits.py` — applies a validated `EditBatch` to a case
- `src/llmclient.py` — thin API client wrapper
- `src/casestore.py` — case load/save
- `src/config.py` — env-driven settings
