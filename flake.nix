{
  description = "FrostPhoenix's nixos configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";

    vicinae.url = "github:vicinaehq/vicinae";
    minegrub.url = "github:Lxtharia/minegrub-theme";

    home-manager = {
      url = "github:nix-community/home-manager";
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
