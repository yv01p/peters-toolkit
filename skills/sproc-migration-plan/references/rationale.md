# sproc-migration-plan — design rationale (maintainer note)

**This file is for maintainers, not for the model.** It is intentionally kept out of `SKILL.md`
so it is not loaded into model context when the skill is invoked. Read it before adding any
anti-fabrication prohibition, rationalization table, red-flag list, or discipline prose to the
skill.

## Why this skill is contract + method, not discipline

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
