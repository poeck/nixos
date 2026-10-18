i always forget how to update, so here are the commands:

## nixpkgs only

```sh
python3 scripts/update-system.py nixpkgs
nh os switch
```

## everything

```sh
python3 scripts/update-system.py
nh os switch
```

The updater runs `nix flake update` and automatically pins the T3 CLI version and
both Linux download hashes to the locked desktop release. Run it from either host;
commit `flake.lock` and `pkgs/t3-cli-release.json` together.

If you already ran `nix flake update` directly, synchronize the CLI before rebuilding:

```sh
python3 scripts/update-system.py --sync-t3-only
nh os switch
```
