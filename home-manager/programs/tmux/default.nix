{ pkgs, ... }:
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
      # base
      set -g set-titles on
      set -g renumber-windows on
      set -g set-clipboard on
      set -g copy-command 'pbcopy'
      set -g status-position top
      set -g display-panes-time 10000
      set -g escape-time 1
      setw -g pane-base-index 1

      # keymaps
      bind -r C-h select-window -t :-
      bind -r C-l select-window -t :+
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind C new-session

      bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"
    '';

    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = tmux-powerline;
      }
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
    ];
  };
}
