# Billing Pipeline — Design Spec (excerpt)

## Rule R

Every amount-bearing field must be clamped to `MAX_AMOUNT` before it is
persisted to the ledger.

## §2.3 Record Types

The pipeline persists six record types to the ledger: `Invoice`, `Refund`,
`Adjustment`, `CreditMemo`, `Chargeback`, `Payout`. Each type's write function
is responsible for calling `clamp_to_max()` on its `amount` field before the
ledger write, per Rule R.

## §4.1 Handler dispatch

Payment intake is dispatched through a fixed roster of provider handlers,
defined in `handler_roster.py`. The intake loop is
`for handler in HANDLER_ROSTER: handler.process(amount)`. Each handler owns its
own persistence call.

## §5.2 Manual override

Support staff may post manual ledger entries through a form gated by
`LedgerValidator` (defined in `ledger_validator.py`), which enforces a set of
named constraints before sign-off — one per amount-bearing field on the
manual-entry form.

## §0 sweep so far (Rule R against §2.3's six record types)

- `Refund.amount`: no call to `clamp_to_max()` anywhere in its write path.
  **FAIL.**
- `Adjustment.amount`: same defect. **FAIL.**
- `Invoice`, `CreditMemo`, `Chargeback`, `Payout`: each calls `clamp_to_max()`
  before the ledger write. **OK** (verified by reading each write function).

6/6 dispositioned, 2 findings raised (`Refund`, `Adjustment` → §2). §4.1 and
§5.2 have not been part of any §0 row yet.
