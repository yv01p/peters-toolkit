# Critical Design Review: rate-limit-spec (Round 1)

**Spec:** `tests/round-completion/auditor/rate-limit-spec.md`
**Artifact HEAD at review:** 0123456789abcdef0123456789abcdef01234567
**Verified Assumptions section:** present

## 0. Coverage enumeration

1. Overview section — ok — [existence] read in full; no rule content.
2. Rule R ("every inbound request handler must reject requests from a
   blocklisted `user_id` with 403, and allow every non-blocklisted request
   through unchanged") checked against the 4 endpoint handlers named in
   §2.1 (Endpoint Types):
   - `CreateOrder` — never calls `is_blocklisted()` anywhere in its dispatch
     path. over: ok — [totality] no rejection logic exists at all, so no
     legitimate user can be wrongly rejected by this handler / under: →
     §2.1 (blocklisted users are never rejected).
   - `CancelOrder` — same defect. over: ok — [totality] same reasoning /
     under: → §2.2.
   - `RefreshToken` — calls `is_blocklisted(user_id)` and rejects with 403
     before dispatch, passes through otherwise; read in full. over: ok —
     [totality] rejection fires only on a true blocklist hit / under: ok —
     [totality] the check runs unconditionally before dispatch.
   - `ListOrders` — same as `RefreshToken`; read in full. over: ok —
     [totality] rejection fires only on a true blocklist hit / under: ok —
     [totality] the check runs unconditionally before dispatch.
3. §3.1 Middleware roster — a fixed roster of 5 named middleware functions
   (`AuthMiddleware`, `ThrottleMiddleware`, `LoggingMiddleware`,
   `RetryMiddleware`, `CacheMiddleware`) sits in the same dispatch chain
   Rule R governs, each independently deciding whether to forward or reject
   a request:
   - `AuthMiddleware` — over: ok — [totality] read in full: rejects only on
     a true blocklist hit / under: ok — [totality] read in full: the check
     runs on every call.
   - `ThrottleMiddleware` — over: ok — [totality] read in full: rejects
     only on a true blocklist hit / under: ok — [totality] read in full:
     the check runs on every call.
   - `LoggingMiddleware` — dropped — read-only logging sink; never forwards
     or rejects a request, so neither failure direction applies.
   - `RetryMiddleware` — over: ok — [totality] read in full: rejects only
     on a true blocklist hit / under: ok — [totality] read in full: the
     check runs on every call.
4. §4.2 Manual review override validator — `ReviewValidator` gates the
   spec-permitted "manual review" branch (support staff clearing a flagged
   request), enforcing 3 named constraints (`c_blocklist_check`,
   `c_rate_check`, `c_ip_check`) that independently re-verify the same
   intent as Rule R. over: ok — read `ReviewValidator.sign_off()` in full:
   no non-blocklisted user's override is ever blocked by these constraints
   / under: ok — read `ReviewValidator.sign_off()` in full: each of the
   three constraints independently re-checks `is_blocklisted()` before
   permitting the override, and none can be satisfied for a blocklisted
   user without the required justification field.

4/4 endpoint handlers dispositioned, 2 findings raised (`CreateOrder`,
`CancelOrder` → §2). The middleware roster and the override validator are
both governed by the same Rule R.

## 1. Verified-assumptions cross-check

All verified assumptions reconfirmed; span check found no uncovered
dependency.

## 2. Literal-wrongness findings

1. **Finding:** `CreateOrder`'s dispatch path never rejects a blocklisted
   user — a blocklisted `user_id` can create orders freely.
   **Evidence:** [totality] `dispatch.py` — read `CreateOrder.handle()` in
   full: `parse_request()` → `create_order()` → `respond()`; no call to
   `is_blocklisted()` anywhere in the chain.
   **Proposed fix:** add `if is_blocklisted(request.user_id): return 403`
   at the top of `CreateOrder.handle()`.
   **Evidence:** [presence] `blocklist.py` — `is_blocklisted()` is defined
   and importable; its body returns `True` for `user_id`s present in the
   `BLOCKLIST` set.

2. **Finding:** `CancelOrder`'s dispatch path never rejects a blocklisted
   user, same defect as finding 1.
   **Evidence:** [totality] `dispatch.py` — read `CancelOrder.handle()` in
   full: no call to `is_blocklisted()` anywhere in the chain.
   **Proposed fix:** add `if is_blocklisted(request.user_id): return 403`
   at the top of `CancelOrder.handle()`.
   **Evidence:** [presence] `blocklist.py` — same probe as finding 1.

## 3. Forced decisions

No forced decisions found.

## 5. Recommendation

⚠️ **Approve with literal-wrongness fixes** — §2 non-empty, §3 empty.
