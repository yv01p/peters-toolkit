"""Payment intake dispatch roster -- see design-spec.md's Section 4.1.

Each handler owns its own persistence call inside process().
"""


def clamp_to_max(amount, max_amount=10000):
    return max(0, min(amount, max_amount))


def _persist_to_ledger(amount):
    pass


class StripeHandler:
    def process(self, amount):
        _persist_to_ledger(clamp_to_max(amount))


class AchHandler:
    def process(self, amount):
        _persist_to_ledger(clamp_to_max(amount))


class WireHandler:
    def process(self, amount):
        _persist_to_ledger(clamp_to_max(amount))


class WalletHandler:
    def process(self, amount):
        _persist_to_ledger(amount)


class ManualHandler:
    def process(self, amount):
        _persist_to_ledger(clamp_to_max(amount))


HANDLER_ROSTER = [
    StripeHandler(), AchHandler(), WireHandler(), WalletHandler(), ManualHandler(),
]


def dispatch_intake(amount):
    for handler in HANDLER_ROSTER:
        handler.process(amount)
