#!/usr/bin/env python3
"""Explicit instructor use only: complete exercises in a NEW disposable directory."""
import argparse
from pathlib import Path
from verify_workshop import copy_fixture, complete

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("destination", type=Path, help="new destination; must not exist")
args = parser.parse_args()
destination = args.destination.resolve()
copy_fixture(destination)
complete(destination)
print(destination)
