{
  pkgs,
  lib,
  sources,
  userConfig,
  ...
}:
lib.mkIf userConfig.isPersonal {
  programs.opencode = {
    enable = true;
    package = pkgs.opencode;

    extraPackages = with pkgs; [
      git
      gh
      ripgrep
    ];

    settings = {
      model = "opencode-go/kimi-k2.7-code";
      autoupdate = false;
      share = "manual";
      snapshot = true;

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

    tui = {
      theme = "tokyonight";
      mouse = true;
      attention = {
        enabled = false;
      };
    };

    context = ./AGENTS.md;
  };

  xdg.configFile."opencode/plugins/tmux-agent-sidebar.js" = {
    source = "${sources.tmux-agent-sidebar.src}/.opencode/plugins/tmux-agent-sidebar.js";
  };
}
