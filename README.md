# Hosts

- `atlas`: ASUS PRIME Z690-P WIFI D4, Intel i7-12700K, NVIDIA RTX 3060 Ti.
- `zephyrus`: ROG Zephyrus G16, AMD integrated graphics and NVIDIA RTX 4060
  Mobile, with its newly installed encrypted SSD.

Both hosts use the shared apps and Hyprland configuration, including Jellyfin.
Atlas uses Intel microcode and NVIDIA directly. Zephyrus retains its AMD GPU
selection, NVIDIA PRIME bus IDs, ASUS daemon, TLP and laptop power settings.

Both automatically log in as `paul` on tty1 once per boot and start Hyprland
using `start-hyprland` from the Zsh login profile. Startup output goes to the
systemd journal instead of the boot console. No display/login manager is
enabled. The LUKS password prompt remains. Other TTYs remain available for
recovery.

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

Automatic idle timings count from the last keyboard or mouse activity:

| Host | Displays off | Lock with Noctalia | Suspend | Hibernate |
| --- | --- | --- | --- | --- |
| Atlas | 15 minutes | 29 minutes | 30 minutes | Never automatically |
| Zephyrus | 13 minutes | 14 minutes | 15 minutes | 120 minutes total |

Zephyrus's hibernation delay is 105 minutes after entering suspend. Closing its
lid starts suspend-then-hibernate immediately, with the same 105-minute delay.
Idle inhibitors can postpone these actions, and low-battery alarms can trigger
hibernation earlier on Zephyrus. Atlas disables suspend-then-hibernate.

### Wake Atlas over Wi-Fi

Atlas enables Wake-on-Wireless-LAN magic packets through NetworkManager.
Its Intel Wi-Fi adapter reports support for this trigger. Use **Sleep**, rather
than shutdown or hibernation, and test waking it from a phone on the same home
Wi-Fi before relying on remote wake.

Configure a Wake-on-LAN app with these values for the current home network:

- Wi-Fi MAC address: `00:91:9e:c0:c5:51`.
- Broadcast address: `192.168.178.255` (current subnet: `192.168.178.0/24`).
- UDP port: `9`.

Send the packet over home Wi-Fi, not to Atlas's Tailscale address. Recheck the
MAC address if connection MAC randomization is enabled, and the broadcast
address if the home subnet changes.

Tailscale on the sleeping PC cannot receive the wake request. The external
Oracle VPS instead sends a unicast packet through a WireGuard tunnel to Atlas.
FRITZ!Box's documented built-in remote wake requires a wired LAN connection;
it is not a supported substitute for a Wi-Fi wake sender.

The Oracle VPS now runs the private wake button at
`https://oracle.alpines-pauling.ts.net/`, published with Tailscale Serve.
The phone must be connected to Tailscale with the owner's account.
For phones with Tailscale DNS disabled, use `http://100.89.248.58:8092/`.
This address needs no DNS lookup. The HTTP connection travels inside
Tailscale's encrypted tunnel; the listener binds only to the VPS's Tailscale IP.
FRITZ!Box now reserves `192.168.178.116` for Atlas's Wi-Fi MAC address, and
MyFRITZ registration has been completed for the router's VPN endpoint.
The router connection is named `Atlas wake VPS`, with only the Atlas device
(named `Paul` in FRITZ!Box) selected. Sending all IPv4 traffic and NetBIOS are
disabled, and the remote DNS domain list is empty.

On Oracle, `/etc/wireguard/wg-atlas.conf` assigns `10.254.77.1/30` to the tunnel
and restricts peer `AllowedIPs` to `192.168.178.116/32`. Exported `DNS` entries
are removed before installation. The original internet route and DNS settings
remain in use. `wg-quick@wg-atlas.service` starts the tunnel at boot.
`wg-atlas-dns.timer` runs the official WireGuard endpoint re-resolution helper
each minute so a stale endpoint can recover after the home public IP changes.
Its units are in `scripts/wg-atlas-dns.service` and `scripts/wg-atlas-dns.timer`.

The tunnel handshake, ping to awake Atlas, and both wake-page addresses have
been verified. Local broadcast and unicast wake were retested successfully.
Capture on Atlas showed no incoming VPN wake packets on UDP port `9`, while
all three matching 102-byte magic packets arrived on each of ports `7` and
`40009`. The wake service therefore uses UDP port `7` for the VPN destination.
An actual remote wake from sleep still needs confirmation after this change.
A successful page response means packets were sent, not that Atlas woke.

