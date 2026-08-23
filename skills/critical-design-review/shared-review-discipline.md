# Shared review discipline (CDR + CIR companion)

Binding for `critical-design-review` and `critical-implementation-review`.
Each skill's SKILL.md instructs reading this file at invocation; its rules apply
to the review exactly as if they appeared in the SKILL.md itself.

Terminology mapping:

| Term here | In CDR | In CIR |
|---|---|---|
| the artifact | the design spec | the implementation plan |
| the outcome | the user's stated outcome | the spec's stated outcome at execution time |
| the author | spec author | plan author |

## Reviewer mindset

Your job is to find the things in the artifact that would literally break the
outcome. You are not paid by the issue. An empty review is a valid output. Your
job is correctness-defense, not value-demonstration.

You are not playing a role — not a Senior Principal Architect, not a Staff
Software Engineer. You are not graded on issues-found per review. The discipline
emerges from the constraints in these skills — the literal-wrongness test, the
bounded finding categories, the explicit delegation to other skills — not from a
persona.

## Evidence tiers: the disposition must match the claim class

An `ok` disposition is only as strong as the evidence named in it. For
**load-bearing rows** — any row whose failure would be a §1 or §2 finding — the
named check must meet the tier its claim class requires. Paste the decisive
evidence into the row (the actual key list, the actual count, the command run);
an evidence tier asserted but not shown is fabricated coverage.

| Claim class | Minimum evidence | Never sufficient |
|---|---|---|
| Totality/coverage over a population ("the join holds", "every X maps", "all keys parse") | Run the rule over the full real population it will see, or inspect both the covered set and the residual set | One sampled instance generalized to the class (n=1 "spot check") |
| Field present in a persisted artifact | Dump a real record's key set and cite the keys | Schema docstrings, Pydantic models, or the in-memory type of the same concept |
| Field absent from a persisted artifact | A dump of a record that **reached the state that populates the field** (stratify by status before sampling) | Absence in a record that never reached the populating state |
| Artifact–consumer compatibility ("the harness consumes these files") | Push at least one real artifact through the consuming operation or its validator | Existence/count evidence — "67 files on disk" discharges "67 files exist", never "these files load" |
| Bidirectional completeness ("every X is Y" mappings, span checks) | Both directions checked, each direction's disposition named in the row | A one-direction pass |

A load-bearing
row that can't meet its tier in-round is not `ok`: upgrade the evidence, or
surface it as a §3 forced decision (verify empirically / accept the risk /
defer). Non-load-bearing rows keep their one-line check; the ladder does not
license padding.

**Per-direction dispositions.** A §0 row for rule-like content shows each failure direction as its own disposition: `over: ok — <probe> / under: → §2.1`. "Check BOTH failure directions" is visible output, not a private step — a row showing one direction is visibly incomplete.

**Claim-class tags.** Every load-bearing disposition and every `Evidence:` line (on §2 fixes and §3 options) opens with a bracketed class tag from this closed vocabulary, mapping onto the ladder rows above: `[totality]`, `[presence]` (field/element present in a persisted artifact), `[absence]`, `[compat]` (artifact–consumer compatibility), `[bidirectional]`, `[negative]` (negative claims, below), `[existence]` (existence-level claims only). The evidence shown after the tag must meet that class's ladder tier — the tag is what makes a read-tier check on a run-tier claim visible at a glance.

**The ladder binds findings too, in the same direction.** A §2 candidate is a
claim about behavior, and its claim class sets the tier its evidence must meet.
Mechanism reasoning over file:line cites is read-tier — for a runtime claim
("this gate cannot pass", "every subsequent call fails") it routinely misses the
interaction (a reload, a fixture, an ordering) that flips the outcome. When the
claimed failure is cheaply runnable in-round (one command, importable
dependencies), run it before the candidate becomes a finding: a probe that
confirms the failure is the finding's evidence; a probe that comes out green is
a disproof that just saved a round. If it can't be run, name the finding's
evidence tier honestly in its row.

