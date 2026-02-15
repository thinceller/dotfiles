{ pkgs, ... }:
let
  tmux-switch-session = pkgs.writeShellScript "tmux-switch-session" ''
    session=$(
      tcmux list-sessions --color=always \
      | fzf --ansi --tmux 80%,50% --layout reverse \
          --preview 'echo {} | sed "s/: .*//" | xargs -I@ tcmux list-windows -t @ --color=always'
    )
    if [ -n "$session" ]; then
      session_name=$(echo "$session" | sed 's/: .*//')
      tmux switch-client -t "$session_name"
    fi
  '';

  tmux-switch-window = pkgs.writeShellScript "tmux-switch-window" ''
    window=$(
      tcmux list-windows -a --color=always \
      | fzf --ansi --tmux 80%,50% --layout reverse
    )
    if [ -n "$window" ]; then
      window_name=$(echo "$window" | sed 's/: .*//')
      tmux switch-client -t "$window_name"
    fi
  '';
in
{
  programs.tmux = {
    enable = true;

    baseIndex = 1;
    clock24 = true;
    customPaneNavigationAndResize = true;
    keyMode = "vi";
    mouse = true;
    prefix = "C-j";
    terminal = "xterm-256color";

    extraConfig = ''
      # true color support
      set -ga terminal-overrides ",*:Tc"

      # base
      set -g set-titles on
      set -g renumber-windows on
      set -g set-clipboard on
      set -g copy-command 'pbcopy'
      set -g status-position top
      set -g display-panes-time 10000
      set -g escape-time 1
      setw -g pane-base-index 1

      # pane focus highlighting
      set -g window-style 'bg=#222436'
      set -g window-active-style 'bg=#1a1b26'
      set -g pane-border-indicators colour

      # keymaps
      bind -r C-h select-window -t :-
      bind -r C-l select-window -t :+
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind C new-session

      # tcmux: list and switch to sessions with window preview
      bind S run-shell "${tmux-switch-session}"

      # tcmux: list and switch to coding agent windows across all sessions
      bind w run-shell "${tmux-switch-window}"

      bind -n S-Enter send-keys Escape "[13;2u"

      bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"
    '';

    plugins = with pkgs.tmuxPlugins; [
      # {
      #   plugin = tmux-powerline;
      # }
      {
        plugin = tmux-fzf;
      }
      {
        plugin = resurrect;
        extraConfig = "set -g @resurrect-strategy-nvim 'session'";
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '60'
        '';
      }
      {
        plugin = urlview;
      }
      {
        plugin = tokyo-night-tmux;
        extraConfig = ''
          set -g @tokyo-night-tmux_window_id_style "fsquare"
        '';
      }
    ];
  };
}
