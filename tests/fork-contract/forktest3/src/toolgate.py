"""Strict tool-schema gate.

Every LLM tool surface in this repo is built through ``build_tool``: the
pydantic model's emitted JSON schema is walked and any keyword outside the
whitelist raises. The whitelist is the set of constructs our strict-emission
API contract supports; do not widen it without an owner decision.
"""

ALLOWED_KEYWORDS = {
    "type", "properties", "required", "items", "anyOf", "enum", "const",
    "title", "description", "additionalProperties", "$defs", "$ref",
    "minimum", "maximum", "exclusiveMinimum", "exclusiveMaximum",
    "minLength", "maxLength", "minItems", "maxItems", "default", "format",
}

# Child dicts of these keys are name->schema maps: their KEYS are names,
# not keywords.
_NAME_MAP_KEYS = {"properties", "$defs"}


class ToolSchemaError(Exception):
    pass


def _walk(node, path):
    if isinstance(node, dict):
        for key, value in node.items():
            if key not in ALLOWED_KEYWORDS:
                raise ToolSchemaError(f"blocked keyword {key!r} at {path}")
            if key in _NAME_MAP_KEYS:
                for name, sub in value.items():
                    _walk(sub, f"{path}.{key}.{name}")
            else:
                _walk(value, f"{path}.{key}")
    elif isinstance(node, list):
        for i, item in enumerate(node):
            _walk(item, f"{path}[{i}]")


def build_tool(name, description, model):
    """Build a strict tool definition from a pydantic model, or raise."""
    schema = model.model_json_schema()
    _walk(schema, "$")
    return {
        "name": name,
        "description": description,
        "input_schema": schema,
        "strict": True,
    }
