#!/usr/bin/env python3
"""Failure-path checks for the display switch; live tests cover real Hyprland."""

import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


spec = importlib.util.spec_from_file_location(
    "atlas_remote", Path(__file__).with_name("atlas-remote.py")
)
remote = importlib.util.module_from_spec(spec)
spec.loader.exec_module(remote)


class RecoveryTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        environment = patch.dict(
            os.environ,
            {
                "XDG_RUNTIME_DIR": self.temporary.name,
                "HYPRLAND_INSTANCE_SIGNATURE": "test-session",
            },
        )
        environment.start()
        self.addCleanup(environment.stop)
        self.desktop = remote.Desktop()

    def enable_marker(self):
        self.desktop.write(self.desktop.marker, "test-session\n")

    def test_a_new_compositor_session_never_inherits_remote_mode(self):
        self.desktop.write(self.desktop.marker, "old-session\n")
        self.desktop.write(self.desktop.state_file, json.dumps({"session": "old-session"}))
        self.assertFalse(self.desktop.enabled)
        self.assertEqual(self.desktop.state(), {})

    def test_unavailable_physical_displays_keep_the_remote_recovery_output(self):
        self.enable_marker()
        with (
            patch.object(remote, "hypr"),
            patch.object(
                self.desktop, "wait_for", side_effect=remote.RemoteError("unplugged")
            ),
            patch.object(self.desktop, "apply_remote") as restore,
        ):
            with self.assertRaisesRegex(remote.RemoteError, "unplugged"):
                self.desktop.off()
        self.assertTrue(self.desktop.enabled)
        restore.assert_called_once()

    def test_failed_virtual_output_creation_restores_local_mode(self):
        local_monitor = {"name": "DP-2"}
        with (
            patch.object(self.desktop, "monitors", return_value=[local_monitor]),
            patch.object(remote, "hypr", return_value=[]),
            patch.object(remote, "run", return_value=subprocess.CompletedProcess([], 0)),
            patch.object(
                self.desktop, "ensure_virtual", side_effect=remote.RemoteError("create failed")
            ),
            patch.object(self.desktop, "off") as restore,
        ):
            with self.assertRaisesRegex(remote.RemoteError, "create failed"):
                self.desktop.on()
        restore.assert_called_once()
        self.assertFalse(self.desktop.enabled)

    def test_idle_display_timeout_does_not_black_out_the_virtual_display(self):
        self.enable_marker()
        with (
            patch.object(remote, "dispatch") as dispatch,
            patch.object(self.desktop, "apply_remote") as apply,
        ):
            self.desktop.dpms("disable")
            dispatch.assert_not_called()
            apply.assert_not_called()
            self.desktop.dpms("enable")
            apply.assert_called_once()

    def test_sunshine_never_falls_back_to_a_physical_monitor_in_remote_mode(self):
        self.enable_marker()
        with (
            patch.object(self.desktop, "monitors", return_value=[{"name": "DP-2"}]),
            patch.object(os, "execv") as execute,
        ):
            with self.assertRaisesRegex(remote.RemoteError, "Remote output is missing"):
                self.desktop.sunshine("/sunshine", "/config")
            execute.assert_not_called()

    def test_local_sunshine_uses_the_aoc_even_when_philips_is_first(self):
        monitors = [
            {"name": "HDMI-A-1", "description": "Philips"},
            {"name": "DP-2", "description": "AOC Q27G4ZR serial"},
        ]
        with (
            patch.object(self.desktop, "monitors", return_value=monitors),
            patch.object(os, "execv") as execute,
        ):
            self.desktop.sunshine("/sunshine", "/config")
        execute.assert_called_once_with("/sunshine", ["/sunshine", "/config", "output_name=DP-2"])


if __name__ == "__main__":
    unittest.main()
