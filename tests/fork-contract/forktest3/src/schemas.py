"""Tool input models for the submit_edits tool."""

from typing import Any

from pydantic import BaseModel, ConfigDict


class ReviewEdit(BaseModel):
    """One edit: replace the entry at target_id with new_content.

    target_id is "<collection>#<index>", e.g. "matrix#3", "defenses#0",
    "edges#7" — the same ids the review packet prints next to each entry,
    so the model echoes them back verbatim.
    """

    model_config = ConfigDict(extra="forbid")

    target_id: str
    new_content: dict[str, Any]  # untyped: validated per-collection at apply time


class EditBatch(BaseModel):
    model_config = ConfigDict(extra="forbid")

    edits: list[ReviewEdit]
