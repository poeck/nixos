{
  description = "NixOS Config";

  inputs = {
    # Nix
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helium-browser = {
      # Pin the reviewed fork; update intentionally with a new reviewed revision.
      url = "github:poeck/helium-browser-nix-flake/14a8f68137d4db62213555937f23ad95e7f8c4e6";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-darwin.follows = "nixpkgs";
    };
    minegrub.url = "github:Lxtharia/minegrub-theme";
    mineplymouth.url = "github:nikp123/minecraft-plymouth-theme";
    hyprdynamicmonitors.url = "github:fiffeek/hyprdynamicmonitors";
    gather-linux = {
      url = "github:poeck/gatherway";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents.url = "github:numtide/llm-agents.nix";
    t3code = {
      url = "github:poeck/t3code-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-desktop.url = "github:aaddrick/claude-desktop-debian";
    chatgpt-desktop-app = {
      url = "github:poeck/chatgpt-desktop-app-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    inlark = {
      # Follow the default branch; refresh with `nix flake update inlark`.
      url = "github:inlark/inlark";
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
        atlas = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ ./hosts/atlas ];
          specialArgs = {
            host = "atlas";
            inherit self inputs username;
          };
        };
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
