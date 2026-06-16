{ pkgs, inputs, ... }:
{
  nixpkgs = {
    config.android_sdk.accept_license = true;
    overlays = [
      (
        final: prev:
        (import ../../pkgs {
          inherit inputs;
          inherit pkgs;
          inherit (prev) system;
        })
      )
      inputs.firefox-addons.overlays.default
      inputs.llm-agents.overlays.default
      inputs.claude-desktop.overlays.default
    ];
  };
}
