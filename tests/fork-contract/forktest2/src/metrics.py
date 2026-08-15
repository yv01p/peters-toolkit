"""Statsd-style counters, fire-and-forget over UDP."""

import socket
import time

from .config import settings


class Metrics:
    def __init__(self):
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.addr = (settings.statsd_host, settings.statsd_port)

    def incr(self, name, value=1):
        try:
            self.sock.sendto(f"ingestd.{name}:{value}|c".encode(), self.addr)
        except OSError:
            pass

    def timing(self, name, start):
        ms = int((time.monotonic() - start) * 1000)
        try:
            self.sock.sendto(f"ingestd.{name}:{ms}|ms".encode(), self.addr)
        except OSError:
            pass


metrics = Metrics()
