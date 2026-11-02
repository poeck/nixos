#!/usr/bin/env python3
"""Apply the managed desk layout while retaining Lan Mouse pairing approvals."""

import json
import os
from pathlib import Path
import sys
import tempfile
import tomllib


def prepare(template: Path, destination: Path) -> None:
    fingerprints = {}
    if destination.exists():
        with destination.open("rb") as source:
            fingerprints = tomllib.load(source).get("authorized_fingerprints", {})
        if not isinstance(fingerprints, dict) or not all(
            isinstance(key, str) and isinstance(value, str)
            for key, value in fingerprints.items()
        ):
            raise ValueError("authorized_fingerprints must map fingerprints to device names")

    contents = template.read_text() + "\n[authorized_fingerprints]\n"
    for fingerprint, name in sorted(fingerprints.items()):
        contents += (
            f"{json.dumps(fingerprint, ensure_ascii=False)} = "
            f"{json.dumps(name, ensure_ascii=False)}\n"
        )
    tomllib.loads(contents)

    destination.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", encoding="utf-8", dir=destination.parent, delete=False
        ) as output:
            temporary = Path(output.name)
            output.write(contents)
        os.replace(temporary, destination)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


if __name__ == "__main__":
    prepare(Path(sys.argv[1]), Path(sys.argv[2]))
