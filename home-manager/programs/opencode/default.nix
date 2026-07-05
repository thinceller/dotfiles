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

    # NOTE: enquire-mcp (obsidian-vault) は Claude Code 側でのみ MCP 統合。
    # OpenCode 側で有効にすると、enquire-mcp の z.tuple スキーマ
    # (obsidian_read_pdf/obsidian_ocr_pdf の pages) を opencode-go バックエンド
    # (GLM-5.2/MiniMax-M3) の XGrammar が拒否してツールコールが壊れる。
    # 上流修正 (PR) が入るまで OpenCode からは @vault reference 経由のみ。
    # enableMcpIntegration = true;

    extraPackages = with pkgs; [
      git
      gh
      ripgrep
    ];

    settings = {
      model = "opencode-go/glm-5.2";
      small_model = "opencode-go/minimax-m3";
      autoupdate = false;
      share = "manual";
      snapshot = true;

      plugin = [
        "superpowers@git+https://github.com/obra/superpowers.git"
      ];

      # Obsidian vault を reference として公開。
      # @vault 補完で直接ファイル参照可能。MCP ツール (obsidian_*) は概念検索向き、
      # references はリテラルパス参照向き。
      references = {
        vault = {
          path = "${userConfig.homeDir}/src/github.com/thinceller/knowledge-base";
          description = "Obsidian knowledge vault (Karpathy LLM Wiki pattern) — Notes/, Clippings/, Agents/, Shared/. Search via obsidian-vault MCP tools for conceptual recall, or use @vault for direct file access.";
        };
      };

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

  # Mnemos: セッションログ自動記録 (共用 worker vault-session-log-worker を呼ぶ)
  xdg.configFile."opencode/plugins/vault-session-log.ts" = {
    source = ./plugins/vault-session-log.ts;
  };
}