**Probe altitude.** A probe discharges a claim only at the altitude the claim is stated at: a module- or entry-point-level claim requires a probe entering through that surface, not through the internal mechanism the claim was inferred from — a regex-level probe is blind to a pre-regex guard. And the probe must exercise the **artifact's described mechanism or cited precedent as described**: a probe of the reviewer's own correct reconstruction verifies the reconstruction, not the artifact.

## Population closure

When any §0 row confirms a **rule-vs-population mismatch** — a rule that fails against a member of a population it governs — the round cannot close until the full (rule × every population it governs) matrix is enumerated: as individual §0 rows, or as one row naming the matrix with a disposition per cell (`ok — <evidence>` / `→ §2.n` / `dropped — <reason>` / `UNVERIFIED: <why>`). "Population" is read expansively:

- The **roster a rule iterates over is itself a governed population** — the outer matrix (rule × roster) needs cells dispositioned, not only the inner matrix the first finding came from.
- The **constraint set of a validator gating a spec-permitted branch** is a population that branch is checked against.
- **Both failure directions apply per cell**, not per rule — a cell checked for over-inclusion only is half-dispositioned (per-direction grammar above).

"Two instances found" triggers full enumeration, never a stop. A population too large to close in-round is not silently sampled: the residual cells get one `UNVERIFIED: <the uncovered remainder>` row, which flows to §3 as a forced decision (verify empirically / accept the risk / defer) — exactly like an unverifiable negative claim.

## Negative claims require empirical evidence

A **negative claim** asserts that something does NOT happen — "consumer X
doesn't access internals of Y", "symbol Z has no callers", "the unit suite
never performs live HTTP", "no other task touches this file". Authors often
cite negative claims as the reason a deletion or change is safe. When a
negative claim is **load-bearing for the artifact's safety**, you MUST treat it
as a §2 candidate UNLESS you have grep evidence against the specific symbol
whose absence is being claimed. A negative claim accepted on faith is the most
common way a review misses a real literal-wrongness finding.

### Verification recipe

| Claim shape | Grep target | Hit means |
|---|---|---|
| "Consumer X doesn't access [internal/private/protected] members of provider Y" | The **specific internal symbol names** declared in Y — especially type names — grep'd in X's source. Not the public API around them. | Claim is FALSE → §2 finding. |
| "Symbol Z is unused" / "Z has no callers" | `\bZ\b` across the codebase, excluding Z's own declaration site. | Any non-self hit → claim FALSE → §2. |
| "Feature/flag F is dead" | `\bF\b` and any documented aliases / configuration keys. | Hit → claim FALSE → §2. |
| "Module M has no external dependents" | Imports / `require` / project references / `using` statements naming M. | Hit → claim FALSE → §2. |
| "Rule R produces correct output on all inputs of class C" (incl. coverage-rate claims) | Run R — or hand-trace it — over the real corpus it will see. Inspect BOTH the covered set (spurious hits) AND the residual set (silent misses). | Either failure direction on real data → §2. |
| "X is unaffected by this change" — where the change (or an applied fix) sets, renames, or removes ambient state: an env var, module global, config key, fixture | Every reader of that name, src AND tests (`\bNAME\b`) — the readers ARE the affected set | Any reader without a per-reader disposition → claim unverified → §2 candidate. |

### Critical pitfall — grep the right symbol

"X uses only public API `foo()`" is NOT sufficient evidence that "X doesn't
access internal type `T`". Public methods can return internal types; field
declarations, parameter types, local-variable types, and base-class declarations
all require the type itself to be accessible. **If T is the access-controlled
symbol, grep X for `\bT\b` — not for the public method that happens to return T.**

Worked example (real failure that motivated this section): an artifact claimed
deleting `[InternalsVisibleTo("Enrichers.GlobalExecutionId")]` was safe because
"that enricher uses only the public LibLog API". Grepping the public entry point
`LogProvider` found a hit and the claim looked verified. Grepping the internal
type `\bILog\b` found four `private readonly ILog _logger = ...` fields — the
field type is internal, and removing the IVT breaks compilation in 4 files. The
public-API call returned an internal type; the claim was false.

