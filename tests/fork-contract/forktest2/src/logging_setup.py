"""Structured logging bootstrap."""

import logging
import sys


def setup(level=logging.INFO):
    handler = logging.StreamHandler(sys.stderr)
    handler.setFormatter(logging.Formatter(
        "%(asctime)s %(levelname)s %(name)s %(message)s"
    ))
    root = logging.getLogger()
    root.handlers[:] = [handler]
    root.setLevel(level)
