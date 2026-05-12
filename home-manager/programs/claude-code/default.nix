{
  config,
  pkgs,
  lib,
  userConfig,
  ...
}:
let
  inherit (userConfig) isPersonal;

  openPlanScript = pkgs.writeShellScript "claude-open-plan" (builtins.readFile ./hooks/open-plan.sh);
  statuslineScript = pkgs.writeShellScript "claude-statusline" (
    builtins.readFile ./statusline-command.sh
  );

  # Override edgepkgs' wrapProgram to place the binary in libexec/ instead of
  # renaming it to .claude-wrapped. This preserves the process name as "claude"
  # (via p_comm), which tools like tcmux rely on for session detection.
  claudeCodePackage = pkgs.edge.claude-code-bin.overrideAttrs (_old: {
    installPhase = ''
      runHook preInstall

      mkdir -p $out/libexec $out/bin
      install -m755 $src $out/libexec/claude

      makeBinaryWrapper $out/libexec/claude $out/bin/claude \
        --inherit-argv0 \
        --set DISABLE_AUTOUPDATER 1 \
        --set USE_BUILTIN_RIPGREP 0 \
        --set DISABLE_INSTALLATION_CHECKS 1 \
        --prefix PATH : ${
          pkgs.lib.makeBinPath (
            with pkgs;
            [
              procps
              ripgrep
            ]
          )
        }

      runHook postInstall
    '';
  });
