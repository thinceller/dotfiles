{
  pkgs,
  lib,
  config,
  userConfig,
  ...
}:
lib.mkIf userConfig.isPersonal {
  programs.opencode = {
    enable = true;
    package = import ./with-cli-config.nix { inherit pkgs lib; } {
      theme.name = "tokyonight";
      mouse = true;
      attention = {
        notifications = false;
        sound = false;
      };
      plugins = [ "${config.xdg.configHome}/opencode/herdr-opencode" ];
    };

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
      model = "opencode-go/gpt-5.6-luna";
      small_model = "opencode-go/deepseek-v4-flash";
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

    context = ./AGENTS.md;

    # hunk 同梱の agent skill を opencode にも展開する。
    skills = {
      hunk-review = "${config.programs.hunk.package}/skills/hunk-review";
    };
  };

  # herdr integration (opencode 側): `herdr integration install opencode` が書き出すファイル相当
  # (v1 用の tui.json 登録は除く)。HERDR_INTEGRATION_VERSION=13, 上流で bump されたら更新する。
  # TUI plugin は cli 設定の plugins から読まれる。
  xdg.configFile."opencode/plugins/herdr-agent-state.js".source = ./plugins/herdr-agent-state.js;
  xdg.configFile."opencode/herdr-opencode".source = ./plugins/herdr-opencode;

  # Mnemos: セッションログ自動記録 (共用 worker vault-session-log-worker を呼ぶ)
  xdg.configFile."opencode/plugins/vault-session-log.ts" = {
    source = ./plugins/vault-session-log.ts;
  };
}
