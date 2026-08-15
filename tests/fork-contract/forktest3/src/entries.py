"""Stored collection entry models. One model per case collection."""

from pydantic import BaseModel, ConfigDict


class MatrixEntry(BaseModel):
    """An entry in the case's `matrix` collection."""

    model_config = ConfigDict(extra="forbid")

    fact: str
    rule_ref: str
    satisfied: bool
    reasoning: str


class DefenseEntry(BaseModel):
    """An entry in the case's `defenses` collection."""

    model_config = ConfigDict(extra="forbid")

    defense: str
    elements: list[str]
    viable: bool


class EdgeEntry(BaseModel):
    """An entry in the case's `edges` collection."""

    model_config = ConfigDict(extra="forbid")

    source: str
    target: str
    relation: str
