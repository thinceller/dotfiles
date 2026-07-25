# oberon (サーバー) 用の OpenCode 設定。darwin 版 (default.nix) から
# vault (references / Mnemos) / tmux-agent-sidebar を除いたもの。
{
  pkgs,
  config,
  ...
}:
{
  programs.opencode = {
    enable = true;
    package = pkgs.opencode;

    settings = {
      model = "opencode-go/glm-5.2";
      small_model = "opencode-go/minimax-m3";
      theme = "tokyonight";
      autoupdate = false;
      share = "manual";
      snapshot = true;

      plugin = [
        "superpowers@git+https://github.com/obra/superpowers.git"
      ];

      compaction = {
        auto = false;
        prune = false;
      };

      permission = {
        bash = {
          "*" = "ask";
          "ls*" = "allow";
          "grep*" = "allow";
          "git status*" = "allow";
          "git diff*" = "allow";
          "git log*" = "allow";
          "rm*" = "ask";
          "git merge*" = "ask";
          "git rebase*" = "ask";
          "git push*" = "ask";
          "sudo*" = "deny";
        };
        webfetch = "allow";
        websearch = "allow";
        read = {
          "*" = "allow";
          "*.env" = "deny";
          "*.env.*" = "deny";
          "~/.ssh/**" = "deny";
        };
        edit = {
          "*" = "allow";
          "*.env*" = "deny";
          "~/.ssh/**" = "deny";
        };
        external_directory = "ask";
      };

      watcher = {
        ignore = [
          "node_modules/**"
          ".git/**"
          "dist/**"
          "build/**"
        ];
      };
    };

    rules = ./AGENTS.md;

    # release-25.11 の opencode module に skills オプションが無いため見送り。
  };

  # herdr integration (opencode 側): `herdr integration install opencode` が
  # 書き出す ~/.config/opencode/plugins/herdr-agent-state.js と等価。
  xdg.configFile."opencode/plugins/herdr-agent-state.js" = {
    source = ./plugins/herdr-agent-state.js;
  };
}