### Input-cleanliness claims are negative claims

"X is just the party name", "this field never carries suffixes", "input class C
needs no special handling" — each asserts an absence of structure in an input.
When a rule's correctness rests on one, it is load-bearing; test it against the
real corpus, in both failure directions. Real failure that motivated this: a
citation matcher extracted a first-party surname as "the last content token
before `v.`"; the artifact asserted the text before `v.` "is just the party
name". Real corpus anchors had corporate parties (`Air Safety, Inc. v. …`
extracts `inc.`), so every corporate-first-party citation silently failed to
match — a false-negative miss on the operand assumed clean, which three review
rounds hunting over-inclusion only never caught.

### When grep can't verify

If access happens through reflection, dynamic dispatch, code generation, runtime
DI registration, string-based lookup, or any mechanism that hides symbol
references from grep — the negative claim is unverifiable at review time. Do
NOT bless it as "probably fine". Surface as a §3 forced decision: "Verify
empirically by attempting the change and observing the toolchain's response;
defer the change if it fails."

### When the claim is incidental, not load-bearing

The literal-wrongness test still applies. A throwaway "this isn't used
elsewhere" remark in artifact prose is NOT a review concern. An explicit "this
is safe to delete because nothing depends on it" IS. The trigger is whether the
artifact's safety argument rests on the negative claim.

## Proposed fixes and §3 options are claims too

A §2 finding's proposed fix is reviewer-authored artifact text: the update
skill applies it, often verbatim. A proposed fix that introduces a new
load-bearing claim — names a function or signature, asserts a property of the
data or corpus, claims an instrument capability, or asserts parity/safety "by
construction" — must carry the same evidence these skills demand of the text it
is replacing: grep, dump, signature read, or run, cited inline. If the evidence
can't be produced in-round, prefix the fix with `UNVERIFIED:` so the update
skill treats it as a claim to verify before applying. An unverified fix applied
verbatim is how a review authors the next round's finding.

The same rule governs §3: each option under a forced decision is
reviewer-authored text the user decides with. Any differentiating claim inside
an option — "path A preserves X", "the toolchain rejects B", "C requires no
migration" — carries the same evidence requirement, or the `UNVERIFIED:`
prefix. The reviewer never picks, but the user picks using the trade-offs the
reviewer asserts.

**Structural requirement:** every §2 proposed fix and every §3 option ends with
an `Evidence:` line naming the probe behind each load-bearing claim in it (grep
/ dump / signature read / run, with its result), or `UNVERIFIED:` for what
couldn't be probed in-round. A fix or option without its Evidence line is
visibly incomplete. A probe must be falsifiable: evidence that constructs the
very state it claims to detect (rather than exercising the real path) is
fabricated coverage — name the result that would have come out otherwise.

**The option set itself is a claim.** A §3 item must state why no combination
of the listed options — and no unlisted variant — dominates them; a dominant
hybrid discovered after the user has chosen is a decision made on an incomplete
menu. Probing the options is what surfaces the dominant variant; do it before
presenting, not after.

## Shared reviewer rationalization table

These thoughts mean STOP — you're rationalizing your way into producing
speculation or fabricated coverage:

