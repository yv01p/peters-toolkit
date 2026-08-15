"""Case load/save against the cases directory (one JSON file per case)."""

import json
from pathlib import Path

from .config import settings
from .entries import DefenseEntry, EdgeEntry, MatrixEntry


class Case:
    def __init__(self, id, collections, path):
        self.id = id
        self.collections = collections
        self.path = path
        self.status = "pending"

    def packet(self):
        lines = []
        for name, entries in self.collections.items():
            for i, entry in enumerate(entries):
                lines.append(f"[{name}#{i}] {entry.model_dump_json()}")
        return "\n".join(lines)

    def mark_reviewed(self):
        self.status = "reviewed"
        self.save()

    def mark_failed(self, reason):
        self.status = f"failed: {reason}"
        self.save()

    def save(self):
        data = {
            "id": self.id,
            "status": self.status,
            "collections": {
                name: [e.model_dump() for e in entries]
                for name, entries in self.collections.items()
            },
        }
        self.path.write_text(json.dumps(data, indent=2))


def load_case(path):
    data = json.loads(Path(path).read_text())
    models = {"matrix": MatrixEntry, "defenses": DefenseEntry, "edges": EdgeEntry}
    collections = {
        name: [models[name].model_validate(e) for e in data["collections"][name]]
        for name in models
    }
    return Case(data["id"], collections, Path(path))


def iter_cases():
    for path in sorted(Path(settings.cases_dir).glob("*.json")):
        yield load_case(path)
