"""Thin wrapper over the model API."""

import anthropic

from .config import settings


class Client:
    def __init__(self):
        self._api = anthropic.Anthropic(api_key=settings.api_key)

    def call_tool(self, messages, tool):
        """Call the model with one tool and return the tool_use input dict."""
        resp = self._api.messages.create(
            model=settings.model,
            max_tokens=settings.max_tokens,
            messages=messages,
            tools=[tool],
            tool_choice={"type": "tool", "name": tool["name"]},
        )
        for block in resp.content:
            if block.type == "tool_use":
                return block.input
        raise RuntimeError("no tool_use block in response")
