# darwin 専用の fish 設定。portable 部分は common.nix にある。
{
  config,
  ...
}:
{
  imports = [ ./common.nix ];

  programs.fish = {
    functions = {
      scc = {
        body = ''
          set git_root (git rev-parse --show-toplevel 2>/dev/null)
          if test $status -eq 0
            cd $git_root
            # sandbox-exec が /bin/ps をブロックするため ccstatusline の
            # ターミナル幅検出が失敗する。COLUMNS を明示的に渡して回避。
            set -x COLUMNS (tput cols)
            cage claude --dangerously-skip-permissions $argv
          else
            echo "Not in a git repository"
            return 1
          end
        '';
        description = "Move to git root and run claude via cage sandbox";
      };
    };
    shellAbbrs = {
      ccc = "cage claude";
    };
    interactiveShellInit = ''
      fish_add_path /opt/homebrew/bin
      fish_add_path /Applications/Obsidian.app/Contents/MacOS
      fish_add_path /Applications/Ghostty.app/Contents/MacOS
      wt config shell init fish | source
      op completion fish | source
      export TEST=$(cat ${config.sops.secrets.test.path})
      export DISCORD_BOT_TOKEN=$(cat ${config.sops.secrets.discord-bot-token.path})
    '';
  };
}
