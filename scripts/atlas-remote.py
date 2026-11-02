#!/usr/bin/env python3
"""Switch an existing Atlas Hyprland session between local and remote displays."""

import argparse
import contextlib
import fcntl
import json
import os
from pathlib import Path
import subprocess
import sys
import time


OUTPUT = "ATLAS-REMOTE"
MODE = "1920x1200@60"
MANAGER = "hyprdynamicmonitors.service"


class RemoteError(Exception):
    pass


def run(*args, check=True):
    result = subprocess.run(args, text=True, capture_output=True, timeout=30)
    if check and result.returncode:
        raise RemoteError(result.stderr.strip() or result.stdout.strip() or str(args))
    return result


def hypr(*args, json_output=False):
    result = run("hyprctl", *(["-j"] if json_output else []), *args)
    if json_output:
        try:
            return json.loads(result.stdout)
        except ValueError as error:
            raise RemoteError("Cannot reach the active Hyprland session.") from error
    # Hyprctl can return a Lua/config error with exit status zero.
    if result.stdout.strip() != "ok":
        raise RemoteError(result.stdout.strip() or "Hyprland rejected the command.")


def lua_string(value):
    return json.dumps(str(value), ensure_ascii=False)


def evaluate(code):
    hypr("eval", code)


def dispatch(expression):
    hypr("dispatch", expression)


