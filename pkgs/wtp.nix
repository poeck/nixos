{ pkgs, lib, ... }:

pkgs.buildGoModule rec {
  pname = "wtp";
  version = "2.7.0";

  src = pkgs.fetchFromGitHub {
    owner = "satococoa";
    repo = "wtp";
    rev = "v${version}";
    hash = "sha256-uD8cGVVZwg0FDjlYBDwL80lMBsaEfEtPTDvvnOhxZXM=";
  };

  vendorHash = "sha256-wX6TeALJojynP4ocOR45WkayVVwvTr2LUbfAxuns9SM=";

  subPackages = [ "cmd/wtp" ];

  # Tests require a git repository
  doCheck = false;

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  meta = with lib; {
    description = "Git worktree management CLI tool";
    homepage = "https://github.com/satococoa/wtp";
    license = licenses.mit;
    mainProgram = "wtp";
  };
}
