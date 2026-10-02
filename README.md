# Hosts

- `atlas`: ASUS PRIME Z690-P WIFI D4, Intel i7-12700K, NVIDIA RTX 3060 Ti.
- `zephyrus`: the existing ROG laptop configuration. Files in `hosts/zephyrus`
  remain unchanged; shared modules retain its existing behavior.

Both hosts use the same shared apps and Hyprland configuration, including
Jellyfin. Atlas uses Intel microcode and NVIDIA directly, without the laptop's
AMD GPU selection, PRIME bus IDs, ASUS daemon, or TLP settings.

Atlas automatically logs in as `paul` on tty1 once per boot and starts Hyprland
from the Zsh login profile. No display/login manager is enabled on Atlas. The
LUKS password prompt remains. Other TTYs remain available for recovery.

The Atlas monitor profile retains Philips at `0x0` and KTC at `1920x0`, both
1920x1080 at 75 Hz with scale 1 and the existing color settings. It selects the
monitors by description, so changing HDMI/DisplayPort connector names does not
require edits. Atlas has no internal-panel rule or Super+U panel-focus binding.
If the descriptions change through a different adapter/cable, the automatic
preferred-mode fallback still works; adjust the descriptions after checking
`hyprctl monitors all`. Zephyrus keeps its original three-display profile.

## Migrate the existing SSD to Atlas

1. Transfer these edits from the Windows checkout to the existing Linux checkout
   at `/home/paul/nixos`. Editing `C:\Users\paul\nixos` does not automatically
   update that separate directory. You can commit/push here and pull under
   NixOS, or copy the changed/new files using a USB drive. If using the supplied
   `atlas-config.zip` overlay, extract it into `/home/paul/nixos`, preserving
   paths and your existing ignored `local/otark-ca` directory:

   ```bash
   nix-shell -p unzip --run 'unzip -o /path/to/atlas-config.zip -d /home/paul/nixos'
   ```

2. Boot the existing NixOS entry, unlock LUKS, and log in as `paul` in the TTY.
   Use Ctrl+Alt+F2 if necessary. Connect the displays to the RTX 3060 Ti's ports.
   If you need Wi-Fi from the terminal, use `nmtui`.

3. In the Linux checkout, verify that the migrated SSD uses the UUIDs in
   `hosts/atlas/hardware-configuration.nix`. They are copied from the working
   laptop storage setup: encrypted root UUID
   `6703cce4-a14d-477a-8388-c62b4fb61759`, EFI partition UUID `A291-69A9`.
   Windows cannot verify the Linux mounts. Also check that the existing private
   certificate input is still present; the flake requires it.

   ```bash
   cd /home/paul/nixos
   lsblk -f
   findmnt /
   findmnt /boot
   test -r local/otark-ca/otark-root-ca.crt
   ```

   Do not rebuild if `/` or `/boot` differs from the configured devices: update
   **Atlas's** hardware file first. Do not replace the Zephyrus hardware file.

4. Make new files visible to the Git-backed flake, then build without activating:

   ```bash
   git add hosts/atlas modules/core/media.nix \
     modules/home/hyprland/monitors/atlas.toml \
     modules/home/hyprland/monitors/profiles/atlas.go.tmpl
   sudo nixos-rebuild build --flake .#atlas
   ```

   `git add` is needed only for files not already tracked by your transferred
   commit; a flake omits untracked files. Keep `flake.lock` for this migration.

5. If the build succeeds, install it for the next boot and reboot:

   ```bash
   sudo nixos-rebuild boot --flake .#atlas
   sudo reboot
   ```

   Use `boot` for the initial migration so the kernel, graphics driver, initrd,
   and desktop config are first used together after reboot. You do not need
   to run `switch` as well. The hostname becomes `atlas` on that boot.

6. After booting, check the host, GPU driver, and displays:

   ```bash
   hostname
   nvidia-smi
   hyprctl monitors all
   ```

   Future updates on this PC:

   ```bash
   cd /home/paul/nixos
   sudo nixos-rebuild switch --flake .#atlas
   ```

### If the desktop still fails

Use Ctrl+Alt+F2 and log in. These checks distinguish a driver problem from a
Hyprland startup/config problem:

```bash
hostname
systemctl --failed
journalctl -b -u getty@tty1 --no-pager
journalctl -b -k --no-pager | grep -Ei 'nvidia|drm|firmware|failed'
nvidia-smi
Hyprland
```

The last command starts Hyprland manually from the recovery TTY and prints its
errors. If Atlas cannot boot, select the previous generation in GRUB. It still
contains the laptop's desktop settings, so it is a route back to a working TTY.

Optionally refine Atlas's hardware scan from the **installed** NixOS system:

```bash
sudo nixos-generate-config --show-hardware-config > /tmp/atlas-hardware.nix
diff -u hosts/atlas/hardware-configuration.nix /tmp/atlas-hardware.nix
```

Review the result instead of overwriting blindly; retain the LUKS `tries=10`
setting and the existing 32 GiB swap-file declaration. Atlas's idle action uses
ordinary suspend; Zephyrus retains suspend-then-hibernate.

## Reinstall Zephyrus later

Select `.#zephyrus` on the laptop. Its current hardware file describes the SSD
now in Atlas; a fresh installation on another SSD will have different UUIDs.
On that new installation, generate/copy its hardware configuration to
`hosts/zephyrus/hardware-configuration.nix`, retaining the swap declaration and
LUKS password retries, then rebuild with `.#zephyrus`. Do not copy Atlas's
Intel/NVIDIA desktop hardware settings onto the laptop.

## Fresh installation

1. Clone the repo

```bash
nix-shell -p git
git clone https://github.com/poeck/nixos.git
cd nixos
```

2. Add swap to `/etc/nixos/hardware-configuration.nix`

```nix
swapDevices = [
  {
    device = "/var/lib/swapfile";
    size = 32 * 1024; # Should be at least the amount of ram
  }
];
```

3. Increase LUKS password tries

```nix
# Replace "your-luks-id" with the id of your luks device
boot.initrd.luks.devices."your-luks-id".crypttabExtraOpts = [ "tries=10" ];
```

4. Copy the generated hardware configuration into the selected host directory

```bash
cp /etc/nixos/hardware-configuration.nix ./hosts/zephyrus/
```

5. Build the selected configuration for the next boot (use `atlas` on the PC)

```bash
sudo nixos-rebuild boot --flake .#zephyrus
reboot
```
