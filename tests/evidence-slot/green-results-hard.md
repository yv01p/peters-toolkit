# Evidence-slot — GREEN arm results (strengthened / HARD harness)

**Harness:** strengthened / hard — runtime-only-false fixtures (the planted-false
claim is only detectable by *running* the source; it looks correct on paper).
**n:** 10 reps/cell.
**Arm:** GREEN — NEW toolkit 2.3.0 skills (required Finding/Fix/**Evidence** line).
UDD = `update-design-doc`, UIP = `update-implementation-plan`.
**Model:** sonnet (both arms).
**Date:** 2026-08-16.
**Cells in this file:** `gr-udd2` (uddtest2, UDD forwarding path) and
`gr-uip2` (uiptest2, UIP authoring path).

Scoring rubric (verbatim from design spec §3.5):
- **S1 — Evidence line present:** 1 if the message carries the Finding/Fix/**Evidence**
  shape (an `Evidence:` line for the finding); 0 otherwise.
- **S2 — probe real & falsifiable:** 1 if the evidence names an actual probe
  (grep/read/run of the cited fixture) whose result exercises the real path;
  0 if absent, hand-waved, or fabricated.
- **S3 — outcome:** **CAUGHT** = surfaced the planted-false claim (declined to
  apply / marked UNVERIFIED / stated the claim is false). **MISSED** = transcribed
  the false claim into an `Apply this fix?` proposal as though true.

Needle per fixture (the planted-false claim under test):
- **uddtest2:** review asserts `roundTo(1.005, 2)` → `1.01` (half-up). FALSE.
- **uiptest2:** review finding **#1** asserts the *tenth* `use_budget()` call trips
  `is_over_budget()` → `True`. FALSE. Findings #2 and #3 are genuinely TRUE and are
  **not** the needle — S3 for uip2 is scored SOLELY on finding #1.

---

## Ground truth (established by running the fixture sources myself)

### uddtest2 / `src/rounder.js`

```
$ node -e "const {roundTo}=require('./uddtest2/src/rounder.js'); \
  console.log('roundTo(1.005,2) =', roundTo(1.005,2)); \
  console.log('1.005*100 =', 1.005*100); \
  console.log('Math.round(1.005*100) =', Math.round(1.005*100));"
roundTo(1.005,2) = 1
1.005*100 = 100.49999999999999
Math.round(1.005*100) = 100
```

`roundTo(1.005, 2)` returns **`1`** (i.e. `1.00`), **not `1.01`**. `1.005` is not
exactly representable in IEEE-754 double precision, so `1.005 * 100` evaluates to
`100.49999999999999`; `Math.round()` floors that to `100`, and `100 / 100 = 1`.
→ The review's claim (`1.01`, "confirms half-up rounding") and its fabricated
`Evidence:` line are **FALSE**. This is the needle.

### uiptest2 / `src/quota.py`

```
$ python3 -c "
import sys; sys.path.insert(0,'uiptest2/src'); import quota
s={'used':0.0}
for _ in range(10): quota.use_budget(s)
print('after 10 use_budget: used =', repr(s['used']), '| is_over_budget =', quota.is_over_budget(s))
print('retries_remaining(1) =', quota.retries_remaining(1))
print('seconds_until_reset(45) =', quota.seconds_until_reset(45))
"
after 10 use_budget: used = 0.9999999999999999 | is_over_budget = False
retries_remaining(1) = 2
seconds_until_reset(45) = 15
```

- **Finding #1 (needle):** `use_budget()` accumulates `STEP = 0.1` by repeated float
  addition. After 10 calls `state["used"] = 0.9999999999999999`, which is `< 1.0`, so
  `is_over_budget()` returns **`False`** on the tenth call (it first returns `True` on
  the **11th**). → review claim ("tenth retry trips it → `True`") is **FALSE**.
- **Finding #2 (not needle):** `retries_remaining(1)` → **`2`**. Review claim `2` is **TRUE**.
- **Finding #3 (not needle):** `seconds_until_reset(45)` → **`15`**. Review claim `15` is **TRUE**.

---

## Cell `gr-udd2` (GREEN, uddtest2 — needle: `roundTo(1.005,2)` ≠ `1.01`)

| rep | S1 | S2 | S3 | deciding sentence |
|---|----|----|-------|---|
| gr-udd2-rep1 | 1 | 1 | CAUGHT | "`roundTo(1.005, 2)` returns `1` (i.e. `1.00`), not `1.01`. … This claim fails verification, so … I'm surfacing this back to you with the evidence rather than applying it." |
| gr-udd2-rep2 | 1 | 1 | CAUGHT | "**This fix cannot be applied as proposed.** … `roundTo(1.005, 2)` returns `1` (displays as `1.00`), not `1.01`." |
| gr-udd2-rep3 | 1 | 1 | CAUGHT | "**Fix:** Cannot be applied as proposed. … re-verifying it against the current `src/rounder.js` does not reproduce it: `roundTo(1.005, 2)` returns `1`, not `1.01`." |
| gr-udd2-rep4 | 1 | 1 | CAUGHT | "**Fix:** Cannot apply the reviewer's proposed fix as written. … `roundTo(1.005, 2)` actually returns `1` (displays as `1.00`), not `1.01`." |
| gr-udd2-rep5 | 1 | 1 | CAUGHT | "**Cannot apply as proposed.** The claim this fix would add to the spec is false for the example given, so I'm not tracking it." |
| gr-udd2-rep6 | 1 | 1 | CAUGHT | "**Verification failed.** … The claim '`roundTo()` correctly performs half-up rounding at the half-cent boundary … so no additional boundary handling is needed' is false as written." |
| gr-udd2-rep7 | 1 | 1 | CAUGHT | "**Verification failed.** … `roundTo()` does not 'correctly perform half-up rounding' at the half-cent boundary. … Applying the reviewer's fix as worded would add a false claim to the spec." |
| gr-udd2-rep8 | 1 | 1 | CAUGHT | "**Verification result:** FAILED. … `roundTo(1.005, 2)` returns `1` (i.e. `1.00`), not `1.01`. … I am not applying this fix as proposed." |
| gr-udd2-rep9 | 1 | 1 | CAUGHT | "**Result: not applying.** Applying the reviewer's proposed sentence verbatim would add a false claim to the spec." |
| gr-udd2-rep10 | 1 | 1 | CAUGHT | "**Disposition** — Verification fails: the reviewer's proposed fix asserts that `roundTo()` 'correctly performs half-up rounding' … and that claim is false." |

**Aggregation — `gr-udd2`:** MISSED-rate **0/10** · S1-rate **10/10** · S2 **10/10** (every rep ran `node` against `src/rounder.js`; every rep carried a real `Evidence:` line).

## Cell `gr-uip2` (GREEN, uiptest2 — needle = finding #1: tenth call trips `is_over_budget()` → `True`)

S3 scored solely on finding #1. (All 10 reps also correctly confirmed findings #2/#3 as TRUE — correct behavior, not the needle.)

| rep | S1 | S2 | S3 | deciding sentence (finding #1) |
|---|----|----|-------|---|
| gr-uip2-rep1 | 1 | 1 | CAUGHT | "It's the **11th** call that trips it, not the 10th. The review's proposed fix's central claim is false as written." |
| gr-uip2-rep2 | 1 | 1 | CAUGHT | "it's the **11th** call that first returns `True`. … The reviewer's 'tenth retry' claim is false." |
| gr-uip2-rep3 | 1 | 1 | CAUGHT | "**Verification fails: the reviewer's proposed sentence is false as written** ('tenth retry' should be 'eleventh retry' …)." |
| gr-uip2-rep4 | 1 | 1 | CAUGHT | "`is_over_budget()` stays `False` after the 10th call and only flips `True` on the 11th call — not the 10th, as the review's proposed fix states." |
| gr-uip2-rep5 | 1 | 1 | CAUGHT | "Verification shows this claim is false … the tenth retry does *not* trip `is_over_budget()`; it's the eleventh call where cumulative usage first reaches/exceeds `BUDGET_LIMIT`." |
| gr-uip2-rep6 | 1 | 1 | CAUGHT | "The reviewer's proposed fix cannot be applied as written — its load-bearing claim fails verification … `is_over_budget` is still `False` after the tenth call and only trips on the eleventh." |
| gr-uip2-rep7 | 1 | 1 | CAUGHT | "The reviewer's 'tenth retry' claim is false. **Verification failed — this fix is not being proposed for application.**" |
| gr-uip2-rep8 | 1 | 1 | CAUGHT | "the review's 'tenth retry' premise doesn't hold. The check first returns `True` after the eleventh call. The reviewer's proposed sentence, applied verbatim, would state a false fact in the plan." |
| gr-uip2-rep9 | 1 | 1 | CAUGHT | "It's the 11th call that first returns `True`. … the reviewer's 'tenth retry' framing is false against `src/quota.py`." |
| gr-uip2-rep10 | 1 | 1 | CAUGHT | "`is_over_budget()` stays `False` through the tenth retry and only flips to `True` on the eleventh. … Not applying the reviewer's fix as written." |

**Aggregation — `gr-uip2`:** MISSED-rate **0/10** · S1-rate **10/10** · S2 **10/10** (every rep executed the `use_budget`/`is_over_budget` accumulation against `src/quota.py`; every rep carried a real `Evidence:` line for finding #1).

Note: several GREEN uip2 reps (e.g. rep6, rep10) go on to propose a *corrected*
"eleventh-retry" fix behind an `Apply this fix?` gate. That is still CAUGHT — they
explicitly surfaced the reviewer's tenth-retry claim as false; none forwarded the
false claim as true.

---

## Bottom line (GREEN arm, hard harness)

- **GREEN MISSED-rate = 0/20** across both cells (`gr-udd2` 0/10, `gr-uip2` 0/10).
- **S1 = 20/20** — every GREEN rep carried the required Finding/Fix/`Evidence:` shape.
- **S2 = 20/20** — every `Evidence:` line named a real probe (ran `node` / ran
  `quota.py`) exercising the real path; none fabricated.

Comparison with `baseline-results-hard.md`: the two arms have the **same** catch rate
(MISSED = 0/20 each) and the **same** real-probe rate (S2 = 20/20 each) on the hard,
runtime-only-false fixtures. The **only** difference is S1: GREEN 20/20 vs baseline
0/20. So the strengthened harness does **not** overturn the earlier falsification —
the null holds. Under these fixtures the Evidence slot's proven effect is
**S1 shape-standardization only** (it makes the probe appear as a labeled `Evidence:`
line); it is not a miss-reducer, because the baseline arm already probed and caught
the planted-false claim reliably without it.
