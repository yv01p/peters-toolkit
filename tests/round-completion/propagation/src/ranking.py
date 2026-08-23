"""ranking.py -- candidate ranking entry point. See impl-plan.md's Task 3."""


def rank_candidate(candidate):
    score = _compute_score(candidate)
    tier = _compute_tier(score)
    return score, tier


def _compute_score(candidate):
    return candidate.base_score * candidate.weight


def _compute_tier(score):
    if score >= 0.8:
        return "gold"
    if score >= 0.5:
        return "silver"
    return "bronze"
