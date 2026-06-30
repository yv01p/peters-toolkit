---
name: critical-security-review
description: Use when reviewing code, Dockerfiles, IaC configs, or dependencies for security vulnerabilities, before merging or deploying to production. Use when asked to perform a security audit, vulnerability review, or code-level threat assessment. Optionally consumes a TMA threat model document as the authoritative attack-surface map (via `tma_path`). Uses a built-in vulnerability taxonomy and severity rubric (Appendices A and B).
version: 2.0.0
---
 
# Input Contract

CSR's input contract auto-classifies arguments by shape, matching `/tma`'s discipline:

- **Required:** one or more code inputs. Each input is one of:
  - An existing local directory path → treated as code to review (used as-is, no clone)
  - An existing local file path → treated as code (single-file review)
  - An HTTPS URL (matches `https://github.com/.../` or similar) → cloned via `gh repo clone <url> <tmpdir>` (preferred — uses `gh` auth) with fallback to `git clone --depth 1 <url> <tmpdir>`. After analysis, prompt user keep-or-delete for each cloned directory at the end of Pass 3.
- **Optional `tma_path`:** path to a TMA threat-model document (typically `<repo>/docs/security/tma.md` or a path under `~/.claude/tma-outputs/`). When supplied, modifies Pass 1's behavior (see "tma_path Consumption Logic" below).
- **Optional focus hints:** prose-style scope restrictions extracted from args (e.g., "focus on auth layer", "skip the database layer"). Same pattern as `/tma`.
- **Optional output location override:** explicit path for the review file. Defaults to `docs/criticalreviews/YYYY-MM-DD-<topic>-critical-security-review-N.md` relative to the first code input's repo root (per family pattern).

If no input given, CSR asks the user to provide inputs.

CSR is **explicitly user-invoked**. No auto-trigger. No chain-from-other-skill.
 
# Out of Scope for this skill

- For threat modeling (STRIDE, threat actors, trust-boundary analysis) → run `/tma`
- For general architectural review (scaling, modularity, technical debt, migration risk, onboarding) → run `arch-review`
- For design-spec review (correctness of an unimplemented design) → run `critical-design-review`
- For implementation-plan review (correctness of a plan before execution) → run `critical-implementation-review`
 
# Family pipeline scope

CSR is optional and explicitly user-invoked. It is not a mandatory pipeline stage. Best run once implementation is complete — typically post-SDD on the finished code — as the dedicated, comprehensive security pass.

In Superpowers 6.0's SDD workflow, each task's implementation is reviewed by a merged `task-reviewer` that returns spec-compliance and code-quality verdicts; these per-task reviews are scoped to requirements and maintainability, not security. After all tasks complete, SDD dispatches one broad whole-branch final review using the general code-reviewer template, which may surface high-level security concerns among broader quality checks. CSR remains the only dedicated security-focused review in the toolkit family.

When a TMA threat model exists, CSR's `tma_path` parameter grounds the attack-surface map in the TMA's findings (see "tma_path Consumption Logic" below). CSR does not auto-chain from other skills; the user invokes it explicitly when security review is warranted.
 
# Behavioral Constraints
 
- **Never fabricate findings.** If you lack sufficient context to confirm a vulnerability, state your assumptions explicitly and mark the finding with reduced confidence.
- **Never flag generically.** Every finding must trace a concrete path: source → transformation(s) → sink, in the specific code provided.
- **Minimize false positives.** If input is provably trusted, static, or sanitized upstream, state so and skip. Err toward precision over recall — a clean report with 5 real findings beats 30 speculative ones.
- **Admit uncertainty.** If a code path is ambiguous (e.g., sanitization may exist in an unseen layer), flag it as "Requires Verification" rather than asserting vulnerability.
- **Do not hallucinate CVEs.** Only reference CVE/CWE identifiers you are certain exist. If unsure, describe the vulnerability class without a specific ID.
 
# Analysis Methodology — Three-Pass Approach
 
Execute analysis in three sequential passes. This ensures nothing is missed.
 
## Pass 1: Reconnaissance & Attack Surface Mapping
Before hunting bugs, build a mental model:
- Identify all entry points (routes, controllers, resolvers, event handlers, CLI args, file parsers, queue consumers, scheduled jobs).
- Map trust boundaries (user input → backend → database → external service → response).
- Identify authentication/authorization architecture (middleware, decorators, guards, RBAC/ABAC model).
- Catalog sensitive data flows (credentials, PII, tokens, payment data, PHI).
- Note technology stack, frameworks, and their built-in protections.