def import_session():
    os.environ.setdefault("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    # SSH and systemd callers need the compositor's actual environment. Import
    # only display variables, never credentials or a caller's entire environment.
    result = run("systemctl", "--user", "show-environment")
    for line in result.stdout.splitlines():
        key, _, value = line.partition("=")
        if key in ("HYPRLAND_INSTANCE_SIGNATURE", "WAYLAND_DISPLAY", "DISPLAY"):
            os.environ[key] = value
    if not os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
        raise RemoteError("No active Hyprland session was found.")


class Desktop:
    def __init__(self):
        self.session = os.environ["HYPRLAND_INSTANCE_SIGNATURE"]
        self.directory = Path(os.environ["XDG_RUNTIME_DIR"]) / "atlas-remote"
        self.directory.mkdir(mode=0o700, exist_ok=True)
        self.marker = self.directory / "enabled"
        self.state_file = self.directory / "state.json"
        self.layout_file = self.directory / "monitors.lua"

    @property
    def enabled(self):
        try:
            return self.marker.read_text().strip() == self.session
        except FileNotFoundError:
            return False

    @contextlib.contextmanager
    def locked(self):
        with (self.directory / "control.lock").open("a") as lock:
            # Never wait indefinitely behind a failed switch, especially via SSH.
            deadline = time.monotonic() + 35
            while True:
                try:
                    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
                    break
                except BlockingIOError:
                    if time.monotonic() > deadline:
                        raise RemoteError("Another display switch is still running.")
                    time.sleep(0.1)
            yield

    def write(self, path, text):
        temporary = path.with_suffix(path.suffix + ".tmp")
        temporary.write_text(text)
        temporary.chmod(0o600)
        temporary.replace(path)

    def state(self):
        try:
            state = json.loads(self.state_file.read_text())
        except (FileNotFoundError, ValueError):
            return {}
        return state if state.get("session") == self.session else {}

    def monitors(self, all_outputs=False):
        return hypr("monitors", *(["all"] if all_outputs else []), json_output=True)

    def virtual_exists(self):
        return any(m["name"] == OUTPUT for m in self.monitors(all_outputs=True))

    def ensure_virtual(self):
        if not self.virtual_exists():
            hypr("output", "create", "headless", OUTPUT)
        evaluate(
            f"hl.monitor({{ output = {lua_string(OUTPUT)}, disabled = false, "
            f"mode = {lua_string(MODE)}, position = 'auto', scale = 1 }})"
        )
        self.wait_for(lambda: any(m["name"] == OUTPUT for m in self.monitors()))

    @staticmethod
    def wait_for(predicate):
        for _ in range(40):
            if predicate():
                return
            time.sleep(0.1)
        raise RemoteError("The requested monitor layout did not become active.")

    def remote_layout(self):
        # Exact output rules take precedence over the wildcard. The wildcard
        # also keeps a physical monitor reconnected during remote use disabled.
        return (
            'hl.monitor({ output = "", disabled = true })\n'
            f"hl.monitor({{ output = {lua_string(OUTPUT)}, disabled = false, "
            f"mode = {lua_string(MODE)}, position = '0x0', scale = 1 }})\n"
        )

    def apply_remote(self):
        self.ensure_virtual()
        evaluate(self.remote_layout())
        dispatch(f"hl.dsp.dpms({{ monitor = {lua_string(OUTPUT)}, action = 'enable' }})")
        self.wait_for(lambda: [m["name"] for m in self.monitors()] == [OUTPUT])

    def restart_sunshine(self):
        run("systemctl", "--user", "reset-failed", "sunshine.service", check=False)
        run("systemctl", "--user", "restart", "sunshine.service")

    def on(self):
        if self.enabled:
            self.apply_remote()
            self.restart_sunshine()
            return
        monitors = [m for m in self.monitors() if m["name"] != OUTPUT]
        if not monitors:
            raise RemoteError("No local monitor layout is available to save.")
        state = {
            "session": self.session,
            "monitors": monitors,
            "workspaces": [
                {key: workspace[key] for key in ("id", "name", "monitor")}
                for workspace in hypr("workspaces", json_output=True)
            ],
            "manager_active": run(
                "systemctl", "--user", "is-active", "--quiet", MANAGER, check=False
            ).returncode == 0,
        }
        self.write(self.state_file, json.dumps(state))
        try:
            # Create and verify the destination before touching real outputs.
            self.ensure_virtual()
            run("systemctl", "--user", "stop", MANAGER)
            self.write(self.layout_file, self.remote_layout())
            self.write(self.marker, self.session + "\n")
            hypr("reload")
            self.apply_remote()
            # Removing a monitor migrates its existing workspaces. The rule also
            # directs newly created workspaces to the sole remaining output.
            dispatch(f"hl.dsp.focus({{ monitor = {lua_string(OUTPUT)} }})")
            for monitor in monitors:
                if monitor.get("focused"):
                    dispatch(
                        "hl.dsp.focus({ workspace = "
                        + lua_string(monitor["activeWorkspace"]["id"])
                        + " })"
                    )
            self.restart_sunshine()
        except Exception:
            try:
                self.off()
            except Exception as rollback_error:
                print(f"Automatic restore needs attention: {rollback_error}", file=sys.stderr)
            raise

    @staticmethod
    def monitor_rule(monitor):
        refresh = monitor.get("refreshRate", 60)
        depth = 10 if "2101010" in monitor.get("currentFormat", "") else 8
        return (
            f"hl.monitor({{ output = {lua_string(monitor['name'])}, disabled = false, "
            f"mode = '{monitor['width']}x{monitor['height']}@{refresh}', "
            f"position = '{monitor['x']}x{monitor['y']}', scale = {monitor['scale']}, "
            f"transform = {monitor.get('transform', 0)}, "
            f"vrr = {1 if monitor.get('vrr') else 0}, bitdepth = {depth} }})"
        )

    def off(self):
        state = self.state()
        was_remote = self.enabled
        self.marker.unlink(missing_ok=True)
        try:
            hypr("reload")
            for monitor in state.get("monitors", []):
                evaluate(self.monitor_rule(monitor))
            self.wait_for(lambda: any(m["name"] != OUTPUT for m in self.monitors()))
        except Exception:
            # Keep the remote destination reachable if all real displays are
            # unavailable or a local configuration fails to restore.
            if was_remote:
                self.write(self.marker, self.session + "\n")
                self.apply_remote()
            raise

        available = {m["name"] for m in self.monitors()}
        live_workspaces = {w["id"] for w in hypr("workspaces", json_output=True)}
        for workspace in state.get("workspaces", []):
            if workspace["id"] not in live_workspaces or workspace["monitor"] not in available:
                continue
            selector = workspace["name"] if workspace["id"] < 0 else workspace["id"]
            dispatch(
                f"hl.dsp.workspace.move({{ workspace = {lua_string(selector)}, "
                f"monitor = {lua_string(workspace['monitor'])} }})"
            )
        for monitor in state.get("monitors", []):
            if monitor["name"] not in available:
                continue
            workspace = monitor["activeWorkspace"]["id"]
            if workspace in live_workspaces:
                dispatch(f"hl.dsp.focus({{ workspace = {lua_string(workspace)} }})")
        for monitor in state.get("monitors", []):
            if monitor.get("focused") and monitor["name"] in available:
                dispatch(f"hl.dsp.focus({{ monitor = {lua_string(monitor['name'])} }})")

        if self.virtual_exists():
            hypr("output", "remove", OUTPUT)
        dispatch("hl.dsp.dpms({ action = 'enable' })")
        if state.get("manager_active", True):
            run("systemctl", "--user", "start", MANAGER)
        self.restart_sunshine()
        self.state_file.unlink(missing_ok=True)
        self.layout_file.unlink(missing_ok=True)

    def dpms(self, action):
        if self.enabled:
            # A virtual output must keep rendering for a new Moonlight client.
            # Screen lock and the existing suspend timer remain independent.
            if action == "enable":
                self.apply_remote()
        else:
            dispatch(f"hl.dsp.dpms({{ action = {lua_string(action)} }})")

    def sunshine(self, executable, config_file):
        # No control lock: on/off waits for systemctl restart, which starts us.
        # The switching process has already established and verified the output.
        monitors = self.monitors()
        if self.enabled:
            if not any(m["name"] == OUTPUT for m in monitors):
                raise RemoteError("Remote output is missing; run atlas-remote on over SSH.")
            output = OUTPUT
        else:
            physical = [m for m in monitors if m["name"] != OUTPUT]
            preferred = [m for m in physical if "AOC Q27G4ZR" in m.get("description", "")]
            if not physical:
                raise RemoteError("No active local display was found.")
            output = (preferred or physical)[0]["name"]
        os.execv(executable, [executable, config_file, f"output_name={output}"])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "action",
        choices=("on", "off", "toggle", "status", "local", "dpms", "sunshine"),
    )
    parser.add_argument("arguments", nargs="*")
    args = parser.parse_args()
    required = {"dpms": 1, "sunshine": 2}.get(args.action, 0)
    if len(args.arguments) != required:
        parser.error(f"{args.action} expects {required} argument(s)")
    if args.action == "dpms" and args.arguments[0] not in ("enable", "disable"):
        parser.error("dpms expects enable or disable")
    import_session()
    desktop = Desktop()
    if args.action == "local":
        return int(desktop.enabled)
    if args.action == "status":
        print("Remote mode " + ("on" if desktop.enabled else "off"))
        print("Active outputs: " + ", ".join(m["name"] for m in desktop.monitors()))
        return 0
    if args.action == "sunshine":
        desktop.sunshine(*args.arguments)
        return 0
    with desktop.locked():
        if args.action == "dpms":
            desktop.dpms(args.arguments[0])
        elif args.action == "on" or (args.action == "toggle" and not desktop.enabled):
            desktop.on()
        else:
            desktop.off()
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (RemoteError, subprocess.TimeoutExpired) as error:
        print(f"atlas-remote: {error}", file=sys.stderr)
        sys.exit(1)
