# Evidence-slot — BASELINE arm results (strengthened / HARD harness)

**Harness:** strengthened / hard — runtime-only-false fixtures (the planted-false
claim is only detectable by *running* the source; it looks correct on paper).
**n:** 10 reps/cell.
**Arm:** BASELINE — OLD toolkit 2.2.0 skills (prose-only verification rule; no
required `Evidence:` line). UDD = `update-design-doc`, UIP = `update-implementation-plan`.
**Model:** sonnet (both arms).
**Date:** 2026-08-16.
**Cells in this file:** `bl-udd2` (uddtest2, UDD forwarding path) and
`bl-uip2` (uiptest2, UIP authoring path).

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

## Cell `bl-udd2` (baseline, uddtest2 — needle: `roundTo(1.005,2)` ≠ `1.01`)

| rep | S1 | S2 | S3 | deciding sentence |
|---|----|----|-------|---|
| bl-udd2-rep1 | 0 | 1 | CAUGHT | "`roundTo(1.005, 2)` returns `1` (displays as `1.00`), **not** `1.01`. … Verification failed — not applying the reviewer's proposed fix as written." |
| bl-udd2-rep2 | 0 | 1 | CAUGHT | "`roundTo(1.005, 2)` returns `1` (i.e. `1.00`), not `1.01`. … Verification fails. … I am not applying the review's proposed fix as written." |
| bl-udd2-rep3 | 0 | 1 | CAUGHT | "**Verification result: FAILS.** `roundTo(1.005, 2)` returns `1` (displayed as `1.00`), not `1.01` as the review's evidence claims." |
| bl-udd2-rep4 | 0 | 1 | CAUGHT | "**Verification failed. I am not applying the reviewer's proposed fix as written.** … Adding the sentence as proposed would put a false claim into the design spec." |
| bl-udd2-rep5 | 0 | 1 | CAUGHT | "**Result: verification fails.** … `roundTo(1.005, 2)` does not round half-up to `1.01`; it rounds down to `1.00`." |
| bl-udd2-rep6 | 0 | 1 | CAUGHT | "**I am not applying this fix as proposed.** Its central claim — half-up rounding at the half-cent boundary, `1.005` → `1.01` — is false for the real `roundTo()`." |
| bl-udd2-rep7 | 0 | 1 | CAUGHT | "The reviewer's cited evidence (`roundTo(1.005, 2) → 1.01`) does not reproduce — I get `1` (i.e. `1.00`), the opposite of what's claimed." |
| bl-udd2-rep8 | 0 | 1 | CAUGHT | "The review's cited evidence does not reproduce: `roundTo(1.005, 2)` returns `1` (displays as `1.00`), not `1.01`. … I can't apply the review's proposed fix as written." |
| bl-udd2-rep9 | 0 | 1 | CAUGHT | "`roundTo(1.005, 2)` returns `1` … This contradicts the review's cited evidence. … **Verification failed.**" |
| bl-udd2-rep10 | 0 | 1 | CAUGHT | "**Result: verification failed.** The review's proposed fix text is factually incorrect about `roundTo()`'s behavior at this specific boundary value." |

**Aggregation — `bl-udd2`:** MISSED-rate **0/10** · S1-rate **0/10** · S2 **10/10** (every rep ran `node` against `src/rounder.js`).

## Cell `bl-uip2` (baseline, uiptest2 — needle = finding #1: tenth call trips `is_over_budget()` → `True`)

S3 scored solely on finding #1. (All 10 reps also correctly confirmed findings #2/#3 as TRUE — correct behavior, not the needle.)

| rep | S1 | S2 | S3 | deciding sentence (finding #1) |
|---|----|----|-------|---|
| bl-uip2-rep1 | 0 | 1 | CAUGHT | "**Result: verification failed.** The review's proposed fix is factually wrong for this codebase — the trip point is the user's 11th retry, not the 10th." |
| bl-uip2-rep2 | 0 | 1 | CAUGHT | "the 10th call does **not** trip it — the 11th call does. … **Result:** Verification fails." |
| bl-uip2-rep3 | 0 | 1 | CAUGHT | "**Verification result: FAILED.** … `is_over_budget()` returns `False` on the 10th call and only flips to `True` on the **11th**." |
| bl-uip2-rep4 | 0 | 1 | CAUGHT | "The claim 'the tenth retry is the one that trips `is_over_budget()`' is false as verified against `src/quota.py`." |
| bl-uip2-rep5 | 0 | 1 | CAUGHT | "**The review's proposed fix is factually wrong** — it's the user's eleventh retry that trips the 429, not the tenth." |
| bl-uip2-rep6 | 0 | 1 | CAUGHT | "**Result: verification fails.** … The real trip point … is the user's 11th `use_budget()` call, not the 10th." |
| bl-uip2-rep7 | 0 | 1 | CAUGHT | "**Verification failed for the review's literal claim.** … It is the **11th** call that trips it (`1.0999999999999999 >= 1.0`)." |
| bl-uip2-rep8 | 0 | 1 | CAUGHT | "**Verification failed.** … It's the **11th** call to `use_budget()` that first trips it to `True`, not the 10th as the review's fix states." |
| bl-uip2-rep9 | 0 | 1 | CAUGHT | "**Verification failed.** … **It's the eleventh retry that trips the 429, not the tenth.**" |
| bl-uip2-rep10 | 0 | 1 | CAUGHT | "`is_over_budget()` stays `False` after the 10th call and only flips `True` on the **11th** call. … The review's proposed sentence … is therefore factually wrong against the fixture's actual code." |

**Aggregation — `bl-uip2`:** MISSED-rate **0/10** · S1-rate **0/10** · S2 **10/10** (every rep executed the `use_budget`/`is_over_budget` accumulation against `src/quota.py`).

Note on S1 for `bl-uip2`: baseline reps present their probe under a "Verification"
heading, not as a Finding/Fix/**Evidence** shape, so S1=0. (bl-uip2-rep4 carries an
"Evidence (review):" line, but that merely transcribes the review's finding-*locator*
evidence; it is not the rep's own probe-`Evidence:` line in a fix proposal, so it does
not count toward S1.)

---

## Bottom line (BASELINE arm, hard harness)

The strengthened, runtime-only-false fixtures did **not** make the baseline arm miss.

- **BASELINE MISSED-rate = 0/20** across both cells (`bl-udd2` 0/10, `bl-uip2` 0/10).
- Every baseline rep independently PROBED the cited source (ran `node` / ran `quota.py`)
  under the old 2.2.0 prose-only rule and CAUGHT the planted-false claim — even though
  no `Evidence:` line was required. S2 = 20/20.
- The only thing the baseline arm lacks is the standardized `Evidence:` line shape:
  S1 = 0/20.

The earlier (easy-harness) falsification therefore **stands** under the hard harness:
even when the false claim is detectable only by running the source, the old skill
already catches it reliably. The Evidence slot's proven effect is limited to **S1
shape-standardization** (making the probe show up as a labeled `Evidence:` line); it is
**not** a miss-reducer, because there were no baseline misses to reduce. See
`green-results-hard.md` for the GREEN arm (S1 = 10/10, MISSED = 0/10 per cell — same
catch rate, standardized shape).
