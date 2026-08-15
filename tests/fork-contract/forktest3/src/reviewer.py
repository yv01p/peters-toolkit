"""LLM call loop for the submit_edits tool."""

from pydantic import ValidationError

from .schemas import EditBatch
from .toolgate import build_tool

MAX_TOOL_RETRIES = 2

_TOOL = build_tool(
    "submit_edits",
    "Submit corrections to the case collections shown in the review packet.",
    EditBatch,
)


class ReviewFailed(Exception):
    pass


def _feedback(exc):
    lines = "\n".join(
        f"- {'.'.join(str(p) for p in err['loc'])}: {err['msg']}"
        for err in exc.errors()
    )
    return {
        "role": "user",
        "content": (
            "Your submit_edits input failed validation. Fix these problems "
            f"and call the tool again:\n{lines}"
        ),
    }


def request_edits(client, packet):
    """Ask the reviewer model for edits; re-prompt on validation failure."""
    messages = [{"role": "user", "content": packet}]
    for _ in range(MAX_TOOL_RETRIES + 1):
        tool_input = client.call_tool(messages, _TOOL)
        try:
            return EditBatch.model_validate(tool_input)
        except ValidationError as e:
            messages = messages + [_feedback(e)]
    raise ReviewFailed("submit_edits never produced a valid batch")
