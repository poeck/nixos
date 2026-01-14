{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nil
    nixd
  ];

  programs.zed-editor = {
    enable = true;
    extensions = [
      "nix"
      "typescript"
      "go"
      "emmet"
    ];
    userSettings = {
      hour_format = "hour24";
      vim_mode = true;
      base_keymap = "VSCode";
      theme = {
        mode = "system";
        dark = "Gruvbox Dark";
        light = "Gruvbox Light";
      };
      git = {
        inline_blame.enabled = false;
      };
    };
    userKeymaps = [
      {
        context = "Editor && vim_mode == insert";
        bindings = {
          "j k" = [
            "workspace::SendKeystrokes"
            "escape"
          ];
        };
      }
      {
        bindings = {
          "ctrl-t" = "terminal_panel::Toggle";
        };
      }
      {
        context = "VimControl && vim_mode == normal";
        bindings = {
          "space space" = "file_finder::Toggle";

          # Panes
          "space w v" = "pane::SplitVertical";
          "space w h" = "pane::SplitHorizontal";
          "space w q" = "pane::CloseAllItems";
          "space d" = "pane::CloseActiveItem";

          "space 1" = [
            "pane::ActivateItem"
            0
          ];
          "space 2" = [
            "pane::ActivateItem"
            1
          ];
          "space 3" = [
            "pane::ActivateItem"
            2
          ];
          "space 4" = [
            "pane::ActivateItem"
            3
          ];
          "space 5" = [
            "pane::ActivateItem"
            4
          ];
          "space 6" = [
            "pane::ActivateItem"
            5
          ];
          "space 7" = [
            "pane::ActivateItem"
            6
          ];
          "space 8" = [
            "pane::ActivateItem"
            7
          ];
          "space 9" = [
            "pane::ActivateItem"
            8
          ];
          "space 0" = [
            "pane::ActivateItem"
            9
          ];

          # Workspace
          "space s" = "workspace::Save";
          "space h" = "workspace::ActivatePaneLeft";
          "space j" = "workspace::ActivatePaneDown";
          "space k" = "workspace::ActivatePaneUp";
          "space l" = "workspace::ActivatePaneRight";
        };
      }
    ];
  };
}