| Thought | Reality |
|---|---|
| "I should propose at least one alternative architecture/implementation to be helpful." | Alternatives serve §2 findings; without one, an alternative is forced speculation. |
| "I notice X could fail at scale" — but scale isn't in the artifact. | The user didn't ask; apply the literal-wrongness test against the outcome. |
| "There's no metrics / observability / audit trail." | Generic over-instrumentation noise unless the user asked. |
| "We could refactor X for clarity." | Adjacent improvement. Drop. |
| "Best practice would be to add X." | Best-practice ≠ correctness; apply the literal-wrongness test. |
| "Nothing critical found — I'll at least surface minor improvements." | Empty is a valid output; there is no minor-improvements section to fill. |
| "The verified-assumptions section claims X, but what if it changes?" | Verified facts are ground truth; "what if it changes" is speculation. |
| "The artifact doesn't address [edge case the user didn't mention]." | The artifact covers the asked-for path; edge cases surface during implementation. |
| "Quality reviews find at least N issues." | Quota-driven critique; the real count is whatever is actually wrong, often zero. |
| "I'm experienced; I should have an opinion on the choices made." | The author picked them; opinions are noise unless literal-wrongness fails. |
| "The verified section says X, but I should double-check by re-reasoning." | Re-read the cited evidence; reconfirm or fail it. Don't re-litigate via vibes. |
| "Small artifact — I should find at least one concern or the review looks lazy." | Small artifacts rest on smaller assumptions, not weaker ones. |
| "A security issue that doesn't fail literal-wrongness — I'll surface it as an FYI." | That's `critical-security-review`'s job; FYIs are noise here. |
| "I'll make it a §3 forced decision so the user has to weigh in." | §3 is for choices real constraints force, not topics you find interesting. |
| "The §2 fix would also benefit from adjacent refactoring; I'll fold it in." | The finding is the finding; don't expand scope to justify cleanup. |
| "I'll add questions for clarification." | No Questions section exists: real either/or → §3; speculation about intent → drop. |
| "The outcome obviously implies X (which the artifact doesn't say)." | If the artifact doesn't say X, X is not the outcome — don't smuggle it in to manufacture a finding. |
| "I have a solid finding already; the rest is probably fine." | One finding proves the search worked, not that it finished; every §0 row needs a disposition. |
| "Enumerating the surface is overhead; I'll spot-check the likely areas." | §0 is checkable output — a missing row is a visible hole; spot-checking is how silent misses survive. |
| "This mechanism is spike-tunable / calibrated later, so it's out of scope." | Calibration sets values; it cannot repair mechanics (identity keys, exclusions, input availability), which are wrong at every value. |
| "The artifact names the paths that produce this status, and I verified those." | The predicate matches whatever the CODE can produce; grep the producers — the unnamed one is the unhandled input class. |
| "I verified this operation's parameter sourcing at its call site." | At *a* call site. One row per caller — the caller treated as a copy of another is the one that breaks. |
| "This block already gave me a finding; the rest of it is covered." | A finding disposes a defect, not a surface; the block's remaining identifiers are unchecked until checked. |
| "The field wasn't in the records I sampled, so it's absent." | Records that never reached the populating state prove nothing; sample where the field would be set. |
| "I found the broken check; the rest of that validator is a different concern." | A found check has siblings enforcing the same invariant; inventory the enclosing span. |
| "This test's outbound call is mocked; the test's row is done." | One row per outbound seam; the unmocked second seam is where the live call escapes. |
| "The fix is my own analysis; it doesn't need the evidence treatment." | Reviewer-authored text bypasses every gate unless this rule holds. |
| "§3 options are just sketches; they don't need the evidence treatment." | The user decides with the trade-offs you assert; a §3 differentiating claim is as load-bearing as a §2 fix. |
| "I verified this earlier in the round; the Evidence line is redundant." | Then it costs one sentence: name the probe and result. Evidence that can't be named in one line was remembered, not verified. |
| "My probe demonstrates the point — I set up the state and showed the check catches it." | A probe that force-assigns the state it claims to detect cannot come out the other way; exercise the real path and name what would have falsified it. |
| "The failure mechanism is clear from reading the code; running it would only confirm it." | Read-tier reasoning about runtime behavior misses the interaction that flips the outcome; if it's one runnable command away, run it before it becomes a finding. |
| "My probe hits the mechanism the claim is really about; the entry point is just plumbing." | A claim stated at module/entry-point altitude is discharged only by a probe entering through that surface; the plumbing is where the pre-mechanism guard lives. |
| "The artifact's description is roughly what my probe implements; close enough." | A probe of your own reconstruction verifies the reconstruction, not the artifact. Probe the described mechanism as described — a passing simulation of the wrong operation is fabricated coverage. |
