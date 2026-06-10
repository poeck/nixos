{
  description = "FrostPhoenix's nixos configuration";

  nixConfig = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  inputs = {
    # Nix
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Third party
    minegrub.url = "github:Lxtharia/minegrub-theme";
    mineplymouth.url = "github:nikp123/minecraft-plymouth-theme";
    hyprdynamicmonitors.url = "github:fiffeek/hyprdynamicmonitors";
    llm-agents.url = "github:numtide/llm-agents.nix";
    claude-desktop.url = "github:aaddrick/claude-desktop-debian";
    codex-desktop-linux = {
      url = "github:ilysenko/codex-desktop-linux";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    handy.url = "github:cjpais/Handy";
    nixpak = {
      url = "github:nixpak/nixpak";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, self, ... }@inputs:
    let
      username = "paul";
      system = "x86_64-linux";
    in
    {
      nixosConfigurations = {
        zephyrus = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ ./hosts/zephyrus ];
          specialArgs = {
            host = "zephyrus";
            inherit self inputs username;
          };
        };
      };
    };
}
