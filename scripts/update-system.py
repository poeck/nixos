#!/usr/bin/env python3
"""Update flake inputs and pin the T3 CLI to the locked desktop release."""

import argparse
import base64
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import urllib.parse
import urllib.request


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "pkgs/t3-cli-release.json"
ARCHES = {"x86_64-linux": "x64", "aarch64-linux": "arm64"}
API = "https://api.github.com/repos/pingdotgg/t3code/releases/tags/"


def release_metadata(version, release):
    tag = f"v{version}"
    if release["tag_name"] != tag or release["draft"]:
        raise ValueError(f"Expected published release {tag}")
    assets = {asset["name"]: asset for asset in release["assets"]}
    releases = {}
    for system, arch in ARCHES.items():
        filename = f"t3-{version}-linux-{arch}.tar.gz"
        asset = assets.get(filename)
        if asset is None:
            raise ValueError(f"{tag}: missing {filename}")
        digest = asset.get("digest") or ""
        if not re.fullmatch(r"sha256:[0-9a-f]{64}", digest):
            raise ValueError(f"{tag}: missing SHA-256 digest for {filename}")
        releases[system] = {
            "arch": arch,
            "hash": "sha256-" + base64.b64encode(
                bytes.fromhex(digest.removeprefix("sha256:"))
            ).decode("ascii"),
        }
    return {"version": version, "releases": releases}


def sync_t3():
    # Read only the input, so the existing version assertion cannot block updates.
    version = subprocess.check_output(
        [
            "nix", "eval", "--raw", "--impure", "--expr",
            '(builtins.getFlake (toString ./.)).inputs.t3code.packages.'
            '${builtins.currentSystem}.nightly.version',
        ],
        cwd=ROOT,
        text=True,
    ).strip()
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": "nixos-t3-cli-updater",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    if token := os.environ.get("GITHUB_TOKEN"):
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(
        API + urllib.parse.quote(f"v{version}", safe=""), headers=headers,
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        metadata = release_metadata(version, json.load(response))
    updated = json.dumps(metadata, indent=2) + "\n"
    if OUTPUT.exists() and OUTPUT.read_text() == updated:
        print(f"T3 CLI already matches desktop {version}", flush=True)
        return
    # Validate both architectures before atomically replacing the previous pins.
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", dir=OUTPUT.parent, delete=False,
        ) as output:
            temporary = Path(output.name)
            output.write(updated)
        temporary.chmod(0o644)
        temporary.replace(OUTPUT)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
    print(f"Pinned T3 CLI to desktop {version}", flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("inputs", nargs="*", help="Specific flake inputs (default: all)")
    parser.add_argument(
        "--sync-t3-only", action="store_true",
        help="Repair CLI pins for the existing flake.lock without updating inputs",
    )
    args = parser.parse_args()
    if args.sync_t3_only and args.inputs:
        parser.error("--sync-t3-only cannot be combined with input names")
    if not args.sync_t3_only:
        subprocess.run(["nix", "flake", "update", *args.inputs], cwd=ROOT, check=True)
    sync_t3()
    print("Ready to rebuild: nh os switch", flush=True)


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError) as error:
        raise SystemExit(
            f"Update failed: {error}\n"
            "T3 CLI pins were not replaced. After resolving the error, retry with "
            "--sync-t3-only if flake.lock was already updated."
        ) from error