When `tma_path` is supplied, Pass 1's "build a mental model" step is grounded in the supplied TMA document — see the "tma_path Consumption Logic" section below for detailed behavior.
 
## Pass 2: Systematic Vulnerability Hunting
Before beginning Pass 2, review the canonical 10-category vulnerability classification in **Appendix A: Vulnerability Taxonomy** (below), and the severity rubric and SQS calculation rules in **Appendix B: Severity Classification & SQS** (below). The taxonomy structures Pass 2's enumeration; the severity rubric is consulted per-finding throughout Pass 2 and again when computing the final SQS in the report.

Work through each vulnerability category in **Appendix A**. For each, trace data flows across the full attack surface mapped in Pass 1.
 
## Pass 3: Cross-Cutting & Compositional Analysis
After individual categories, analyze:
- **Chained attacks:** Can two medium-severity issues combine into a critical path?
- **Implicit trust assumptions:** Does Service A trust Service B's output without validation?
- **Defense-in-depth gaps:** If one control fails, what's the blast radius?
- **Deployment context:** Do Dockerfiles, IaC configs, or CI/CD pipelines widen the attack surface?
 
# tma_path Consumption Logic

When `tma_path` is supplied:

1. **Pass 1 (Reconnaissance & Attack Surface Mapping)** reads the TMA document and uses its content as the authoritative attack-surface map:
   - TMA §3 (Architecture & data flows with trust boundaries) → CSR's component/trust-boundary map
   - TMA §4 (Threat actors) → CSR's threat-actor scope (do not re-derive; inherit)
   - TMA §5 (STRIDE-per-element) → the elements CSR will vuln-hunt in Pass 2
   - TMA §6 (Findings — prioritized roadmap) → CSR's "prior-art" findings list; each TMA finding becomes a target to confirm/refute with code-level evidence
   - CSR may add elements TMA didn't surface (if Pass 1's own scan finds attack surface TMA missed) but uses TMA's structure as the spine.
2. **Pass 2 (Systematic Vulnerability Hunting)** vuln-hunts each TMA-identified element using the loaded vuln-taxonomy. Findings are tagged with their relationship to TMA findings:
   - **Confirms TMA M1**: code-level evidence supports TMA's M1 finding; CSR's per-finding entry cross-links via "Confirms TMA M1 with code-level evidence at `file:line`"
   - **Refutes TMA L1**: code-level evidence shows TMA's L1 was incorrect or now-mitigated; CSR's per-finding entry cross-links via "Refutes TMA L1 — verification shows `<reason>` at `file:line`"
   - **Net-new** (not in TMA): finding stands alone; no cross-link field
3. **Pass 3 (Cross-Cutting & Compositional Analysis)** unchanged; cross-cutting analysis is independent of TMA grounding.

**If `tma_path` is supplied but the file does not exist, is empty, or fails to parse as markdown:** STOP Pass 1 immediately and surface this message to the user verbatim:

> CSR cannot proceed with TMA grounding: `tma_path` was supplied as `<path>` but the file does not exist (or is empty / not valid markdown). Either fix the path or omit `tma_path` to fall back to from-scratch attack-surface mapping.

Do NOT silently fall back. The user explicitly opted into TMA grounding by supplying the argument; silent fallback could produce a CSR review that diverges from user expectation.

When `tma_path` is NOT supplied:

- Pass 1 maps the attack surface from scratch using the criteria already in the methodology (entry points, trust boundaries, auth/authz architecture, sensitive data flows, technology stack)
- Pass 2 and Pass 3 unchanged
- No "TMA cross-link" field appears in any per-finding entry
 
# Output Format — Per Finding
 
Finding #[N]: [Short Descriptive Title]
 
Vulnerability: [Name] — [OWASP Category] (e.g., A01 – Broken Access Control)
Severity: Critical / High / Medium / Low
Confidence: Confirmed / High / Medium / Low
Attack Complexity: Low / Medium / High
TMA cross-link (when `tma_path` was supplied): Confirms TMA #M / Refutes TMA #M / Net-new
 
Location:
- File: path/to/file.ext, Line(s): 42–45
- Related: other/file.ext:89 (cross-file trace if applicable)
 
Risk & Exploit Path:
[Root cause → how an attacker reaches and exploits this → realistic impact.
Include: preconditions, required access level, user interaction needed.]
 
Evidence / Trace:
[Source → transformation(s) → sink. Annotated code snippets, 4–10 lines per step max.
Mark the dangerous line(s) with ← VULNERABLE comments.]
 
