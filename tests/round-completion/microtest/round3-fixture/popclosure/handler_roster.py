"""Payment intake dispatch roster -- see spec.md's Section 4.1.

Each handler owns its own persistence call inside process().
"""

HANDLER_ROSTER = [
    stripe_handler, ach_handler, wire_handler, paypal_handler,
    venmo_handler, zelle_handler, check_handler, wallet_handler,
    giftcard_handler, crypto_handler, manual_handler,
]


def dispatch_intake(amount):
    for handler in HANDLER_ROSTER:
        handler.process(amount)
