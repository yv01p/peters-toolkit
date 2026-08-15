"""Apply a validated EditBatch to a case's stored collections."""

from pydantic import ValidationError

from .entries import DefenseEntry, EdgeEntry, MatrixEntry

_COLLECTION_MODELS = {
    "matrix": MatrixEntry,
    "defenses": DefenseEntry,
    "edges": EdgeEntry,
}


class ApplyError(Exception):
    pass


def apply_edits(case, batch):
    for edit in batch.edits:
        collection, sep, index = edit.target_id.partition("#")
        if not sep or collection not in _COLLECTION_MODELS:
            raise ApplyError(f"bad target_id {edit.target_id!r}")
        try:
            idx = int(index)
        except ValueError:
            raise ApplyError(f"bad index in target_id {edit.target_id!r}")
        entries = case.collections[collection]
        if not 0 <= idx < len(entries):
            raise ApplyError(f"{edit.target_id!r} out of range")
        model = _COLLECTION_MODELS[collection]
        try:
            entries[idx] = model.model_validate(edit.new_content)
        except ValidationError as e:
            raise ApplyError(
                f"{edit.target_id!r}: content is not a valid "
                f"{model.__name__}: {e.error_count()} errors"
            )
    case.save()
