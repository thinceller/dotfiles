# oberon (サーバー) 用の OpenCode 設定。darwin 版 (default.nix) から
# vault (references / Mnemos) を除いたもの。
{
  pkgs,
  lib,
  config,
  ...
}:
{
  programs.opencode = {
    enable = true;
    package = import ./with-cli-config.nix { inherit pkgs lib; } {
      theme.name = "tokyonight";
      plugins = [ "${config.xdg.configHome}/opencode/herdr-opencode" ];
    };

    settings = {
      model = "opencode-go/gpt-5.6-luna";
      small_model = "opencode-go/deepseek-v4-flash";
      autoupdate = false;
      share = "manual";
      snapshot = true;

      plugin = [
        "superpowers@git+https://github.com/obra/superpowers.git"
      ];

      compaction = {
        auto = false;
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

  # release-25.11 の opencode module は config.json に書くが、v2 は opencode.json(c) しか読まない。
  xdg.configFile."opencode/config.json".target = "opencode/opencode.json";

  # herdr integration (opencode 側): default.nix と同じ。
  xdg.configFile."opencode/plugins/herdr-agent-state.js".source = ./plugins/herdr-agent-state.js;
  xdg.configFile."opencode/herdr-opencode".source = ./plugins/herdr-opencode;
}
