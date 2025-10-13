{ pkgs }:
{
  programs.tmux = {
    enable = true;

    baseIndex = 1;
    clock24 = true;
    customPaneNavigationAndResize = true;

    extraConfig = ''
      # base
      set -g set-titles on
      set -g renumber-windows on
      set -g set-clipboard on
      set -g copy-command 'pbcopy'
      set -g status-position top
      setw -g pane-base-index 1

      # keymaps
      bind -r C-h select-window -t :-
      bind -r C-l select-window -t :+
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind C new-session

      bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"
    '';

    keyMode = "vi";
    mouse = true;

    plugins = with pkgs; [
      {
        plugin = tmuxPlugins.tmux-powerline;
      }
      {
        plugin = tmuxPlugins.tmux-fzf;
      }
      {
        plugin = tmuxPlugins.resurrect;
        extraConfig = "set -g @resurrect-strategy-nvim 'session'";
      }
      {
        plugin = tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '60'
        '';
      }
    ];

    prefix = "C-j";
    terminal = "xterm-256color";
  };
}
