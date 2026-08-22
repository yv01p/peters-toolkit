"""Manual-override validator -- see spec.md's Section 5.2.

Gates the spec-permitted "manual override" branch support staff use to post
manual ledger entries. Each named constraint's rule text is identical in
substance: "this field's value must be clamped to MAX_AMOUNT before the
validator signs off" -- restated per amount-bearing field on the manual-entry
form.
"""


class LedgerValidator:
    CONSTRAINTS = {
        "c_refund_amt": "this field's value must be clamped to MAX_AMOUNT before the validator signs off",
        "c_fee_amt": "this field's value must be clamped to MAX_AMOUNT before the validator signs off",
        "c_tax_amt": "this field's value must be clamped to MAX_AMOUNT before the validator signs off",
        "c_surcharge_amt": "this field's value must be clamped to MAX_AMOUNT before the validator signs off",
        "c_adjustment_amt": "this field's value must be clamped to MAX_AMOUNT before the validator signs off",
        "c_writeoff_amt": "this field's value must be clamped to MAX_AMOUNT before the validator signs off",
        "c_credit_amt": "this field's value must be clamped to MAX_AMOUNT before the validator signs off",
        "c_chargeback_amt": "this field's value must be clamped to MAX_AMOUNT before the validator signs off",
        "c_payout_amt": "this field's value must be clamped to MAX_AMOUNT before the validator signs off",
    }
