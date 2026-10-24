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

## GNOME Keyring

Both hosts use GNOME Keyring for Secret Service and the desktop Secret portal.
The tty1 PAM session uses `pam_fde_boot_pw` to reuse the LUKS password entered
in Plymouth, including during tty autologin. The login keyring must use that
same password. No password is stored in the Nix configuration or Nix store.
Seahorse (**Passwords and Keys**) is installed for managing the keyring.

The session identifies itself as `Hyprland`. Inlark's executable and the
ChatGPT and T3 Code desktop launchers select Electron's keyring backend with
`--password-store=gnome-libsecret`. Adding `GNOME` to `XDG_CURRENT_DESKTOP`
changes desktop and portal detection and triggers Hyprland's startup warning;
it is not needed to run GNOME Keyring.

The keyring stays unlocked during suspend and Island's screen lock. Island
still asks for the normal account password to unlock the desktop; there is no
additional keyring prompt. This configuration does not disable the screen lock.

On a fresh installation, PAM can create the login keyring
using the cached LUKS password on the next boot. Automatic unlocking needs the
cached password to remain available until tty1 starts. Changing the LUKS
password later also requires changing the login keyring password in Seahorse.

After reboot, check:

```bash
systemctl --user status gnome-keyring
journalctl -b -u getty@tty1 --no-pager | rg 'loaded key|gkr-pam|keyring'
```

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

| Host | Displays off | Lock with Island | Suspend | Hibernate |
| --- | --- | --- | --- | --- |
| Atlas | 15 minutes | 29 minutes | 30 minutes | Never automatically |
| Zephyrus | 13 minutes | 14 minutes | 15 minutes | 120 minutes total |

Zephyrus's hibernation delay is 105 minutes after entering suspend. Closing its
lid starts suspend-then-hibernate immediately, with the same 105-minute delay.
Idle inhibitors can postpone these actions, and low-battery alarms can trigger
hibernation earlier on Zephyrus. Atlas disables suspend-then-hibernate.

## Island desktop shell

