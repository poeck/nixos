{ config, pkgs, lib, ... }:
{
  config.programs.nixvim = {
    plugins = {
      telescope = {
        enable = true;
        extensions.fzf-native.enable = true;
        settings.defaults = {
          file_ignore_patterns = [ "node_modules/" ".git/" "dist/" ".next/" ".nx/" ];
          mappings.i = {
            "<Esc>" = "close";
          };
        };
        settings.pickers.find_files = {
          find_command = [
            "rg"
            "--no-ignore"
            "--hidden"
            "--files"
            "-g"
            "!**/node_modules/*"
            "-g"
            "!**/.git/*"
          ];
        };
      };

      oil = {
        enable = true;
        settings = {
          default_file_explorer = true;
          columns = [ "size" "icon" ];
          delete_to_trash = true;
          skip_confirm_for_simple_edits = true;
          prompt_save_on_select_new_entry = false;
          lsp_file_methods = {
            enabled = true;
            timeout_ms = 1000;
            autosave_changes = true;
          };
          watch_for_changes = true;
          keymaps = {
            t = "actions.parent";
          };
          view_options = {
            show_hidden = true;
          };
        };
      };

      supermaven = {
        enable = true;
        settings = {
          keymaps = {
            accept_suggestion = "<C-j>";
            clear_suggestion = "<C-]>";
            accept_word = "<C-]>";
          };
          log_level = "off";
        };
      };

      gitsigns = {
        enable = true;
      };

      nvim-autopairs.enable = true;

      ts-autotag = {
        enable = true;
        settings.opts = {
          enable_close = true;
          enable_rename = true;
          enable_close_on_slash = true;
        };
      };


      conform-nvim = {
        enable = true;
        settings = {
          formatters_by_ft = {
            lua = [ "stylua" ];
            python = [ "ruff_fix" "ruff_format" "ruff_organize_imports" ];
            rust = [ "rustfmt" ];
            javascript = [ "biome" ];
            typescript = [ "biome" ];
            javascriptreact = [ "biome" ];
            typescriptreact = [ "biome" ];
            nix = [ "nixpkgs_fmt" ];
            css = [ "prettier" ];
            scss = [ "prettier" ];
            html = [ "prettier" ];
          };
        };
      };

      lualine = {
        enable = true;
      };

      barbar = {
        enable = true;
      };

      commentary.enable = true;
      fugitive.enable = true;
      nvim-surround.enable = true;
      vim-visual-multi.enable = true;

      treesitter = {
        enable = true;
        settings = {
          highlight.enable = true;
          indent.enable = true;
        };
        grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
          nix
          css
          html
          javascript
          typescript
          tsx
          scss
        ];
      };

      web-devicons.enable = true;
      indent-blankline = {
        enable = true;
        settings = {
          indent.char = "│";
          indent.tab_char = "│";
          scope.enabled = false;
        };
      };
      neoscroll = {
        enable = true;
        settings = {
          mappings = [
            "<C-u>"
            "<C-d>"
            "<C-b>"
            "<C-f>"
            "<C-y>"
            "<C-e>"
            "zt"
            "zz"
            "zb"
          ];
          hide_cursor = true;
          stop_eof = true;
          respect_scrolloff = false;
          cursor_scrolls_alone = true;
          duration_multiplier = 0.35;
          easing = "linear";
          pre_hook = null;
          post_hook = null;
          performance_mode = false;
          ignored_events = [ "WinScrolled" "CursorMoved" ];
        };
      };
      auto-session.enable = false;

      luasnip = {
        enable = true;
        settings = {
          vscode-snippet-paths = [
            "${pkgs.vimPlugins.friendly-snippets}"
          ];
        };
      };

      blink-cmp = {
        enable = true;
        settings = {
          keymap = { preset = "default"; };
          appearance.nerd_font_variant = "mono";
          completion.documentation.auto_show = false;
          sources.default = [ "lsp" "path" "snippets" "buffer" ];
        };
      };

      lint = {
        enable = true;
        lintersByFt = {
          javascript = [ "eslint" ];
          typescript = [ "eslint" ];
          typescriptreact = [ "eslint" ];
          javascriptreact = [ "eslint" ];
        };
      };

      nvim-lightbulb.enable = true;

      trouble-nvim = {
        enable = true;
        settings = {
          command = "Trouble";
        };
      };

      coc-nvim.enable = false;

      emmet.enable = true;

      system-copy.enable = true;

      markview.enable = true;
    };

    extraPlugins = with pkgs.vimPlugins; [
      gruvbox-material
      nvim-lspconfig
      vim-wakatime
      (pkgs.vimUtils.buildVimPlugin {
        pname = "telescope-cc.nvim";
        version = "2024-11-16";
        src = pkgs.fetchFromGitHub {
          owner = "olacin";
          repo = "telescope-cc.nvim";
          rev = "c3cf3489178f945e3efdf0bd15bfb8c353279755";
          hash = "sha256-5l606k9jG1LKKwL5lCy45ZSWiEStbuqm1/tBQXOBpGA=";
        };
      })
      snacks-nvim
      opencode-nvim
      friendly-snippets
    ];

    extraPackages = with pkgs; [
      typescript-language-server
      tailwindcss-language-server
      nixd
      vscode-langservers-extracted
      eslint
    ];
  };
}

