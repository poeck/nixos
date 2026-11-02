#!/usr/bin/env python3
"""Check update routing and preservation of CLI pins on release errors."""

from contextlib import ExitStack
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


spec = importlib.util.spec_from_file_location(
    "update_system", Path(__file__).with_name("update-system.py"),
)
updater = importlib.util.module_from_spec(spec)
spec.loader.exec_module(updater)


class UpdateSystemTests(unittest.TestCase):
    version = "0.1.1-nightly.20261018.3302"

    def release(self):
        return {
            "tag_name": f"v{self.version}",
            "draft": False,
            "assets": [
                {
                    "name": f"t3-{self.version}-linux-{arch}.tar.gz",
                    "digest": "sha256:" + "00" * 32,
                }
                for arch in ("x64", "arm64")
            ],
        }

    def test_sync_uses_locked_release_and_is_idempotent(self):
        with tempfile.TemporaryDirectory() as directory, ExitStack() as stack:
            output = Path(directory) / "release.json"
            stack.enter_context(patch.object(updater, "OUTPUT", output))
            stack.enter_context(patch.object(
                updater.subprocess, "check_output", return_value=self.version,
            ))
            fetch = stack.enter_context(patch.object(updater.urllib.request, "urlopen"))
            for attempt in range(2):
                fetch.return_value = io.BytesIO(json.dumps(self.release()).encode())
                updater.sync_t3()
                if attempt == 0:
                    initial_mtime = output.stat().st_mtime_ns
            self.assertEqual(output.stat().st_mtime_ns, initial_mtime)
            self.assertEqual(fetch.call_args.args[0].full_url, updater.API + f"v{self.version}")
            metadata = json.loads(output.read_text())
            self.assertEqual(metadata["version"], self.version)
            self.assertEqual(set(metadata["releases"]), {"x86_64-linux", "aarch64-linux"})
            self.assertEqual(
                metadata["releases"]["x86_64-linux"]["hash"],
                "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
            )

    def test_invalid_releases_preserve_previous_pins(self):
        wrong_tag = self.release()
        wrong_tag["tag_name"] = "v99.0.0"
        missing_arm = self.release()
        missing_arm["assets"].pop()
        missing_digest = self.release()
        missing_digest["assets"][1]["digest"] = None
        for release in (wrong_tag, missing_arm, missing_digest):
            with self.subTest(release=release), tempfile.TemporaryDirectory() as directory:
                output = Path(directory) / "release.json"
                output.write_text("previous pins")
                with patch.object(updater, "OUTPUT", output), patch.object(
                    updater.subprocess, "check_output", return_value=self.version,
                ), patch.object(
                    updater.urllib.request, "urlopen",
                    return_value=io.BytesIO(json.dumps(release).encode()),
                ), self.assertRaises(ValueError):
                    updater.sync_t3()
                self.assertEqual(output.read_text(), "previous pins")

    def test_update_modes(self):
        for args, inputs in (([], []), (["t3code"], ["t3code"]), (["--sync-t3-only"], None)):
            with self.subTest(args=args), patch("sys.argv", ["update-system.py", *args]), patch.object(
                updater.subprocess, "run",
            ) as run, patch.object(updater, "sync_t3") as sync:
                updater.main()
                if inputs is None:
                    run.assert_not_called()
                else:
                    run.assert_called_once_with(
                        ["nix", "flake", "update", *inputs], cwd=updater.ROOT, check=True,
                    )
                sync.assert_called_once_with()

    def test_failed_input_update_does_not_sync(self):
        with patch("sys.argv", ["update-system.py"]), patch.object(
            updater.subprocess, "run",
            side_effect=updater.subprocess.CalledProcessError(1, "nix"),
        ), patch.object(updater, "sync_t3") as sync, self.assertRaises(
            updater.subprocess.CalledProcessError,
        ):
            updater.main()
        sync.assert_not_called()


if __name__ == "__main__":
    unittest.main()
