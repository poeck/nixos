#!/usr/bin/env python3
"""Exercise the shutdown guard in an isolated unit directory, without power actions."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


class GuardTests(unittest.TestCase):
    def test_enable_disable_preserves_other_dropins_and_power_actions(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            marker = root / 'remote-enabled'
            units = root / 'units'
            binary = root / 'bin'
            binary.mkdir()
            log = root / 'reloads'
            systemctl = binary / 'systemctl'
            systemctl.write_text('#!/bin/sh\n[ "$*" = daemon-reload ] || exit 99\nprintf reload\\\\n >> "$GUARD_TEST_LOG"\n')
            systemctl.chmod(0o755)
            env = dict(os.environ, PATH=f'{binary}:{os.environ["PATH"]}', GUARD_TEST_LOG=str(log))
            other = units / 'poweroff.target.d' / 'other.conf'
            other.parent.mkdir(parents=True)
            other.write_text('[Unit]\nDescription=Keep me\n')
            script = Path(__file__).with_name('atlas-remote-power-guard.sh')
            def sync():
                subprocess.run(['bash', str(script), str(marker), str(units)], env=env, check=True)
            sync()
            self.assertFalse(log.exists())
            marker.touch()
            sync()
            first = log.read_bytes()
            for name in ('poweroff', 'halt'):
                self.assertEqual((units / f'{name}.target.d/90-atlas-remote-guard.conf').read_text(), '[Unit]\nRefuseManualStart=yes\n')
            self.assertFalse((units / 'reboot.target.d').exists())
            self.assertFalse((units / 'suspend.target.d').exists())
            sync()
            self.assertEqual(log.read_bytes(), first)
            marker.unlink()
            sync()
            self.assertEqual(other.read_text(), '[Unit]\nDescription=Keep me\n')
            self.assertFalse((units / 'halt.target.d').exists())
            self.assertFalse((other.parent / '90-atlas-remote-guard.conf').exists())
            second = log.read_bytes()
            self.assertNotEqual(first, second)
            sync()
            self.assertEqual(log.read_bytes(), second)


if __name__ == '__main__':
    unittest.main()
