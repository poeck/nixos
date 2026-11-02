#!/usr/bin/env python3
"""Prepare Atlas's root-only early-boot WLAN profile and dedicated SSH host key."""

import hashlib
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile


DIRECTORY = Path("/etc/secrets/initrd/atlas")
INTERFACE = "wlo1"
SSID = "FRITZ!Box 7583 LM"
MAC = "00:91:9e:c0:c5:51"


def command(*args):
    # Some commands return the PSK. Capture it without echoing it or placing it
    # in process arguments, shell history, log messages or exception output.
    result = subprocess.run(args, text=True, capture_output=True, timeout=30)
    if result.returncode:
        raise RuntimeError(f"{args[0]} failed; no secret output has been printed.")
    return result.stdout.rstrip("\n")


def wpa_profile(ssid, password):
    ssid_bytes = ssid.encode("utf-8")
    if not 1 <= len(ssid_bytes) <= 32:
        raise ValueError("Invalid WLAN SSID length.")
    if re.fullmatch(r"[0-9a-fA-F]{64}", password):
        psk = password.lower()
    elif 8 <= len(password.encode("utf-8")) <= 63:
        psk = hashlib.pbkdf2_hmac(
            "sha1", password.encode("utf-8"), ssid_bytes, 4096, 32
        ).hex()
    else:
        raise ValueError("The WLAN profile has no usable WPA2 pre-shared key.")
    # Hex-encode the SSID too; quotes and backslashes cannot inject config.
    return (
        "ctrl_interface=/run/wpa_supplicant\n"
        "update_config=0\ncountry=AT\nmac_addr=0\npreassoc_mac_addr=0\n"
        "network={\n"
        f"    ssid={ssid_bytes.hex()}\n"
        f"    psk={psk}\n"
        "    key_mgmt=WPA-PSK\n    proto=RSN\n}\n"
    )


def write_private(path, text):
    descriptor, temporary = tempfile.mkstemp(prefix=".prepare-", dir=path.parent)
    try:
        with os.fdopen(descriptor, "w") as output:
            output.write(text)
            output.flush()
            os.fsync(output.fileno())
        os.replace(temporary, path)
    finally:
        Path(temporary).unlink(missing_ok=True)


def prepare():
    if os.geteuid() != 0:
        raise RuntimeError("Run this command as root with sudo or pkexec.")
    if Path("/etc/hostname").read_text().strip() != "atlas":
        raise RuntimeError("This helper is only for Atlas.")
    if Path(f"/sys/class/net/{INTERFACE}/address").read_text().strip().lower() != MAC:
        raise RuntimeError("Atlas's expected Wi-Fi MAC address is not active.")

    profile = command("nmcli", "-g", "GENERAL.CON-UUID", "device", "show", INTERFACE)
    if not profile or profile == "--":
        raise RuntimeError("Connect Atlas to its home Wi-Fi before preparing initrd.")

    def read_field(name, secret=False):
        return command(
            "nmcli", *(["--show-secrets"] if secret else []),
            "--escape", "no", "-g", name, "connection", "show", profile,
        )

    if read_field("802-11-wireless.ssid") != SSID:
        raise RuntimeError("The current connection is not Atlas's home Wi-Fi.")
    if read_field("802-11-wireless-security.key-mgmt") != "wpa-psk":
        raise RuntimeError("The current connection is not the expected WPA2 profile.")
    config = wpa_profile(SSID, read_field("802-11-wireless-security.psk", secret=True))

    DIRECTORY.mkdir(parents=True, mode=0o700, exist_ok=True)
    DIRECTORY.chmod(0o700)
    write_private(DIRECTORY / "wpa_supplicant.conf", config)
    host_key = DIRECTORY / "ssh_host_ed25519_key"
    if not host_key.exists():
        command("ssh-keygen", "-q", "-t", "ed25519", "-N", "", "-C", "atlas-initrd", "-f", str(host_key))
    host_key.chmod(0o600)
    # Derive the public key on every run, preserving the existing private key.
    public = command("ssh-keygen", "-y", "-f", str(host_key))
    (DIRECTORY / "ssh_host_ed25519_key.pub").write_text(public + "\n")
    print("Prepared root-only WLAN credentials and the dedicated initrd SSH host key.")
    print("Host public key:", public)
    print(command("ssh-keygen", "-lf", str(DIRECTORY / "ssh_host_ed25519_key.pub")))
    print("The LUKS passphrase has not been read or stored.")


if __name__ == "__main__":
    try:
        prepare()
    except (OSError, ValueError, RuntimeError, subprocess.TimeoutExpired) as error:
        print(f"atlas-initrd-prepare: {error}", file=sys.stderr)
        sys.exit(1)
