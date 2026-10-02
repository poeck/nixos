#!/usr/bin/env python3
"""Pin Chromium extensions to immutable CRX URLs, versions, and SHA-256 hashes."""

import argparse
import base64
from concurrent.futures import ThreadPoolExecutor
import hashlib
import io
import json
from pathlib import Path
import struct
import urllib.parse
import urllib.request
import zipfile


def protobuf_fields(data):
    offset = 0

    def varint():
        nonlocal offset
        value, shift = 0, 0
        while True:
            byte = data[offset]
            offset += 1
            value |= (byte & 127) << shift
            if byte < 128:
                return value
            shift += 7

    fields = {}
    while offset < len(data):
        tag = varint()
        wire = tag & 7
        if wire == 2:
            size = varint()
            fields[tag >> 3] = data[offset:offset + size]
            offset += size
        elif wire == 0:
            varint()
        elif wire in (1, 5):
            offset += 8 if wire == 1 else 4
        else:
            raise ValueError("Unsupported CRX header field")
    return fields


def crx_extension_id(data):
    version = struct.unpack_from("<I", data, 4)[0]
    if version == 3:
        size = struct.unpack_from("<I", data, 8)[0]
        signed_header = protobuf_fields(data[12:12 + size])[10000]
        key_id = protobuf_fields(signed_header)[1]
    elif version == 2:
        key_size = struct.unpack_from("<I", data, 8)[0]
        key_id = hashlib.sha256(data[16:16 + key_size]).digest()[:16]
    else:
        raise ValueError(f"Unsupported CRX version {version}")
    if len(key_id) != 16:
        raise ValueError("Invalid CRX extension ID")
    return "".join(chr(97 + int(digit, 16)) for digit in key_id.hex())


def fetch_extension(extension, browser_version):
    query = urllib.parse.urlencode({
        "response": "redirect",
        "acceptformat": "crx2,crx3",
        "prodversion": browser_version,
        "prod": "chromiumcrx",
        "x": f"id={extension['id']}&installsource=ondemand&uc",
    })
    source = extension.get("source", "chrome-web-store")
    fixed_url = None
    if source == "github:gorhill/uBlock":
        release_request = urllib.request.Request(
            "https://api.github.com/repos/gorhill/uBlock/releases/latest",
            headers={"User-Agent": "nixos-chromium-extension-updater"},
        )
        with urllib.request.urlopen(release_request, timeout=90) as response:
            release = json.load(response)
        fixed_url = next(
            asset["browser_download_url"] for asset in release["assets"]
            if asset["name"].endswith(".chromium.crx")
        )
    request = urllib.request.Request(
        fixed_url or "https://clients2.google.com/service/update2/crx?" + query,
        headers={"User-Agent": "Mozilla/5.0"},
    )
    with urllib.request.urlopen(request, timeout=90) as response:
        data = response.read()
        url = fixed_url or response.geturl()
    if not data.startswith(b"Cr24"):
        raise ValueError(f"{extension['name']}: Google did not return a CRX package ({len(data)} bytes, {data[:100]!r})")
    if "service/update2/crx" in url:
        raise ValueError(f"{extension['name']}: update URL did not resolve to a fixed download")
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        manifest = json.loads(archive.read("manifest.json"))
    extension_id = crx_extension_id(data)
    if source == "chrome-web-store" and extension_id != extension["id"]:
        raise ValueError(f"{extension['name']}: downloaded CRX has an unexpected ID")
    result = {
        "name": extension["name"],
        "id": extension_id,
        "url": url,
        "sha256": "sha256-" + base64.b64encode(hashlib.sha256(data).digest()).decode(),
        "version": manifest["version"],
    }
    if source != "chrome-web-store":
        result["source"] = source
    print(f"{result['name']}: {result['version']}", flush=True)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("browser_version", help="Version of the configured Chromium package")
    parser.add_argument(
        "--manifest",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "modules/home/chromium-extensions.json",
    )
    args = parser.parse_args()
    extensions = json.loads(args.manifest.read_text())
    with ThreadPoolExecutor(max_workers=4) as pool:
        futures = [pool.submit(fetch_extension, ext, args.browser_version) for ext in extensions]
        results, errors = [], []
        for future in futures:
            try:
                results.append(future.result())
            except Exception as error:
                errors.append(str(error))
    if errors:
        raise SystemExit("\n".join(errors))
    # Write only after every download succeeds, preserving the previous pins on failure.
    args.manifest.write_text(json.dumps(results, indent=2) + "\n")


if __name__ == "__main__":
    main()
