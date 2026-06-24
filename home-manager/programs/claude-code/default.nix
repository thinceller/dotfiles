{
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
  programs.claude-code = {
    enable = true;
    package = claudeCodePackage;

    settings = {
      theme = "dark";
      autoCompactEnabled = false;
      alwaysThinkingEnabled = true;
      language = "japanese";
      autoMemoryEnabled = false;
      cleanupPeriodDays = 9999;

      model = "opus";
      # advisorModel = "opus";
      # effortLevel = "xhigh";
      voiceEnabled = true;
      skipAutoPermissionPrompt = true;
      useAutoModeDuringPlan = true;

      # Claude Code 組み込み sandbox (macOS: Seatbelt)。
      # cage と二重に Seatbelt をネストすると失敗するため、これを使うときは
      # `cage claude` ではなく素の `claude` で起動すること。cage 設定
      # (configs/.config/cage/presets.yaml) は併用できるよう残してある。
      sandbox = {
        enabled = true;
        # sandbox 内で完結する Bash コマンドは許可プロンプトなしで自動実行
        autoAllowBashIfSandboxed = true;
        # sandbox 起因で失敗したコマンドは dangerouslyDisableSandbox での
        # unsandboxed 再実行を許す (escape hatch)。
        # ただし勝手には解除されない: dangerouslyDisableSandbox 付きの実行は
        # permissions.allow の明示ルールに一致する場合を除き、auto mode の
        # 自動承認より優先して必ず "ask" (確認プロンプト) に強制される
        # (バイナリ 2.1.170 の checkPermissions / sandboxOverride 実装で確認済み)。
        allowUnsandboxedCommands = true;
        excludedCommands = [
          # sandbox 非対応 (公式ドキュメント記載)
          "docker *"
          # macOS Seatbelt 下では Go 製 CLI の TLS 検証が失敗する
          "gh *"
          # nix-daemon socket / store 書き込みが sandbox と相性が悪い
          "nix *"
          "darwin-rebuild *"
        ];
        network = {
          # dev server 等の localhost バインドを許可
          allowLocalBinding = true;
          # 1Password SSH agent socket を許可し、sandbox 内の git commit でも
          # op-ssh-sign (agent 経由の SSH 署名) が動くようにする
          allowUnixSockets = [
            "${userConfig.homeDir}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
          ];
          # 未許可ドメインは初回にプロンプトが出て承認すると永続化されるので、
          # ここには頻出のものだけ事前許可しておく
          allowedDomains = [
            "github.com"
            "*.githubusercontent.com"
            "registry.npmjs.org"
          ];
        };
        filesystem = {
          # デフォルトで denyRead される ~/.ssh のうち known_hosts だけ read 再許可。
          # SSH 越しの git push でホスト鍵検証 (known_hosts 読み取り) が
          # sandbox にブロックされて失敗するのを防ぐ。秘密鍵は引き続き読めない。
          allowRead = [
            "~/.ssh/known_hosts"
          ];
          # Bash サブプロセスが書き込む実績のあるパス
          # (cage preset の allow リストから、メインプロセスが書くものを除いて移植)
          allowWrite = [
            "/tmp"
            "~/.claude"
            "~/.npm"
            "~/.bun"
            "~/.cache"
            "~/.config"
            "~/.local"
            "~/.codex"
            "~/Library/pnpm"
            "~/Library/Caches/ms-playwright"
          ];
        };
      };

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

    context = ./user-memory.md;

    # agentsDir = ./agents;
    skills = ./skills;
    # hooksDir = ./hooks;
  };
}
