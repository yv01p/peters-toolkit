"""Datastore client. Thin wrapper over the backend HTTP API."""

import requests

from .config import settings
from .errors import TransientBackendError


class Store:
    def __init__(self, base_url=None):
        self.base_url = base_url or settings.store_url
        self.session = requests.Session()

    def submit(self, payload):
        try:
            resp = self.session.post(
                f"{self.base_url}/v1/rows",
                json=payload,
                timeout=settings.store_timeout,
            )
        except (requests.Timeout, requests.ConnectionError) as e:
            raise TransientBackendError(str(e)) from e
        if resp.status_code >= 500:
            raise TransientBackendError(f"backend {resp.status_code}")
        resp.raise_for_status()
        return resp.json()["row_ids"]
