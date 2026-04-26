{
  pkgs,
  sources,
  ...
}:
let
  tmux-agent-sidebar = import ./plugins/tmux-agent-sidebar { inherit pkgs sources; };

  tmux-switch-session = pkgs.writeShellScript "tmux-switch-session" ''
    session=$(
      tcmux list-sessions --color=always \
      | fzf --ansi --tmux 80%,80% --layout reverse \
          --preview 'session_name=$(echo {} | sed "s/: .*//"); tcmux list-windows -t "$session_name" --color=always; echo ""; echo "─── Active Pane ───"; tmux capture-pane -t "$session_name:" -p -e'
    )
    if [ -n "$session" ]; then
      session_name=$(echo "$session" | sed 's/: .*//')
      tmux switch-client -t "$session_name"
    fi
  '';

  tmux-switch-window = pkgs.writeShellScript "tmux-switch-window" ''
    window=$(
      tcmux list-windows -a --color=always \
        -F '#{session_name}:#{window_index}: #{window_name} (#{window_panes} panes) #{agent_status}' \
      | fzf --ansi --tmux 80%,80% --layout reverse \
          --preview 'target=$(echo {} | sed "s/: .*//"); tmux capture-pane -t "$target" -p -e'
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
      set -g allow-passthrough on
      set -g focus-events on
      set -s extended-keys on
      set -as terminal-features 'xterm*:extkeys'
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
      bind s run-shell "${tmux-switch-session}"
      bind S choose-tree -Zs

      # tcmux: list and switch to coding agent windows across all sessions
      bind w run-shell "${tmux-switch-window}"

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
        plugin = tokyo-night-tmux.overrideAttrs (old: {
          postInstall = (old.postInstall or "") + ''
            # Fix: patch shebangs to use Nix bash (5.x) instead of macOS /bin/bash (3.2)
            # bash 3.2 doesn't support declare -A (associative arrays) used in themes.sh
            find $out -type f \( -name '*.sh' -o -name '*.tmux' \) -exec \
              sed -i 's|#!/usr/bin/env bash|#!${pkgs.bash}/bin/bash|' {} +
          '';
        });
        extraConfig = ''
          set -g @tokyo-night-tmux_window_id_style "fsquare"
        '';
      }
      tmux-agent-sidebar.plugin
    ];
  };

  home.packages = [ tmux-agent-sidebar.package ];
}