Remediation:
- Primary fix: [Specific secure code change — show before/after when possible, prefer framework-native safe patterns]
- Architectural improvement: [If applicable — e.g., centralized authz middleware, parameterized queries at ORM level]
- Defense-in-depth: [Additional controls — WAF rules, monitoring, rate limiting]
 
References:
- link, link — only cite identifiers you are certain of
 
# Final Report Sections
 
After all individual findings, produce these sections in order:
 
## 1. Executive Summary
2–3 paragraphs: overall risk posture, most concerning patterns, business implications, and whether the codebase is ready for production.
 
## 2. Findings Summary Table
 
| # | Title | Category | Severity | Confidence | Similar Instances | Status |
|---|-------|----------|----------|------------|-------------------|--------|
| 1 | ...   | A01      | Critical | Confirmed  | 3                 | BLOCK  |
 
## 3. Security Quality Score (SQS)

Compute and report the SQS using the calculation rules, hard gates, and posture interpretation in **Appendix B** (Severity Classification & SQS). The report's SQS section reports:

**Final SQS:** [XX]/100
**Hard gates triggered:** [Yes/No — list if any]
**Posture:** [Strong / Acceptable / Unacceptable]
 
## 4. Positive Security Observations
List 3–5 things the codebase does well (e.g., consistent use of parameterized queries, proper CSRF tokens, good secret management). This calibrates the report and acknowledges sound engineering.
 
## 5. Prioritized Remediation Roadmap
Rank the top 5 issues to fix first. For each:
1. Finding reference and title
2. Why it's prioritized (severity × exploitability × blast radius)
3. Estimated effort: Quick Win / Moderate / Significant Refactor
4. Suggested owner: Backend / Frontend / DevOps / Security Team
 
# Output Naming & Location

Family-style numbered review rounds (matches CDR + CIR):

- **Path:** `docs/criticalreviews/YYYY-MM-DD-<topic>-critical-security-review-N.md` relative to the first code input's repo root (or to `~/.claude/` if no clear repo root). User may override with explicit `output_location` arg.
- **`<topic>`:** the first code input's basename (last path segment for directories, filename without extension for files), lowercased verbatim — no abbreviation, no truncation. Dots, hyphens, and underscores in the basename are preserved as-is (e.g. `Umbraco.Cms.Persistence.EFCore.Sqlite/` → `umbraco.cms.persistence.efcore.sqlite`). If user supplied multiple code inputs, use the first one as the topic anchor. User may override with an explicit `topic` argument.
- **`N`:** round number. Check the output directory for existing files matching `*-critical-security-review-*.md` with the same `<topic>`. If none exist, `N=1`. If any exist, find the highest integer N and use `N+1`. **Never overwrite** an existing file. Always increment.
- **Single canonical file per round** (not split into per-finding files).

# Appendix A: Vulnerability Taxonomy

The canonical 10-category classification that structures Pass 2 enumeration.

## 1. Injection (OWASP A03)
Trace every untrusted input (HTTP params, headers, JSON/XML/GraphQL bodies, cookies, file uploads,
message queues, database-derived values, environment variables) to every dangerous sink (SQL/NoSQL
queries, OS commands, LDAP, template engines, eval/exec, log formatters, mail headers, regex
engines).

Hunt: SQLi, NoSQLi, command injection, SSTI, XPath injection, LDAP injection, header injection, log
injection, ReDoS, expression language injection.

## 2. Broken Access Control (OWASP A01)
Verify authorization enforcement at **every** entry point — not just the presence of middleware, but
correct application.

Hunt: IDOR, forced browsing, vertical/horizontal privilege escalation, missing function-level
authorization, mass assignment, BOLA/BFLA, tenant isolation bypass, path traversal, insecure direct
object reference via predictable IDs, CORS misconfiguration enabling cross-origin state changes,
SSRF.

## 3. Cryptographic Failures & Data Exposure (OWASP A02)
Hunt: hardcoded secrets (keys, tokens, passwords, certificates, connection strings), weak algorithms
(MD5/SHA-1 for security purposes, ECB mode, hardcoded IVs, < 2048-bit RSA), PII/credentials in
logs/error responses/client-side storage/URL parameters, missing encryption at rest or in transit,
insecure random number generation, timing-safe comparison violations.

## 4. Security Misconfiguration (OWASP A05)
Hunt: debug/verbose modes in production, stack traces in responses, directory listing, default
credentials, exposed sensitive endpoints (.git, .env, /actuator, /graphql playground, /debug, backup
files), overly permissive CORS, missing security headers (CSP, HSTS, X-Frame-Options,
X-Content-Type-Options, Permissions-Policy), permissive firewall/network rules in IaC.

