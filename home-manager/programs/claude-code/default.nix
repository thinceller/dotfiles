{
  pkgs,
  lib,
  userConfig,
  ...
}:
let
  inherit (userConfig) isPersonal;

  openPlanScript = pkgs.writeShellScript "claude-open-plan" (builtins.readFile ./hooks/open-plan.sh);
  vaultSessionLogScript = pkgs.writeShellScript "claude-vault-session-log" (
    builtins.readFile ./hooks/vault-session-log.sh
  );
  # Mnemos: セッションログ自動記録の共用 worker。Claude Code の hook と
  # OpenCode の plugin (home-manager/programs/opencode/) の両方から
  # PATH 上の `vault-session-log-worker` として呼ばれる。
  vaultSessionLogWorker = pkgs.writeShellScriptBin "vault-session-log-worker" (
    builtins.readFile ./scripts/vault-session-log-worker.sh
  );
  statuslineScript = pkgs.writeShellScript "claude-statusline" (
    builtins.readFile ./statusline-command.sh
  );

  # herdr integration (Claude Code): `herdr integration install claude` が
  # 書き出す ~/.claude/hooks/herdr-agent-state.sh と等価。上流 (ogulcancelik/herdr,
  # src/integration/assets/claude/herdr-agent-state.sh) を vendor しており、
  # HERDR_INTEGRATION_VERSION=7。上流で version が bump されたらファイルごと更新する。
  herdrAgentStateScript = pkgs.writeShellScript "claude-herdr-agent-state" (
    builtins.readFile ./hooks/herdr-agent-state.sh
  );

  # `herdr integration install claude` が settings.json に登録する hook 群
  # (src/integration/targets.rs::install_claude と一致)。
  # 引数はエージェント状態のヒントで、SessionStart 以外の呼び出しは script 内で
  # 早期 exit するが、上流と同じ登録セットを再現しておく。
  herdrClaudeHook = arg: {
    matcher = "*";
    hooks = [
      {
        type = "command";
        command = "${herdrAgentStateScript} ${arg}";
        timeout = 10;
      }
    ];
  };
  herdrClaudeHooks = {
    SessionStart = [ (herdrClaudeHook "session") ];
    Stop = [ (herdrClaudeHook "idle") ];
    SubagentStop = [ (herdrClaudeHook "working") ];
    SessionEnd = [ (herdrClaudeHook "release") ];
    UserPromptSubmit = [ (herdrClaudeHook "working") ];
    PreToolUse = [ (herdrClaudeHook "working") ];
    PostToolUse = [ (herdrClaudeHook "working") ];
  };

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
  home.packages = lib.optionals isPersonal [ vaultSessionLogWorker ];

  programs.claude-code = {
    enable = true;
    package = claudeCodePackage;

    settings = {
      theme = "dark";
      autoCompactEnabled = false;
      alwaysThinkingEnabled = true;
      language = "japanese";
      autoMemoryEnabled = true;
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
          # pre-commit の unstaged-stash が Read(.env*) / Claude Code の built-in
          # deny (`./secrets`, `**/*.key` 等) に阻まれて "unable to create file
          # ...: File exists" で ロールバックする。
          # git commit -> pre-commit -> git stash が .envrc / secrets/*.yaml を
          # 読み書きできず、hook 完走後の git checkout でツリーを復元できない
          # (2026-07-16 実測)。git commit の deny (Bash(git commit --no-gpg-sign:*))
          # は残っているので、GPG 署名バイパスなどの経路は引き続き遮断される。
          "git commit *"
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
          ]
          ++ lib.optionals isPersonal [
            "${userConfig.homeDir}/src/github.com/thinceller/knowledge-base"
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
          ]
          ++ lib.optionals isPersonal [
            "${userConfig.homeDir}/src/github.com/thinceller/knowledge-base"
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

        # wrapper の --set DISABLE_AUTOUPDATER は wrapper 経由の起動しか守れない。
        # native binary (chrome-native-host 等) も settings.json の env は読むため、
        # ここで無効化しないと updater が ~/.local/bin/claude を再生成し
        # Nix wrapper を PATH shadow する (2026-06-28, 2026-07-05 に再発)。
        DISABLE_AUTOUPDATER = "1";

        ENABLE_TOOL_SEARCH = true;
        CLAUDE_CODE_ENABLE_TASKS = true;
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
        CLAUDE_CODE_NEW_INIT = "1";
        CLAUDE_CODE_NO_FLICKER = "1";
        CLAUDE_AFK_TIMEOUT_MS = "86400000";

        # codex-plugin-cc が thread/start に sandbox: "read-only" 等を強制送信し、
        # cage の中で codex 内部の Seatbelt をネストしようとして失敗するため、
        # plugin 経由のときだけ sandbox を danger-full-access に切り替える。
        # cage が外側で十分に守っており codex の内部 sandbox は冗長。
        # CLI 直接利用 (`codex` / `codex exec` 等) はこの env を読まないため
        # 通常通りデフォルト sandbox が適用される。
        # See: https://github.com/openai/codex-plugin-cc/pull/241
        CODEX_COMPANION_SANDBOX_MODE = "danger-full-access";
      };

      hooks =
        herdrClaudeHooks
        // {
          # herdr の汎用 PreToolUse エントリと、既存の ExitPlanMode 用エントリを共存させる。
          PreToolUse = herdrClaudeHooks.PreToolUse ++ [
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
        }
        // lib.optionalAttrs isPersonal {
          # Mnemos: vault へのセッションログ自動記録。
          # Stop はデバウンス付き (30 分に 1 回まで)、SessionEnd で最終更新。
          # 実処理は detach した worker が headless claude (haiku) で行うため
          # セッションをブロックしない。詳細は hooks/vault-session-log.sh 冒頭。
          Stop = herdrClaudeHooks.Stop ++ [
            {
              hooks = [
                {
                  type = "command";
                  command = vaultSessionLogScript;
                }
              ];
            }
          ];
          SessionEnd = herdrClaudeHooks.SessionEnd ++ [
            {
              hooks = [
                {
                  type = "command";
                  command = vaultSessionLogScript;
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

    agentsDir = ./agents;
    skills = ./skills;
    # hooksDir = ./hooks;
  }
  // lib.optionalAttrs isPersonal {
    # programs.mcp.servers (obsidian-vault) を Claude Code に統合。
    # 過去に --plugin-dir wrapper が Agent View TUI を破壊した経緯がある
    # (commit 726976b, Claude Code v2.1.139)。v2.1.195 で再試行し、
    # 再発したら enableMcpIntegration=false + home.activation jq マージに切り替える。
    # 既存の codex plugin 有効化 (extraKnownMarketplaces) と同じゲート体制。
    enableMcpIntegration = true;
  };
}
