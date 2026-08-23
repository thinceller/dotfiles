{
  pkgs,
  lib,
  config,
  userConfig,
  ...
}:
let
  inherit (userConfig) isPersonal;

  common = import ./common.nix { inherit pkgs; };
  herdrClaudeHooks = common.herdrIntegration.hooks;

  # ローカル ./skills 配下の各 skill ディレクトリを attrset として展開し、
  # hunk パッケージ同梱の agent skill (hunk-review) をマージする。
  # 上流の home-manager モジュールは `skills` を attrs か path の
  # いずれでも受けるので、attrs 形式に統一して両立させている。
  localSkills = lib.mapAttrs (name: _type: ./skills + "/${name}") (
    lib.filterAttrs (_name: type: type == "directory") (builtins.readDir ./skills)
  );

  vaultSessionLogScript = pkgs.writeShellScript "claude-vault-session-log" (
    builtins.readFile ./hooks/vault-session-log.sh
  );
  # Mnemos: セッションログ自動記録の共用 worker。Claude Code の hook と
  # OpenCode の plugin (home-manager/programs/opencode/) の両方から
  # PATH 上の `vault-session-log-worker` として呼ばれる。
  vaultSessionLogWorker = pkgs.writeShellScriptBin "vault-session-log-worker" (
    builtins.readFile ./scripts/vault-session-log-worker.sh
  );
  checkUserMemoryScript = pkgs.writeShellScript "claude-check-user-memory" (
    builtins.readFile ./hooks/check-user-memory.sh
  );
in
{
  imports = [ ./deploy.nix ];

  home.packages = lib.optionals isPersonal [ vaultSessionLogWorker ];

  programs.claude-code = {
    enable = true;
    package = common.package;

    settings = common.settings // {
      # 明示的なフォールバックチェーンを無効化 (空配列 = 指定なしと等価)。
      # 設定キーは単数形 `fallbackModel` だが型は string 配列
      # (CLI の --fallback-model はカンマ区切り)。
      fallbackModel = [ ];
      # advisorModel = "fable";
      # effortLevel = "xhigh";
      voiceEnabled = true;

      # 全セッションで Remote Control bridge を自動起動する (/remote-control 相当)。
      # 私用機のみ有効。仕事機 (SC-N-843) は明示的に無効のままにする。
      # security-sensitive setting のため user settings (~/.claude/settings.json)
      # か policy でしか有効化できない (project/local settings は false のみ有効)。
      remoteControlAtStartup = isPersonal;

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
          # pre-commit の unstaged-stash が Read(.env)/Read(.env.*) / Claude Code の
          # built-in deny (`./secrets`, `**/*.key` 等) に阻まれて "unable to create
          # file ...: File exists" で ロールバックする。
          # git commit -> pre-commit -> git stash が .env / secrets/*.yaml を
          # 読み書きできず、hook 完走後の git checkout でツリーを復元できない
          # (2026-07-16 実測)。git commit の deny (Bash(git commit --no-gpg-sign:*))
          # は残っているので、GPG 署名バイパスなどの経路は引き続き遮断される。
          "git commit *"
          # sandbox は SSH を SOCKS5 proxy 経由にする GIT_SSH_COMMAND
          # (ProxyCommand: nc -X 5) を注入するが、proxy は認証必須で macOS の
          # nc は SOCKS5 認証非対応のため、SSH 越しの git 操作は許可ドメイン
          # 宛でも "nc: authentication method negotiation failed" で必ず失敗
          # する (2026-07-19 実測)。HTTPS remote は HTTP proxy 経由で動くので
          # 対象は SSH transport を使いうるコマンドのみ。
          "git push *"
          "git fetch *"
          "git pull *"
          "ssh *"
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

      permissions = common.settings.permissions // {
        allow = common.settings.permissions.allow ++ [ "Bash(playwright-cli:*)" ];
      };

      env = common.settings.env // {
        # API がリクエストにフラグを立てた (refusal) ときの自動モデル切り替えを禁止。
        # バイナリ 2.1.220 では refusal fallback の可否が
        # `!CLAUDE_CODE_DISABLE_REFUSAL_FALLBACK && !CLAUDE_CODE_NO_MODEL_FALLBACK`
        # かつ gate `switchModelsOnFlag` (デフォルト true) で決まる。gate は
        # サーバー側なのでユーザーが触れるのはこの env のみ。
        # なお CLAUDE_CODE_NO_MODEL_FALLBACK=1 はこれを含む上位互換で、
        # モデル不可用時の availability fallback まで潰す (= 黙って降格せずエラーになる)。
        CLAUDE_CODE_DISABLE_REFUSAL_FALLBACK = "1";

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
        common.settings.hooks
        // {
          # user memory (~/.claude/CLAUDE.md) の消失検知。詳細は hooks/check-user-memory.sh 冒頭。
          SessionStart = herdrClaudeHooks.SessionStart ++ [
            {
              hooks = [
                {
                  type = "command";
                  command = checkUserMemoryScript;
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

      extraKnownMarketplaces =
        common.settings.extraKnownMarketplaces
        // {
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

      enabledPlugins =
        common.settings.enabledPlugins
        // {
          # claude-plugins-official
          "claude-code-setup@claude-plugins-official" = true;
          "claude-md-management@claude-plugins-official" = true;
          "plugin-dev@claude-plugins-official" = true;
          "skill-creator@claude-plugins-official" = true;
          "frontend-design@claude-plugins-official" = true;
          "ralph-loop@claude-plugins-official" = true;
          # "code-review@claude-plugins-official" = true;
          # "pr-review-toolkit@claude-plugins-official" = true;
          "discord@claude-plugins-official" = true;

          # hiroppy
          "tmux-agent-sidebar@hiroppy" = true;
        }
        // lib.optionalAttrs isPersonal {
          "codex@openai-codex" = true;
        };
    };

    context = ./user-memory.md;

    agentsDir = ./agents;
    skills = localSkills // {
      hunk-review = "${config.programs.hunk.package}/skills/hunk-review";
    };
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
