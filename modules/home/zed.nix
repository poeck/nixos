{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nil
    nixd
    prettier
  ];

  programs.zed-editor = {
    enable = true;
    extensions = [
      "nix"
      "typescript"
      "go"
      "emmet"
      "prisma"
      "wakatime"
    ];
    userSettings = {
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
      preview_tabs = {
        enabled = false;
      };
      active_pane_modifiers = {
        inactive_opacity = 0.8;
      };
      tabs = {
        file_icons = true;
        git_status = true;
        show_diagnostics = "all";
      };
      # Shows function signature when inside parentheses
      auto_signature_help = true;
      # Close editors when file is deleted from disk
      close_on_file_delete = true;
      features = {
        edit_prediction_provider = "supermaven";
      };
      vim = {
        use_system_clipboard = "always";
        # Smart case for f and t binds
        use_smartcase_find = true;
        # Normal = relative, insert = absolute
        toggle_relative_line_numbers = true;
      };
      languages = {
        "TSX" = {
          formatter = [
            { code_action = "source.fixAll.eslint"; }
            { code_action = "source.organizeImports"; }
          ];
        };
        "JavaScript" = {
          formatter = [
            { code_action = "source.fixAll.eslint"; }
            { code_action = "source.organizeImports"; }
          ];
        };
      };
    };
    userKeymaps = [
      {
        bindings = {
          # Panes
          "shift-f1 w v" = "pane::SplitVertical";
          "shift-f1 w h" = "pane::SplitHorizontal";
          "shift-f1 w c" = "pane::CloseAllItems";
          "shift-f1 w q" = "pane::CloseOtherItems";
          "shift-f1 d" = "pane::CloseActiveItem";

          "shift-f1 1" = [
            "pane::ActivateItem"
            0
          ];
          "shift-f1 2" = [
            "pane::ActivateItem"
            1
          ];
          "shift-f1 3" = [
            "pane::ActivateItem"
            2
          ];
          "shift-f1 4" = [
            "pane::ActivateItem"
            3
          ];
          "shift-f1 5" = [
            "pane::ActivateItem"
            4
          ];
          "shift-f1 6" = [
            "pane::ActivateItem"
            5
          ];
          "shift-f1 7" = [
            "pane::ActivateItem"
            6
          ];
          "shift-f1 8" = [
            "pane::ActivateItem"
            7
          ];
          "shift-f1 9" = [
            "pane::ActivateItem"
            8
          ];
          "shift-f1 0" = [
            "pane::ActivateItem"
            9
          ];

          # Workspace
          "shift-f1 w f" = "workspace::ToggleZoom";
          "shift-f1 shift-f1" = "workspace::ToggleLeftDock";
          "shift-f1 h" = "workspace::ActivatePaneLeft";
          "shift-f1 j" = "workspace::ActivatePaneDown";
          "shift-f1 k" = "workspace::ActivatePaneUp";
          "shift-f1 l" = "workspace::ActivatePaneRight";

          # Git
          "shift-f1 g g" = "git_panel::ToggleFocus";
          "shift-f1 g d" = "git::Diff";
          "shift-f1 g c" = "git::Commit";

          # Other
          "shift-f1 space" = "file_finder::Toggle";
          "shift-f1 f" = "project_panel::ToggleFocus";
          "shift-f1 t" = "terminal_panel::Toggle";
        };
      }
      {
        # In editor & insert mode
        context = "Editor && vim_mode == insert";
        bindings = {
          # Map j k to escape
          "j k" = [
            "workspace::SendKeystrokes"
            "escape"
          ];
        };
      }
      {
        # In editor & normal mode
        context = "Editor && vim_mode == normal";
        bindings = {
          "space" = [
            "workspace::SendKeystrokes"
            "shift-f1"
          ];

          # Other
          "shift-f1 s" = "workspace::Save";
        };
      }
      {
        # In terminal
        context = "Terminal";
        bindings = {
          "shift-f1 n" = "workspace::NewTerminal";
        };
      }
    ];
  };
}