in
{
  # home-manager の programs.claude-code は enableMcpIntegration を有効にすると
  # claude バイナリを `--plugin-dir <hm-plugin>` 付きで起動する bash wrapper で
  # 包む。このフラグが Claude Code v2.1.139 の Agent View TUI を阻害して、
  # 起動時に agent 定義の静的フォールバック表示に落ちる。
  # 回避策として MCP 統合 wrapper を切り、user スコープ (~/.claude.json) に
  # 下の home.activation で直接マージする。
  programs.claude-code = {
    enable = true;
    package = claudeCodePackage;
    enableMcpIntegration = false;

    settings = {
      theme = "dark";
      autoCompactEnabled = false;
      enableAllProjectMcpServers = true;
      alwaysThinkingEnabled = true;
      language = "japanese";
      autoMemoryEnabled = true;
      cleanupPeriodDays = 9999;

      # model = "opus";
      # advisorModel = "opus";
      effortLevel = "xhigh";
      voiceEnabled = true;
      skipAutoPermissionPrompt = true;

      # sandbox = {
      #   enabled = true;
      #   excludedCommands = [
      #     "docker"
      #     "git"
      #     "gh"
      #     "nix"
      #   ];
      #   network = {
      #     allowLocalBinding = true;
      #   };
      # };

      permissions = {
        allow = [
          "WebFetch"
          "WebSearch"
          "Bash(ls:*)"
          "Bash(grep:*)"
          "Bash(playwright-cli:*)"
        ];
        ask = [
          "Bash(rm:*)"
          "Bash(git merge:*)"
          "Bash(git rebase:*)"
          "Bash(git push:*)"
        ];
        deny = [
          "Read(~/.ssh/**)"
          "Read(.env*)"
          "Bash(sudo:*)"
          "Bash(git commit --no-gpg-sign:*)"
          "Write(~/.ssh/**)"
          "Write(.env*)"
        ];
        defaultMode = "auto";
      };

      env = {
        BASH_DEFAULT_TIMEOUT_MS = "60000";
        BASH_MAX_TIMEOUT_MS = "180000";
        CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR = "1";
        USE_BUILTIN_RIPGREP = "1";

        ANTHROPIC_DEFAULT_OPUS_MODEL = "claude-opus-4-7[1m]";

        ENABLE_TOOL_SEARCH = true;
        ENABLE_EXPERIMENTAL_MCP_CLI = false;
        CLAUDE_CODE_ENABLE_TASKS = true;
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
        CLAUDE_CODE_NEW_INIT = "1";
        CLAUDE_CODE_NO_FLICKER = "1";

        # codex-plugin-cc が thread/start に sandbox: "read-only" 等を強制送信し、
        # cage の中で codex 内部の Seatbelt をネストしようとして失敗するため、
        # plugin 経由のときだけ sandbox を danger-full-access に切り替える。
        # cage が外側で十分に守っており codex の内部 sandbox は冗長。
        # CLI 直接利用 (`codex` / `codex exec` 等) はこの env を読まないため
        # 通常通りデフォルト sandbox が適用される。
        # See: https://github.com/openai/codex-plugin-cc/pull/241
        CODEX_COMPANION_SANDBOX_MODE = "danger-full-access";
      };

      hooks = {
        PreToolUse = [
          {
            matcher = "ExitPlanMode";
            hooks = [
              {
                type = "command";
                command = openPlanScript;
              }
            ];
          }
        ];
      };

      statusLine = {
        type = "command";
        command = statuslineScript;
      };

      extraKnownMarketplaces = {
        "thinceller-claude-plugins" = {
          source = {
            source = "github";
            repo = "thinceller/claude-plugins";
          };
        };
        "superpowers-dev" = {
          source = {
            source = "github";
            repo = "obra/superpowers";
          };
        };
        "hiroppy" = {
          source = {
            source = "github";
            repo = "hiroppy/tmux-agent-sidebar";
          };
        };
      }
      // lib.optionalAttrs isPersonal {
        "openai-codex" = {
          source = {
            source = "github";
            # PR #241 (CODEX_COMPANION_SANDBOX_MODE 対応) を取り込んだ fork。
            # upstream にマージされたら "openai/codex-plugin-cc" に戻す。
            repo = "thinceller/codex-plugin-cc";
          };
        };
      };

      enabledPlugins = {
        # claude-plugins-official
        "claude-code-setup@claude-plugins-official" = true;
        "claude-md-management@claude-plugins-official" = true;
        "plugin-dev@claude-plugins-official" = true;
        "skill-creator@claude-plugins-official" = true;
        "frontend-design@claude-plugins-official" = true;
        "ralph-loop@claude-plugins-official" = true;
        "code-simplifier@claude-plugins-official" = true;
        # "code-review@claude-plugins-official" = true;
        # "pr-review-toolkit@claude-plugins-official" = true;
        "discord@claude-plugins-official" = true;

        # superpowers-dev
        "superpowers@superpowers-dev" = true;

        # thinceller-claude-plugins
        "git-toolkit@thinceller-claude-plugins" = true;

        # hiroppy
        "tmux-agent-sidebar@hiroppy" = true;
      }
      // lib.optionalAttrs isPersonal {
        "codex@openai-codex" = true;
      };
    };

    memory.source = ./user-memory.md;

    # agentsDir = ./agents;
    skillsDir = ./skills;
    # hooksDir = ./hooks;
  };

  # programs.claude-code.enableMcpIntegration を false にした代わりに、
  # mcp-servers-nix が生成した programs.mcp.servers を user スコープ
  # (~/.claude.json の mcpServers) にマージする。
  # Claude Code は ~/.claude.json を稼働中の状態ファイルとして書き換えるため、
  # 全置換は不可。jq でキー単位に merge する。
  home.activation.claudeCodeMcpUserScope =
    let
      mcpJson = builtins.toJSON (config.programs.mcp.servers or { });
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      CLAUDE_JSON="$HOME/.claude.json"
      if [ ! -f "$CLAUDE_JSON" ]; then
        echo '{}' > "$CLAUDE_JSON"
      fi
      TMP="$(${pkgs.coreutils}/bin/mktemp)"
      ${pkgs.jq}/bin/jq \
        --argjson new ${lib.escapeShellArg mcpJson} \
        '.mcpServers = ((.mcpServers // {}) * $new)' \
        "$CLAUDE_JSON" > "$TMP"
      ${pkgs.coreutils}/bin/mv "$TMP" "$CLAUDE_JSON"
    '';
}
