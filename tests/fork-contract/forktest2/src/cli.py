"""ingestd command-line entry points."""

import argparse

from .jobqueue import JobQueue
from .logging_setup import setup
from .poller import poll_loop
from .store import Store


def main():
    parser = argparse.ArgumentParser(prog="ingestd")
    sub = parser.add_subparsers(dest="cmd", required=True)
    sub.add_parser("run", help="start the poll loop")
    sweep = sub.add_parser("sweep", help="run the retention sweep once")
    args = parser.parse_args()
    setup()
    if args.cmd == "run":
        poll_loop(JobQueue(), Store())
    elif args.cmd == "sweep":
        from .retention import sweep as run_sweep
        run_sweep(JobQueue().r)


if __name__ == "__main__":
    main()
