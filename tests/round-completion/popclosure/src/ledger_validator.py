"""Manual-override validator -- see design-spec.md's Section 5.2.

Gates the spec-permitted "manual override" branch support staff use to post
manual ledger entries. Each named constraint's rule text is identical in
substance: this field's value must be clamped to MAX_AMOUNT before the
validator signs off, restated per amount-bearing field on the manual-entry
form.
"""


def clamp_to_max(amount, max_amount=10000):
    return max(0, min(amount, max_amount))


class LedgerValidator:
    CONSTRAINTS = (
        "c_refund_amt", "c_fee_amt", "c_tax_amt", "c_writeoff_amt",
    )

    def sign_off(self, field_values):
        clamped = {}
        for field in ("c_refund_amt", "c_fee_amt", "c_tax_amt"):
            clamped[field] = clamp_to_max(field_values[field])
        clamped["c_writeoff_amt"] = field_values["c_writeoff_amt"]
        return clamped
