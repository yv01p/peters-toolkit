"""Env-driven settings."""

import os
from dataclasses import dataclass


@dataclass
class Settings:
    api_key: str = os.environ.get("ANTHROPIC_API_KEY", "")
    model: str = os.environ.get("CASEAUDIT_MODEL", "claude-sonnet-5")
    max_tokens: int = int(os.environ.get("CASEAUDIT_MAX_TOKENS", "8192"))
    cases_dir: str = os.environ.get("CASEAUDIT_CASES_DIR", "cases")


settings = Settings()