Both hosts use [Island](https://github.com/poeck/island) in live mode for the
status bar, application launcher, media, calendar, weather, system tray, system
monitor, audio, network, Bluetooth, notifications, OSDs, session menu, Polkit
authentication and screen lock. Notifications and Polkit ownership are enabled;
other supported features are available by default. Atlas prefers the AOC display;
Zephyrus prefers its internal Sharp display, with an available-output fallback.
Atlas uses power-profiles-daemon and Zephyrus exposes TLP profiles through tlp-pd
for Island's power-profile selector. Weather initially uses Vienna.

| Shortcut | Action |
| --- | --- |
| Super+R | Toggle the application launcher |
| Super+P | Toggle the session / power menu |
| Super+Space | Show or hide the bar over fullscreen windows |

Home Manager starts Island with the graphical session. Hypridle uses Island's
PAM locker and waits for compositor-confirmed locking before sleep. The PAM
service is `swaylock`. Island retains its upstream Quickshell/Qt dependency pin;
update it with `nix flake update island`. Check the running integration with
`island doctor` and `island status`.

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
`https://oracle.alpines-pauling.ts.net:8443/`, published with Tailscale Serve.
Serve uses port `8443` because Oracle's existing Coolify proxy needs port `443`
for service domains that also resolve to Oracle's Tailscale IP.
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
Wake from sleep through the wake page was confirmed after this change;
further reliability testing is planned.
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
listens at `http://127.0.0.1:3774`. Its `--tailscale-serve` startup flag publishes
that backend over tailnet-only HTTPS on port 443 through Tailscale Serve. The
service user needs Tailscale operator permission (`paul` is already the operator
on Atlas). After rebuilding, use `t3 pair --tailscale` to generate a pairing link
for another device. `tailscale serve status` shows the HTTPS endpoint and target.
The desktop launcher uses `~/.t3-desktop`, separate from the service's `~/.t3`.
On each host, disable **Local environment** in the desktop app under
**Settings → Connections**, restart the app, and add the host's background
service using the link from `t3 pair --tailscale`. The desktop app then acts as
a client of that host's service; its local environment stays disabled.
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
and uninstall commands are disabled in the managed launcher. To update, run
`python3 scripts/update-system.py` (all inputs) or
`python3 scripts/update-system.py t3code` (T3 only), then rebuild. The updater reads
the locked desktop version and records the matching CLI release's GitHub SHA-256
digests for both Linux architectures in `pkgs/t3-cli-release.json`. Commit that file
with `flake.lock`. Nix verifies the archive hashes when downloading; configuration
evaluation checks that the CLI and desktop versions agree. If inputs were updated
directly, run `python3 scripts/update-system.py --sync-t3-only` before rebuilding.
A changed service runtime restarts on rebuild, interrupting active turns on that
service.

## Stream Atlas to Zephyrus over Tailscale

Atlas enables Sunshine as a user service with Wayland/WLR screen capture and
NVIDIA NVENC encoding. It starts with the graphical session. A small package
wrapper supplies `/run/opengl-driver/lib` so Sunshine's bundled FFmpeg can load
the NVIDIA driver libraries. No KMS capability or CUDA toolkit build is needed.
Zephyrus installs the Moonlight client (`moonlight`). Both hosts allow Tailscale's encrypted peer
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
4. Select **Desktop** to connect. In normal mode Sunshine selects the AOC by
   description, instead of defaulting to the first (Philips) screen. Keep Atlas
   awake with Hyprland running. Start at 60 FPS and adjust bitrate as needed.

### Switch between the local desk and a virtual remote screen

On Atlas, **Super + Shift + R** toggles remote mode. The launcher also contains
**Atlas: Toggle remote desktop**. Terminal commands are:

```bash
atlas-remote on
atlas-remote status
atlas-remote off
```

From the laptop, after waking Atlas and connecting to Tailscale:

```bash
ssh atlas '~/.local/bin/atlas-remote on'
# Connect to Desktop in Moonlight.
ssh atlas '~/.local/bin/atlas-remote off'
```

`on` creates a 1920x1200, 60 Hz virtual monitor named `ATLAS-REMOTE`, saves the
current physical monitor and workspace layout, and disables the physical
outputs. The same desktop, applications, Island lock screen and 1Password
remain running. Workspaces move to the virtual output. Sunshine restarts to
select it; an existing stream must reconnect. `off` restores the saved layout
and selects the AOC again. **Super + Ctrl + Shift + R** also returns to local
mode, even while the screen is locked. Neither command unlocks the desktop.

While remote mode is enabled, a root system service adds temporary
`RefuseManualStart=yes` drop-ins for `poweroff.target` and `halt.target`.
Normal desktop shutdown actions, `shutdown` and `systemctl poweroff` (including
via sudo) are refused; suspend and reboot remain available. `atlas-remote off`
automatically removes only these guard drop-ins. A systemd path unit watches
the existing remote marker, so no password is needed when switching modes.
The change is event-driven and can take a moment to apply. Check it with:

```bash
systemctl show poweroff.target halt.target -p Id -p RefuseManualStart
```

Both targets report `RefuseManualStart=yes` while protected. The guard is an
accident-prevention measure; forced shutdown commands bypassing systemd and
holding the physical power button can still turn Atlas off.

Remote mode remains enabled when Moonlight disconnects and across ordinary
suspend/resume. HyprDynamicMonitors is paused, config reloads retain the remote
layout, and display-idle/resume hooks keep the virtual monitor usable without
enabling physical outputs. Lock and suspend timeouts are unchanged. The mode
and layout snapshot live under `$XDG_RUNTIME_DIR/atlas-remote` and are tied to
the current Hyprland session; a new compositor session or reboot starts local.
Only monitor/workspace metadata is saved, not window contents or passwords.

`off` keeps the virtual screen available if no physical output can be restored.
A failed `on` attempts to restore local mode automatically. SSH commands import
the graphical session's display environment, so no manual `DISPLAY` or
`HYPRLAND_INSTANCE_SIGNATURE` setup is required. Repeating `on` repairs the
virtual layout and restarts Sunshine. Application window sizes/positions may
change when moving from three monitors to one; monitor modes, positions,
scales and existing workspace assignments are saved for the return trip.

Before relying on this away from home, test Moonlight input and Island unlock
on the virtual screen, 1Password authorization, disconnect/reconnect, and a
full suspend/wake cycle while remote mode is enabled. For reboot recovery, see
Atlas remote LUKS unlock below.

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

## Share Atlas's keyboard and mouse with Zephyrus

Lan Mouse runs as a receiver automatically in Zephyrus's Hyprland session.
Its keyboard and trackpad always stay local. Atlas starts with sharing off;
press **Super + Shift + L** on Atlas to enable or disable it. With sharing on,
move past the left edge of Atlas's desktop to control Zephyrus, and move back
through the laptop's right edge to return. A notification confirms each toggle.
The same shortcut on Zephyrus enables or disables its receiver. Zephyrus starts
enabled in a new Hyprland session, but a manual disable stays off until you
enable it again or start a new session, including across suspend and resume.

Apply the updated checkout on both hosts:

```bash
# On Atlas:
sudo nixos-rebuild switch --flake .#atlas
# On Zephyrus:
sudo nixos-rebuild switch --flake .#zephyrus
```

After the first rebuild, log out and back in on Zephyrus, or run
`lan-mouse-desk on` in its current Hyprland session to start the receiver.
New files must be tracked before rebuilding a Git-backed flake.

Pair once:

1. Open **Lan Mouse** from the app launcher on both hosts. On Atlas, opening
   this window also enables sharing; the GUI attaches to the managed service.
2. Find Atlas's certificate fingerprint in its Lan Mouse window. On Atlas,
   attempt to move the pointer past the left edge to connect to Zephyrus.
3. On Zephyrus, authorize Atlas under **Incoming Connections**, checking that
   the fingerprint matches. Only this direction needs authorization.
4. Close the windows. Pairing is saved; closing the GUI keeps the service
   running. Use the shortcut or `lan-mouse-desk off` to stop sharing on Atlas.

Hold **left Ctrl + left Alt + left Shift + left Super** together to release
the mouse back to Atlas. This releases the current capture without disabling
sharing. When the pointer is on the laptop, use this chord before pressing
Atlas's toggle shortcut, because ordinary shortcuts are forwarded to Zephyrus.

Atlas's sharing stops before suspend or hibernate and stays off after waking.
It also stops when the Hyprland session ends, and does not start on login.
Zephyrus's receiver is ready after login or resume. Before moving the laptop
away from the desk, turn sharing off on Atlas; network reachability does not
detect whether the laptop is beside the monitors. To reject input immediately
from the laptop, press **Super + Shift + L**, use **Lan Mouse: Toggle receiver**
in its launcher, or run `lan-mouse-desk off`. An explicitly stopped receiver
stays off until enabled again or the next Hyprland session.

Both hosts use Tailscale; UDP 4242 is allowed only on `tailscale0`. The tailnet
policy must permit that traffic. Atlas addresses Zephyrus by MagicDNS and uses
Lan Mouse's layer-shell backend for Hyprland keyboard shortcut compatibility.

Nix supplies the layout and release chord on each service start. Pairing
approvals remain in the writable `~/.config/lan-mouse/config.toml`; the private
certificate stays in `~/.config/lan-mouse/lan-mouse.pem`. Neither is stored in
the repository or Nix store. GUI layout edits are reset on the next start;
pairing approvals are retained. Clipboard sharing is not configured.

Useful controls and diagnostics:

```bash
lan-mouse-desk status
lan-mouse-desk on
lan-mouse-desk off
lan-mouse-desk gui
systemctl --user status lan-mouse
journalctl --user -u lan-mouse -b
tailscale ping zephyrus # From Atlas
```

## SSH between Atlas and Zephyrus

Both hosts run OpenSSH and allow `paul` to log in with the public key in
`keys/paul.pub`. This is the **SSH Key Zephyrus** key already stored in
1Password and used for Git signing. Its private key stays in 1Password.
Password authentication and root SSH login are disabled.

Apply the updated checkout on each host:

```bash
# On Atlas:
sudo nixos-rebuild switch --flake .#atlas
# On Zephyrus:
sudo nixos-rebuild switch --flake .#zephyrus
```

Add new files to Git before rebuilding a Git-backed flake, or transfer the
committed checkout. On each host, sign in to the 1Password desktop app and enable
**Settings > Developer > Use the SSH agent**. The shared desktop configuration
starts 1Password automatically; unlock it and approve its SSH authorization
prompt when connecting. Log out and back in after the first rebuild so apps
inherit the updated `SSH_AUTH_SOCK`.

From the laptop, use `ssh atlas`; from the PC, use `ssh zephyrus`. Both aliases
select user `paul`, the public key at `~/.ssh/paul.pub`, and the 1Password agent
at `~/.1password/agent.sock`. Agent forwarding is disabled for these aliases;
connections started on the other host use that host's own 1Password app.

The aliases resolve `atlas.alpines-pauling.ts.net` and
`zephyrus.alpines-pauling.ts.net`. Tailscale must be connected on both hosts,
including at home. It can connect directly over the home LAN and continues
working away from home without router port forwarding. TCP port 22 is allowed
only on `tailscale0`. Tailscale SSH is disabled so OpenSSH always verifies the
1Password key. MagicDNS must be enabled in the tailnet, and its access policy
must permit TCP port 22 between these devices. Both devices were already
enrolled when this configuration was prepared; after a fresh installation,
run `sudo tailscale up` on that host to sign in.

Useful checks:

```bash
systemctl status sshd tailscaled tailscaled-set
SSH_AUTH_SOCK="$HOME/.1password/agent.sock" ssh-add -l
tailscale ping atlas  # From Zephyrus; use zephyrus from Atlas.
ssh -v atlas         # From Zephyrus; use zephyrus from Atlas.
```

Both machines must be awake to receive SSH connections. The earlier Atlas wake
instructions also apply when connecting remotely.

## Browser extension pins

`modules/home/chromium-extensions.json` pins each extension's CRX download,
version and SHA-256 hash. Helium reuses the requested entries from this manifest;
the standalone Chromium browser is no longer installed. Builds use those exact
packages instead of a mutable Web Store update endpoint. To update the pins:

```bash
cd /home/paul/nixos
browser_version=$(helium --version | sed -n 's/.*(Chromium \([^)]*\)).*/\1/p')
nix-shell -p python3 --run "python3 scripts/update-chromium-extensions.py $browser_version"
git diff -- modules/home/chromium-extensions.json
```

The updater reads each downloaded manifest and CRX extension ID. It only writes
the pins after all downloads succeed. Classic uBlock Origin uses the signed CRX
from its developer's GitHub releases; its ID is `fkgkibajhfbepljeaefdnfnegdcjomkh`,
which differs from the old Web Store ID. Existing settings under the old ID may
need to be exported and imported when migrating an existing Chromium profile.

## Helium browser

Helium uses the reviewed `poeck/helium-browser-nix-flake` fork, pinned to commit
`14a8f68137d4db62213555937f23ad95e7f8c4e6` (Helium 0.18.3.1). To update the browser,
review a new fork revision, change the pin in `flake.nix`, then run
`nix flake update helium-browser`. The local package override removes upstream
flags that disable component updates and suppress outdated-browser warnings.

`modules/home/helium.nix` installs the pinned 1Password, ChatGPT (the `Codex`
manifest entry), and Claude extensions in both profiles, and AuthFill and
SponsorBlock only in Personal, using `chromium-extensions.json`.
Classic uBlock Origin is bundled with Helium; no second blocker or uBlock Origin
Lite is installed. The module
also configures 1Password's native messaging host and browser allowlist, plus
ChatGPT's native messaging host from the official OpenAI Chrome plugin. That
plugin must be installed for the ChatGPT desktop connection to work. Sign in
to the extensions separately in each profile. Helium is not an officially
supported browser for either AI extension; installation does not guarantee
that all browser-control or desktop-connection features work.

The application menu contains **Helium (Personal)** and **Helium (Otark)**;
the corresponding commands are `helium-personal` and `helium-otark`. Personal
is the default for web links. Otark starts with a green accent (`#16a34a`).
Both profiles keep separate browsing data under
`~/.config/net.imput.helium/Personal` and `Otark`. Preferences are seeded
only when absent and stay writable; later changes in Helium are preserved.
The existing `Default` profile is retained. Each new profile appears in
Helium's profile picker after its first launch.

The profile initializer removes AuthFill and SponsorBlock registrations from
Otark and records per-profile external-extension exclusions. It preserves other
settings and keeps a private backup before making this targeted change. If Helium is running,
the change is deferred until the next start after all Helium windows are closed.

`modules/core/helium.nix` sets Google as the search provider through Chromium's
shared Linux policy directory. This applies to both Helium profiles; the search
provider is managed through Nix rather than the browser's settings. 
Apply the configuration with `sudo nixos-rebuild switch --flake .#atlas`
(or `.#zephyrus` on the laptop).

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


## Atlas remote LUKS unlock

Atlas's systemd initrd connects to the home Wi-Fi (`wlo1`, Intel AX201) and
obtains its reserved address `192.168.178.116` from the FRITZ!Box. SSH listens
on port 2222 only during early boot. The configured Paul public key grants
access only to the interactive LUKS password agent, with forwarding disabled.
Local Plymouth unlocking remains available independently of Wi-Fi.

The route is Zephyrus → Tailscale SSH on Oracle → Oracle's existing WireGuard
connection to the FRITZ!Box → Atlas. Oracle and its `wg-quick@wg-atlas` service
must be running. No WireGuard installation on Zephyrus is required. Tailscale
may require browser confirmation for the Oracle SSH hop.

On Zephyrus, unlock 1Password and use `ssh atlas-unlock` after applying the
updated shared SSH configuration there. Until then, this equivalent command
works with the existing public key and 1Password SSH agent:

```bash
ssh -J paul@oracle.alpines-pauling.ts.net -t -p 2222 \
  -i ~/.ssh/paul.pub -o IdentitiesOnly=yes \
  -o IdentityAgent=~/.1password/agent.sock -o HostKeyAlias=atlas-initrd \
  root@192.168.178.116
```

Verify the initial host-key fingerprint against the dedicated key on Atlas
before accepting it. The key prepared for this installation has fingerprint:

```text
SHA256:RcgXquVIPgZR+3xT5aZoBPbyVGP9u5vGMmb7p7ip2/s
```

Enter the LUKS password in the SSH terminal. The session
will disconnect when boot continues; normal Tailscale/desktop access follows.
A connection refused or timeout while Atlas is already running is expected:
the initrd SSH service does not run in the normal system.

### Preparing or updating the boot image

The root-only helper copies the active home Wi-Fi credentials without printing
them and creates a separate initrd SSH host key, preserving an existing key:

```bash
cd /home/paul/nixos
nix build --out-link /tmp/atlas-initrd-prepare \
  path:/home/paul/nixos#nixosConfigurations.atlas.config.system.build.atlasInitrdPrepare
sudo /tmp/atlas-initrd-prepare/bin/atlas-initrd-prepare
sudo nixos-rebuild boot --flake path:/home/paul/nixos#atlas
```

Credentials live under `/etc/secrets/initrd/atlas` (directory mode 0700,
private files 0600). At bootloader installation time, GRUB receives a separate
secrets archive alongside the base initrd and loads both together. Neither the
Wi-Fi PSK nor the SSH private key enters the Nix store or Git.
They **are present in that archive on the unencrypted boot partition**;
someone with physical access can extract them. The LUKS password is never
stored there. Re-run the helper and rebuild after changing the Wi-Fi password.
If the Wi-Fi firmware version changes with a kernel update, review the pinned
firmware name in `hosts/atlas/remote-unlock.nix`.

### First boot test and recovery

The configuration was built and installed for the next boot on Atlas. The
installed base initrd matches the built image; the separate secrets archive
contains the expected files with root-only archive permissions. GRUB loads
both and retains the previous generation.

The supervised remote reboot test passed on 2026-10-24: initrd Wi-Fi connected,
SSH authentication arrived through Oracle (`10.254.77.1`), and entering the LUKS
passphrase remotely allowed the new system to boot. The login journal confirms
`pam_fde_boot_pw` loaded the cached key and GNOME Keyring unlocked successfully.
Sunshine and GNOME Keyring were running afterward, no system units had failed,
and the initrd SSH listener on port 2222 was gone.

For future retests after boot/network changes:

1. Keep Atlas physically accessible and have Zephyrus with unlocked 1Password
   ready. Confirm `ssh paul@oracle` works and Oracle's home tunnel is active.
2. Reboot Atlas, leave the Plymouth password blank and wait for Wi-Fi/DHCP.
3. Connect from Zephyrus using the command above, verify the host fingerprint,
   and enter the LUKS password. Retry the connection if Wi-Fi is still starting.
4. Check normal Tailscale, desktop and 1Password access after boot. Also check
   GNOME Keyring: the login journal should confirm the keyring was unlocked.
5. If remote unlock fails, enter the password locally in Plymouth. The previous
   NixOS generation remains selectable in GRUB for recovery.

This enables recovery after a reboot. It does not enable Wi-Fi wake from a
complete shutdown. Continue using suspend for ordinary remote operation.
