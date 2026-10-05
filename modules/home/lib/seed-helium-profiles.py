"""Seed Helium profiles and apply extension exclusions while Helium is stopped."""

import json
import os
from pathlib import Path
import sys
import tempfile


def browser_running(user_data_dir: Path) -> bool:
    try:
        pid = int(os.readlink(user_data_dir / "SingletonLock").rsplit("-", 1)[1])
        if pid <= 0:
            return True
        os.kill(pid, 0)
    except (FileNotFoundError, ProcessLookupError):
        return False
    except (OSError, ValueError, IndexError):
        # An unknown lock must not cause us to edit a potentially live profile.
        return True
    return True


def exclude_extensions(profile_dir: Path, excluded_ids: list[str]) -> None:
    if not excluded_ids:
        return
    preferences_path = profile_dir / "Preferences"
    original = preferences_path.read_text()
    preferences = json.loads(original)
    extensions = preferences.setdefault("extensions", {})
    uninstalled = extensions.setdefault("external_uninstalls", [])
    settings = extensions.get("settings", {})
    pending = [id for id in excluded_ids if id not in uninstalled or id in settings]
    if not pending:
        return
    if browser_running(profile_dir.parent):
        print("Helium läuft: Extension-Ausschlüsse werden beim nächsten Start nach "
              "vollständigem Beenden angewendet.", file=sys.stderr)
        return

    secure_path = profile_dir / "Secure Preferences"
    secure = json.loads(secure_path.read_text()) if secure_path.exists() else {}
    protected = secure.get("extensions", {}).get("settings", {})
    if any(id in protected for id in pending):
        raise RuntimeError("Extension-Einstellungen sind geschützt; bitte die "
                           "ausgeschlossenen Extensions im Profil manuell entfernen.")
    for id in pending:
        if id not in uninstalled:
            uninstalled.append(id)
        settings.pop(id, None)

    # Keep a private rollback copy and replace the updated JSON atomically.
    backup = profile_dir / "Preferences.before-nix-extension-exclusions"
    try:
        fd = os.open(backup, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    except FileExistsError:
        pass
    else:
        with os.fdopen(fd, "w") as handle:
            handle.write(original)
    fd, temporary = tempfile.mkstemp(prefix=".Preferences-", dir=profile_dir)
    try:
        with os.fdopen(fd, "w") as handle:
            json.dump(preferences, handle)
            handle.write("\n")
        os.replace(temporary, preferences_path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def seed_profiles(defaults_path: Path, user_data_dir: Path) -> None:
    defaults = json.loads(defaults_path.read_text())
    for name, preferences in defaults.items():
        if name in {"", ".", ".."} or Path(name).name != name:
            raise ValueError(f"Invalid profile directory: {name!r}")
        profile_dir = user_data_dir / name
        profile_dir.mkdir(parents=True, exist_ok=True, mode=0o700)
        preferences_path = profile_dir / "Preferences"
        try:
            fd = os.open(preferences_path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        except FileExistsError:
            exclude_extensions(
                profile_dir,
                preferences.get("extensions", {}).get("external_uninstalls", []),
            )
            continue
        with os.fdopen(fd, "w") as handle:
            json.dump(preferences, handle)
            handle.write("\n")


if __name__ == "__main__":
    seed_profiles(Path(sys.argv[1]), Path(sys.argv[2]))
