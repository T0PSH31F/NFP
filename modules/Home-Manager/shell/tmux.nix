{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.tmux;
in
{
  programs.tmux = {
    enable = true;
    package = pkgs.tmux;

    # Use Ctrl+a as prefix (more ergonomic than Ctrl+b)
    prefix = "C-a";

    # Start window/pane indexing from 1
    baseIndex = 1;

    # Enable mouse support
    mouse = true;

    # Vi-style key bindings
    keyMode = "vi";

    # Larger scrollback buffer
    historyLimit = 50000;

    # Faster key response
    escapeTime = 0;

    # True color support
    terminal = "tmux-256color";

    # Clock mode settings
    clock24 = true;

    # Plugins via TPM
    plugins = with pkgs.tmuxPlugins; [
      sensible # Sensible defaults
      yank # System clipboard integration
      pain-control # Better pane navigation
      resurrect # Session persistence
      continuum # Automatic session saving
    ];

    extraConfig = ''
      # ============================================================================
      # DYNAMIC THEMING
      # ============================================================================

      # Source generated colors if they exist
      if-shell "test -f ~/.config/tmux/colors.conf" "source ~/.config/tmux/colors.conf"

      # Fallback defaults if colors not found (Material Dark)
      if-shell "test ! -f ~/.config/tmux/colors.conf" \
        "set -g status-style 'bg=#1e1e2e,fg=#cdd6f4'; \
         set -g status-left '#[bg=#89b4fa,fg=#1e1e2e,bold] #S #[bg=#1e1e2e,fg=#89b4fa] '; \
         set -g status-right '#[fg=#a6adc8,bg=#1e1e2e]#[bg=#a6adc8,fg=#1e1e2e] #H #[fg=#bac2de,bg=#a6adc8]#[bg=#bac2de,fg=#1e1e2e] %Y-%m-%d %H:%M '; \
         set -g window-status-format '#[fg=#a6adc8,bg=#1e1e2e] #I:#W '; \
         set -g window-status-current-format '#[fg=#1e1e2e,bg=#89b4fa]#[fg=#1e1e2e,bg=#89b4fa,bold] #I:#W #[fg=#89b4fa,bg=#1e1e2e,nobold]'; \
         set -g pane-border-style 'fg=#313244'; \
         set -g pane-active-border-style 'fg=#89b4fa'; \
         set -g message-style 'bg=#fab387,fg=#1e1e2e'"
      # ============================================================================
      # GENERAL SETTINGS
      # ============================================================================

      # Enable true color support
      set -ga terminal-overrides ",*256col*:Tc"
      set -ga terminal-overrides ",xterm-256color:Tc"
      set -ga terminal-overrides ",alacritty:Tc"
      set -ga terminal-overrides ",ghostty:Tc"

      # Focus events for nvim autoread
      set -g focus-events on

      # Automatic window renaming
      set -g automatic-rename on
      set -g renumber-windows on

      # Activity monitoring
      set -g monitor-activity on
      set -g visual-activity off

      # ============================================================================
      # KEY BINDINGS
      # ============================================================================

      # Reload config
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"

      # Split panes using | and -
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %

      # New window in current path
      bind c new-window -c "#{pane_current_path}"

      # Vim-style pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Resize panes with Shift+Arrow
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # Quick window switching
      bind -r C-h previous-window
      bind -r C-l next-window

      # Send prefix to nested tmux
      bind a send-prefix

      # ============================================================================
      # COPY MODE (VI-STYLE)
      # ============================================================================

      # Enter copy mode with prefix + v
      bind v copy-mode

      # Vi-style selection
      bind -T copy-mode-vi v send -X begin-selection
      bind -T copy-mode-vi C-v send -X rectangle-toggle
      bind -T copy-mode-vi y send -X copy-pipe-and-cancel "wl-copy"

      # Mouse selection copies to clipboard
      bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel "wl-copy"

      # ============================================================================
      # RESURRECT & CONTINUUM SETTINGS
      # ============================================================================

      # Restore neovim sessions
      set -g @resurrect-strategy-nvim 'session'

      # Restore pane contents
      set -g @resurrect-capture-pane-contents 'on'

      # Auto-save every 15 minutes
      set -g @continuum-save-interval '15'

      # Auto-restore on tmux start
      set -g @continuum-restore 'on'

      # ============================================================================
      # STATUS BAR
      # ============================================================================

      # Position
      set -g status-position bottom

      # Update interval
      set -g status-interval 1
    '';
  };
}
