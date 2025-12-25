# Installation

1. Clone the repo

```bash
nix-shell -p git
git clone https://github.com/poeck/nixos.git
cd n
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

3. Copy the hardware configuration to `/etc/nixos/hardware-configuration.nix`

```bash
cp /etc/nixos/hardware-configuration.nix ./hosts/zephyrus/
```

4. Switch to the new configuration

```bash
sudo nixos-rebuild boot --flake .#zephyrus
sudo nixos-rebuild switch --flake .#zephyrus
reboot
```