## 5. Vulnerable Components & Supply Chain (OWASP A06)
Hunt: outdated dependencies with known CVEs (inspect manifests, lockfiles, Dockerfiles), missing
integrity checks (no lockfile, no hash pinning), typosquat-susceptible dependencies, overly broad
dependency versions, Dockerfile base images with known vulnerabilities, missing SBOM, unverified
third-party scripts/CDN resources.

## 6. Input Validation & Output Encoding (OWASP A03 overlap)
Hunt: missing allowlist validation, weak denylist approaches, absent/incorrect output encoding per
context (HTML body, HTML attributes, JavaScript, CSS, URL), canonicalization bypass, Unicode
normalization attacks, null byte injection, prototype pollution, parameter pollution.

→ XSS family: reflected, stored, DOM-based, mutation XSS, dangerouslySetInnerHTML / v-html /
[innerHTML] misuse.

## 7. Authentication & Session Management (OWASP A07)
Hunt: weak password policies, missing rate-limiting on auth endpoints, absent MFA, session fixation,
predictable session tokens, JWT vulnerabilities (alg:none, weak signing keys, missing expiry, key
confusion attacks), insecure password reset flows, credential stuffing exposure, token leakage
(Referer headers, logs, URLs).

## 8. Business Logic & State Machine Flaws
Hunt: race conditions (TOCTOU), idempotency bypass, negative quantity/price manipulation, unlimited
resource claims (coupons, trials, credits), payment flow bypass, state transition violations,
order/status manipulation, API parameter tampering that violates business rules, missing concurrent
request protection.

## 9. Error Handling & Information Leakage (related: OWASP A09)
Hunt: stack traces exposing internals, verbose error messages revealing schema/paths/versions,
unhandled exceptions disabling security controls, swallowed exceptions masking failures, different
error responses enabling user enumeration, debug information in production responses.

## 10. Emerging & Modern Threats
Hunt as applicable:
- **Deserialization:** gadget chains, unsafe deserializers (pickle, Java ObjectInputStream, PHP
unserialize)
- **Prototype pollution:** JavaScript object prototype manipulation
- **AI/LLM integration:** prompt injection, training data poisoning, excessive agency, insecure
output handling
- **IaC/Container:** root USER in Dockerfile, public cloud storage buckets, permissive IAM policies,
secrets in build layers, missing network policies
- **API-specific:** broken object-level authorization, unrestricted resource consumption, unsafe API
version coexistence, mass assignment via API, GraphQL introspection/batching/depth attacks
- **WebSocket:** missing origin validation, authentication bypass, injection via frames
- **CI/CD:** secret exposure in logs/artifacts, unpinned actions, script injection in workflows

# Appendix B: Severity Classification & SQS

## Severity Classification

Use CVSSv3.1 as inspiration but calibrate to **application context and exploitability**:

| Severity | Criteria | Examples |
|----------|----------|----------|
| **Critical** | Direct RCE, full auth bypass, mass data compromise, trivial exploitation, no user interaction required | Unauthenticated SQLi → full DB, command injection, hardcoded admin credentials |
| **High** | Significant data leak or privilege escalation, SSRF to internal services, mass account takeover possible, moderate exploitation complexity | Stored XSS in admin panel, IDOR to other users' PII, JWT key confusion |
| **Medium** | Limited scope, requires chaining or specific preconditions, lower likelihood | CSRF on non-critical action, reflected XSS requiring social engineering, information disclosure of internal paths |
| **Low** | Best-practice violation, defense-in-depth improvement, minimal direct impact | Missing security header, verbose error in non-sensitive endpoint, cookie without SameSite |

## Security Quality Score (SQS)

**Calculation (starts at 100):**

| Finding Severity | Deduction per Instance | If Grouped (≥3 similar) |
|-----------------|----------------------|------------------------|
| Critical        | −40                  | −40 (count as one)     |
| High            | −20                  | −20 (count as one)     |
| Medium          | −8                   | −8 (count as one)      |
| Low             | −2                   | −2 (count as one)      |
| Informational   | −1                   | −1 (count as one)      |

**Hard gates (override numeric score → automatic BLOCK):**
- Any unremediated Critical finding
- Any Critical/High CVE with EPSS ≥ 0.2 or listed in CISA KEV
- Hardcoded secrets or leaked credentials in source code

**Interpretation:**
| Score          | Posture                                  |
|----------------|------------------------------------------|
| ≥ 85, no Criticals | Strong — deploy with standard monitoring |
| 70–84          | Acceptable — deploy only with remediation commitment and timeline |
| < 70           | Unacceptable — block deployment, urgent remediation required |
