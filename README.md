# Hosts

- `atlas`: ASUS PRIME Z690-P WIFI D4, Intel i7-12700K, NVIDIA RTX 3060 Ti.
- `zephyrus`: ROG Zephyrus G16, AMD integrated graphics and NVIDIA RTX 4060
  Mobile, with its newly installed encrypted SSD.

Both hosts use the shared apps and Hyprland configuration, including Jellyfin.
Atlas uses Intel microcode and NVIDIA directly. Zephyrus retains its AMD GPU
selection, NVIDIA PRIME bus IDs, ASUS daemon, TLP and laptop power settings.

Both automatically log in as `paul` on tty1 once per boot and start Hyprland
from the Zsh login profile. No display/login manager is enabled. The LUKS
password prompt remains. Other TTYs remain available for recovery.

Atlas retains Philips at `0x0` and KTC at `1920x0`, both 1920x1080 at 75 Hz,
with the existing scale and color settings. It selects monitors by description,
so different HDMI/DisplayPort connector names do not require edits. Atlas has
no internal-panel rule or Super+U panel-focus binding. If an adapter changes
the descriptions, adjust them after checking `hyprctl monitors all`.
Zephyrus keeps its original three-display profile.

## Install the prepared Zephyrus configuration

The laptop hardware file describes the new SSD:

- Encrypted root: `ce41c749-af9f-430e-8b52-a04d76b0b41c`.
- EFI partition: `4C4A-872A`.
- Encrypted swap: `beb7d44b-251f-4e68-914d-1743e9f48580`.

The installer put the swap unlock declaration in `/etc/nixos/configuration.nix`,
separately from its generated hardware file. This repo includes that declaration
and the resume device, preserving the installed swap partition for hibernation.
Zephyrus keeps the fresh installation's `system.stateVersion = "25.11"`.
Atlas retains `24.05` for its existing installation.

From the prepared checkout on the laptop:

```bash
cd /home/paul/nixos
sudo nixos-rebuild boot --flake .#zephyrus
sudo reboot
```

Use `boot` initially so the new kernel, graphics driver, initrd and desktop
configuration first run together after reboot. The hostname becomes `zephyrus`.
For subsequent changes use `sudo nixos-rebuild switch --flake .#zephyrus`.

## Migrate the existing SSD to Atlas

1. Update the **Linux** checkout at `/home/paul/nixos` with the committed changes.
   The Windows checkout at `C:\Users\paul\nixos` is separate. Pull the changes
   under NixOS using Git, or transfer the files preserving their paths.
2. Boot NixOS, unlock LUKS and log in in the TTY. Use Ctrl+Alt+F2 if necessary.
   Connect the displays to the RTX 3060 Ti's ports. Use `nmtui` for Wi-Fi.
3. Check `lsblk -f`, `findmnt /` and `findmnt /boot` against
   `hosts/atlas/hardware-configuration.nix`. Atlas still describes the SSD moved
   from the laptop: encrypted root `6703cce4-a14d-477a-8388-c62b4fb61759`,
   EFI `A291-69A9`, and the existing 32 GiB swap file. If they differ, update
   Atlas's hardware file before rebuilding.
4. Build and install the Atlas configuration:

   ```bash
   cd /home/paul/nixos
   sudo nixos-rebuild build --flake .#atlas
   sudo nixos-rebuild boot --flake .#atlas
   sudo reboot
   ```

5. Check `hostname`, `nvidia-smi` and `hyprctl monitors all` after boot.
   Future updates use `sudo nixos-rebuild switch --flake .#atlas`.

Files transferred without a Git commit must be added with `git add` if they
are new: Git-backed flakes omit untracked files. Keep the existing `flake.lock`
when migrating; updating all dependencies is a separate operation.

Atlas uses ordinary suspend. Zephyrus uses suspend-then-hibernate.

## Chromium extensions

`modules/home/chromium-extensions.json` pins each extension's CRX download,
version and SHA-256 hash. Builds use those exact packages instead of a mutable
Web Store update endpoint. To update the pins intentionally:

```bash
cd /home/paul/nixos
browser_version=$(nix eval --raw .#nixosConfigurations.zephyrus.config.home-manager.users.paul.programs.chromium.package.version)
nix-shell -p python3 --run "python3 scripts/update-chromium-extensions.py $browser_version"
git diff -- modules/home/chromium-extensions.json
```

The updater reads each downloaded manifest and CRX extension ID. It only writes
the pins after all downloads succeed. Classic uBlock Origin uses the signed CRX
from its developer's GitHub releases; its ID is `fkgkibajhfbepljeaefdnfnegdcjomkh`,
which differs from the old Web Store ID. Existing settings under the old ID may
need to be exported and imported when migrating an existing Chromium profile.

## Optional Otark certificate

A fresh clone builds without the Otark root CA. When available, place the real
public PEM certificate at `certificates/otark-root-ca.crt`, add it to Git and
rebuild. It will be installed in both the system trust bundle and Zen's
certificate policy. Do not commit private keys.

The absolute-path `otark-ca` flake input and the empty `local/otark-ca` workaround
are no longer required. Otark services that need this CA will remain untrusted
until the real certificate is supplied.

## If the desktop fails

Use Ctrl+Alt+F2 and log in:

```bash
hostname
systemctl --failed
journalctl -b -u getty@tty1 --no-pager
journalctl -b -k --no-pager | grep -Ei 'nvidia|drm|firmware|failed'
nvidia-smi
Hyprland
```

The last command starts Hyprland manually and prints its errors. Select a
previous generation in the boot menu if the new generation cannot boot.

## A future fresh installation

Clone this repo after installing NixOS with encryption. Generate the hardware
configuration on that machine and update **only its host's** hardware file.
Also carry over any installer-specific storage declarations from
`/etc/nixos/configuration.nix`, including encrypted swap unlocks and resume
settings. Preserve LUKS password retries and use the fresh installation's
`system.stateVersion`; do not change the existing other host's value.

Stage new files, build the selected host and install it for the next boot:

```bash
sudo nixos-rebuild build --flake .#zephyrus
sudo nixos-rebuild boot --flake .#zephyrus
sudo reboot
```

Use `.#atlas` on the PC. Do not copy Atlas's Intel/NVIDIA hardware configuration
onto the laptop, or the laptop's SSD UUIDs onto Atlas.
