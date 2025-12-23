{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    prefix = "C-Space";
    baseIndex = 1;
    newSession = true;
    escapeTime = 0;
    keyMode = "vi";
    mouse = true;
    terminal = "screen-256color";

    plugins = with pkgs.tmuxPlugins; [
      better-mouse-mode
      yank
      prefix-highlight
      {
        plugin = pkgs.tmuxPlugins.sysstat;
        extraConfig = ''
          set -g @sysstat_cpu_view_tmpl '#[fg=magenta]CPU:#[default] #[fg=#{cpu.color}]#{cpu.pused}#[default]'
          set -g @sysstat_mem_view_tmpl '#[fg=magenta]Mem:#[default] #[fg=#{mem.color}]#{mem.pused}#[default]'
          set -g status-interval 3
          set -g status-right '#{sysstat_cpu} #[fg=#858585]| #{sysstat_mem} #[fg=white,bg=#504945] %a %d %h %H:%M '
        '';
      }
    ];

    extraConfig = ''
      # Theme
      set -g status-justify "centre"
      set -g status "on"
      set -g status-left-style "none"
      set -g message-command-style "fg=#a89984,bg=#504945"
      set -g status-right-style "none"
      set -g pane-active-border-style "fg=#a89984"
      set -g status-style "none,bg=#3a3735"
      set -g message-style "fg=#a89984,bg=#504945"
      set -g pane-border-style "fg=#504945"
      set -g status-left-length "100"
      setw -g window-status-activity-style "underscore,fg=#a89984,bg=#3a3735"
      setw -g window-status-separator ""
      setw -g window-status-style "none,fg=#a89984,bg=#3a3735"
      setw -g window-status-format "#[fg=#3a3735,bg=#3a3735,nobold,nounderscore,noitalics] #[fg=#a89984] #I #W #[fg=#3a3735,bg=#3a3735,nobold,nounderscore,noitalics] "
      setw -g window-status-current-format "#[fg=#3a3735,bg=#504945,nobold,nounderscore,noitalics] #[fg=#a89984,bg=#504945] #I #W #F #[fg=#504945,bg=#3a3735,nobold,nounderscore,noitalics] "

      # Terminal overrides
      set -g terminal-overrides ',xterm-256color:Tc'
      set -as terminal-overrides ',xterm*:sitm=\E[3m'

      # Prefix Highlight Config
      set -g @prefix_highlight_fg 'colour00'
      set -g @prefix_highlight_bg 'colour01'
      set -g @prefix_highlight_show_copy_mode 'on'
      set -g @prefix_highlight_copy_mode_attr 'fg=colour00,bg=colour05,bold'
      set -g @prefix_highlight_prefix_prompt 'Prefix'
      set -g @prefix_highlight_copy_prompt 'Copy'

      # Pane navigation
      bind -r h select-pane -L
      bind -r j select-pane -D
      bind -r k select-pane -U
      bind -r l select-pane -R
      bind > swap-pane -D
      bind < swap-pane -U

      # Pane resizing
      bind -r H resize-pane -L 2
      bind -r J resize-pane -D 2
      bind -r K resize-pane -U 2
      bind -r L resize-pane -R 2

      # Open new windows in current path
      bind c new-window -c "#{pane_current_path}"
      bind '"' split-window -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"

      # Window navigation
      unbind n
      unbind p
      bind -r C-h previous-window
      bind -r C-l next-window

      # Status Bar / UI
      set -g status-justify left
      set -g pane-active-border-style fg=colour00,bg=default
      set -g status-left "#{?client_prefix,#[fg=colour00]#[bg=colour01] Prefix ,#{?pane_in_mode,#[default]#[fg=colour00]#[bg=colour05]#[bold] Copy ,#[default]#[fg=default]#[bg=default]}}#[default]#[fg=#282828,bg=#a89984]"
    '';
  };
}
