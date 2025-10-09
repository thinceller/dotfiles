{ pkgs }:
{
  programs.tmux = {
    enable = true;

    baseIndex = 1;
    clock24 = true;
    customPaneNavigationAndResize = true;

    extraConfig = ''
      set -g set-titles on
      set -g renumber-windows on
      set -g set-clipboard on
      set -g copy-command 'pbcopy'
      setw -g pane-base-index 1

      bind -r C-h select-window -t :-
      bind -r C-l select-window -t :+
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
    '';

    keyMode = "vi";
    mouse = true;

    plugins = with pkgs; [
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
  };
}
