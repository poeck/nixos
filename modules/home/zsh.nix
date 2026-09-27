{ pkgs, ... }:
let
  sudoAskpass = pkgs.writeShellScript "sudo-askpass" ''
    printf -v context 'Action: %s\nRun as: %s\nDirectory: %s\n\n%s' \
      "''${SUDO_ASKPASS_ACTION:-Sudo request}" \
      "''${SUDO_ASKPASS_TARGET:-root}" \
      "''${SUDO_ASKPASS_DIRECTORY:-unknown}" \
      "''${1:-Enter your sudo password}"

    exec ${pkgs.zenity}/bin/zenity --entry --hide-text \
      --title="Authentication Required" \
      --width=480 \
      --text="$context"
  '';

  graphicalSudo = pkgs.writeShellScriptBin "sudo" ''
    if [ -n "''${WAYLAND_DISPLAY:-}''${DISPLAY:-}" ]; then
      sudo_args=( "$@" )
      target=root
      action="Sudo request"

      # Display only the program name; command arguments can contain secrets.
      while (( $# )); do
        case "$1" in
          --) shift; break ;;
          -u|--user)
            if (( $# < 2 )); then break; fi
            target=$2
            shift 2 ;;
          --user=*) target=''${1#*=}; shift ;;
          -u?*) target=''${1#-u}; shift ;;
          -g|--group|-C|--close-from|-D|--chdir|-p|--prompt|-R|--chroot|-r|--role|-t|--type)
            if (( $# < 2 )); then break; fi
            shift 2 ;;
          --*=*) shift ;;
          -v|--validate) action="Validate sudo credentials"; shift ;;
          -e|--edit) action="Edit files with sudo"; shift ;;
          -s|--shell|-i|--login) action="Open a shell"; shift ;;
          -A|-B|-b|-E|-H|-K|-k|-n|-P|-S) shift ;;
          -*) break ;;
          *) break ;;
        esac
      done

      if [ "$action" = "Sudo request" ] && (( $# )); then
        printf -v action 'Run %q' "$1"
      fi

      printf -v target_label '%q' "$target"
      printf -v directory_label '%q' "$PWD"

      export SUDO_ASKPASS=${sudoAskpass}
      export SUDO_ASKPASS_ACTION="$action"
      export SUDO_ASKPASS_TARGET="$target_label"
      export SUDO_ASKPASS_DIRECTORY="$directory_label"
      exec /run/wrappers/bin/sudo -A "''${sudo_args[@]}"
    fi

    exec /run/wrappers/bin/sudo "$@"
  '';
in
{
  home.packages = [ graphicalSudo ];

  programs.zsh = {
    enable = true;
    # enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # .zshenv also runs for non-interactive shells used by coding agents.
    envExtra = ''
      path=( ${graphicalSudo}/bin ''${path:#${graphicalSudo}/bin} )
    '';

    plugins = [
      {
        # Must be before plugins that wrap widgets, such as zsh-autosuggestions or fast-syntax-highlighting
        name = "fzf-tab";
        src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
      }
      {
        name = "zsh-autopair";
        src = "${pkgs.zsh-autopair}/share/zsh/zsh-autopair";
        file = "autopair.zsh";
      }
    ];

    completionInit = ''
      # Load Zsh modules
      # zmodload zsh/zle
      # zmodload zsh/zpty
      # zmodload zsh/complist

      # Initialize colors
      autoload -Uz colors
      colors

      # Initialize completion system
      # autoload -U compinit
      # compinit
      _comp_options+=(globdots)

      # Load edit-command-line for ZLE
      autoload -Uz edit-command-line
      zle -N edit-command-line
      bindkey "^e" edit-command-line

      # General completion behavior
      zstyle ':completion:*' completer _extensions _complete _approximate

      # Use cache
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/.zcompcache"

      # Complete the alias
      zstyle ':completion:*' complete true

      # Autocomplete options
      zstyle ':completion:*' complete-options true

      # Completion matching control
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
      zstyle ':completion:*' keep-prefix true

      # Group matches and describe
      zstyle ':completion:*' menu select
      zstyle ':completion:*' list-grouped false
      zstyle ':completion:*' list-separator '''
      zstyle ':completion:*' group-name '''
      zstyle ':completion:*' verbose yes
      zstyle ':completion:*:matches' group 'yes'
      zstyle ':completion:*:warnings' format '%F{red}%B-- No match for: %d --%b%f'
      zstyle ':completion:*:messages' format '%d'
      zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b'
      zstyle ':completion:*:descriptions' format '[%d]'

      # Colors
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}

      # Directories
      zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
      zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
      zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'
      zstyle ':completion:*:*:-command-:*:*' group-order aliases builtins functions commands
      zstyle ':completion:*' special-dirs true
      zstyle ':completion:*' squeeze-slashes true

      # Sort
      zstyle ':completion:*' sort false
      zstyle ":completion:*:git-checkout:*" sort false
      zstyle ':completion:*' file-sort modification
      zstyle ':completion:*:eza' sort false
      zstyle ':completion:complete:*:options' sort false
      zstyle ':completion:files' sort false

      # fzf-tab
      zstyle ':fzf-tab:*' use-fzf-default-opts yes
      zstyle ':fzf-tab:complete:*:*' fzf-preview 'eza --icons  -a --group-directories-first -1 --color=always $realpath'
      zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps --pid=$word -o cmd --no-headers -w -w'
      zstyle ':fzf-tab:complete:kill:argument-rest' fzf-flags '--preview-window=down:3:wrap'
      zstyle ':fzf-tab:*' fzf-command fzf
      zstyle ':fzf-tab:*' fzf-pad 4
      zstyle ':fzf-tab:*' fzf-min-height 100
      zstyle ':fzf-tab:*' switch-group ',' '.'
    '';

    initContent = ''
      # NixOS setuid programs, such as sudo, live in /run/wrappers/bin.
      path=(/run/wrappers/bin ''${path:#/run/wrappers/bin})
      path=( ${graphicalSudo}/bin ''${path:#${graphicalSudo}/bin} )

      DISABLE_AUTO_UPDATE=true
      DISABLE_MAGIC_FUNCTIONS=true
      export "MICRO_TRUECOLOR=1"

      # Load the Sentry token at runtime so it stays out of the Nix store.
      if [[ -r "$HOME/.config/secrets/sentry-token" ]]; then
        export SENTRY_AUTH_TOKEN="$(cat "$HOME/.config/secrets/sentry-token")"
      fi

      # Bind Ctrl + Left Arrow to move back one word
      bindkey "^[[1;5D" backward-word
      # Bind Ctrl + Right Arrow to move forward one word
      bindkey "^[[1;5G" forward-word

      # Disable mouse support in zsh to let tmux handle scrolling
      # This prevents mouse scroll events from being interpreted as arrow keys
      # When running inside tmux, ensure mouse events are handled by tmux, not zsh
      if [[ -n "$TMUX" ]]; then
        # Disable mouse reporting so tmux can handle all mouse events
        printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l' > /dev/tty
      fi

      setopt sharehistory
      setopt hist_ignore_space
      setopt hist_ignore_all_dups
      setopt hist_save_no_dups
      setopt hist_ignore_dups
      setopt hist_find_no_dups
      setopt hist_expire_dups_first
      setopt hist_verify

      # Use fd (https://github.com/sharkdp/fd) for listing path candidates.
      # - The first argument to the function ($1) is the base path to start traversal
      # - See the source code (completion.{bash,zsh}) for the details.
      _fzf_compgen_path() {
        fd --hidden --exclude .git . "$1"
      }

      # Use fd to generate the list for directory completion
      _fzf_compgen_dir() {
        fd --type=d --hidden --exclude .git . "$1"
      }

      # Advanced customization of fzf options via _fzf_comprun function
      # - The first argument to the function is the name of the command.
      # - You should make sure to pass the rest of the arguments to fzf.
      _fzf_comprun() {
        local command=$1
        shift

        case "$command" in
          cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
          ssh)          fzf --preview 'dig {}'                   "$@" ;;
          *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
        esac
      }

      # Make sure that the terminal is in application mode when zle is active, since
      # only then values from $terminfo are valid
      if (( ''${+terminfo[smkx]} )) && (( ''${+terminfo[rmkx]} )); then
        function zle-line-init() {
          echoti smkx
        }
        function zle-line-finish() {
          echoti rmkx
        }
        zle -N zle-line-init
        zle -N zle-line-finish
      fi
    '';
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}