The service source is `scripts/atlas-wake.py`, with its Ubuntu systemd unit in
`scripts/atlas-wake.service`. On Oracle it is installed under `/opt/atlas-wake`,
with configuration in `/etc/atlas-wake.env`. The HTTPS backend listens on
`127.0.0.1:8091` and checks the Tailscale identity supplied by Serve.
The direct IP listener on `100.89.248.58:8092` instead identifies the actual
connecting peer using `tailscale whois`, and ignores client-supplied identity
headers. Both listeners require the owner's account, check the form origin and
token, and only send the fixed Atlas magic packet when `192.168.178.116` routes
through `wg-atlas`. `WAKE_ORIGINS` lists the two permitted addresses;
`WAKE_TAILSCALE_IP` and `WAKE_TAILSCALE_PORT` enable the direct listener.
WireGuard private keys must stay outside this repository.

Useful checks on Oracle:

```bash
systemctl status atlas-wake.service
sudo tailscale serve status
ip route get 192.168.178.116
sudo wg show wg-atlas
```

## T3 Code background service

Both hosts install the T3 CLI and enable `t3code.service` for `paul`. Lingering
starts the user service at boot and keeps it running after logout. The server
listens at `http://127.0.0.1:3774`, alongside the desktop app on port 3773.
Projects, threads, settings and Connect identity stay under `~/.t3/userdata`.
Each device keeps its own local data and requires its own provider authentication
and remote-access setup.

Apply the shared configuration on each device:

```bash
sudo nixos-rebuild switch --flake .#atlas
# On the laptop:
sudo nixos-rebuild switch --flake .#zephyrus
```

The first rebuild migrates an existing installer-created service and launchers,
keeping backups with a `.pre-nix` suffix. Downloaded runtimes and user data are
retained. After rebuilding, use:

```bash
t3 --version
t3 service status
t3 service restart
journalctl --user -u t3code.service -f
```

Nix owns the CLI and service; `t3 update`, `t3 uninstall` and the service install
and uninstall commands are disabled in the managed launcher. To update, refresh
the desktop with `nix flake update t3code`, update the CLI version and release
hashes in `pkgs/t3-cli.nix` to match, then rebuild. Configuration evaluation checks
that the CLI and desktop versions agree. A changed service runtime restarts on
rebuild, interrupting active turns on that service.

## Stream Atlas to Zephyrus over Tailscale

Atlas enables Sunshine as a user service with DRM/KMS screen capture and NVIDIA
NVENC encoding. It starts with the graphical session. Zephyrus installs the
Moonlight client (`moonlight`). Both hosts allow Tailscale's encrypted peer
traffic on UDP 41641 to help establish direct connections.

Apply this checkout on Atlas:

```bash
cd /home/paul/nixos
sudo nixos-rebuild switch --flake .#atlas
systemctl --user start sunshine.service
```

On Zephyrus, after transferring the updated checkout, run
`sudo nixos-rebuild switch --flake /home/paul/nixos#zephyrus`. To install Moonlight
immediately without transferring the checkout, run
`nix profile install nixpkgs#moonlight-qt` on the laptop instead.

1. On Atlas, open `https://localhost:47990`, accept Sunshine's self-signed
   certificate, and create its administrator username and password.
2. On Zephyrus, launch Moonlight and use **Add PC** with Atlas's Tailscale IPv4
   address, currently `100.92.181.17`. Tailscale does not carry LAN discovery;
   add the address manually. Confirm the current address with `tailscale ip -4`
   on Atlas if it changes.
3. Select Atlas in Moonlight. Enter its displayed PIN in Sunshine's **PIN**
   page. The page is also accessible from the laptop at
   `https://100.92.181.17:47990` while connected to Tailscale.
4. Select **Desktop** to connect. Keep Atlas awake with Hyprland running and a
   display active. Start with 1080p at 60 FPS and adjust bitrate as needed.

Sunshine's streaming and setup ports are allowed only on `tailscale0`; UPnP
is disabled. Tailnet access policies still apply. Its web UI permits WAN-class
addresses because Tailscale addresses are outside ordinary private LAN ranges;
the host firewall limits remote access to Tailscale. The exact Tailscale web UI
URL is also allowed in `csrf_allowed_origins` for setup and pairing; update that
setting if Atlas's Tailscale address changes. Video settings are managed
in `hosts/atlas/default.nix`; administrator credentials and pairing data stay
under `~/.config/sunshine` rather than in the repository or Nix store.

Check `systemctl --user status sunshine` and
`journalctl --user -u sunshine -b` on Atlas if streaming fails. On Zephyrus,
`tailscale ping atlas` checks the peer connection and reports whether it is
direct or relayed.

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
journalctl -b -t hyprland --no-pager
journalctl -b -k --no-pager | grep -Ei 'nvidia|drm|firmware|failed'
nvidia-smi
start-hyprland
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
