{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Declarative settings のハッシュを systemd restart trigger に使い、
  # settings 変更時に hermes-agent サービスを自動再起動させる。
  # 特に Block Kit rich rendering のように、config.yaml は更新されても
  # 動作中プロセスが起動時設定を使い続ける場合があるため、
  # この trigger で再起動を促す。
  hermesConfigHash = pkgs.writeText "hermes-config-hash.json" (
    builtins.toJSON config.services.hermes-agent.settings
  );

  sources = pkgs.callPackage ../../_sources/generated.nix { };

  # design-pipeline skill の設計工程 (grill-with-docs → to-spec → to-tickets) が依存する
  # mattpocock/skills。リポジトリ全体を external_dirs に載せると in-progress や
  # personal 配下まで system prompt に載るため、使う skill だけを取り出す。
  # grilling は grill-with-docs / grill-me から参照される共有 skill。
  plannerSkills = pkgs.runCommand "matt-pocock-planner-skills" { } ''
    mkdir -p $out
    for s in \
      engineering/grill-with-docs \
      engineering/to-spec \
      engineering/to-tickets \
      engineering/domain-modeling \
      productivity/grill-me \
      productivity/grilling; do
      cp -r ${sources.matt-pocock-skills.src}/skills/"$s" $out/
    done
  '';

  # default プロファイル (planner) と worker プロファイルで共有する設定。
  # profile の config.yaml は root の config.yaml とマージされず完全に置き換わるため、
  # 共通部分をここで一元化して両方に流し込む。
  sharedSettings = {
    # OpenCode Go ($10/月サブスク、オープンモデル)。
    # 認証は OPENCODE_GO_API_KEY 環境変数のみ (OAuth 不要)。
    model.provider = "opencode-go";
    model.default = "kimi-k2.7-code";
    # MESSAGING_CWD 環境変数の代替。nixosModule は systemd Environment= に
    # MESSAGING_CWD をセットするが、hermes v0.16.0 でこの変数は deprecated。
    # settings 経由で config.yaml に書き出すことで警告を解消する。
    terminal.cwd = config.services.hermes-agent.workingDirectory;
    # standalone kind のプラグインは既定 opt-in のため、明示的に有効化する。
    plugins.enabled = [ "session-vault-export" ];
    # Mnemos の vault 系スキル (経路C 版: terminal + git、MCP なし) と、
    # design-pipeline が使う mattpocock/skills。external_dirs は読み取り専用の
    # 共有スキルディレクトリ。
    skills.external_dirs = [
      "${./hermes-skills}"
      "${plannerSkills}"
    ];
    # 秘書的な運用のため、セッションをまたいだ記憶を upstream default に従って明示化。
    memory.memory_enabled = true;
    memory.user_profile_enabled = true;
    # ユーザー ID や電話番号などの個人識別情報をモデルに渡す前にハッシュ化。
    privacy.redact_pii = true;
    # 2026-07-01 マージの Block Kit リッチレンダリングを有効化。
    # フォールバック平文は従来の mrkdwn のままなので、標準 Markdown を書くプラクティスは維持される。
    platforms.slack.extra.rich_blocks = true;
  };

  # worker プロファイルの HERMES_HOME。
  workerProfileDir = "${config.services.hermes-agent.stateDir}/.hermes/profiles/worker";

  # worker は kanban dispatcher から stdin=DEVNULL で spawn されるため、
  # approvals.mode が manual/smart のままだと承認プロンプトが EOFError になり
  # 必ず deny に落ちる。Draft PR までを無人で完走させるため off にする。
  # 破壊的操作の抑止は worker の SOUL.md の規約が担う。
  #
  # skills は planner 用のものしか無く、worker が使う場面が無い。
  # approvals off の worker に to-kanban (タスク作成) を持たせない意味もあるので空にする。
  workerSettings = lib.recursiveUpdate sharedSettings {
    approvals.mode = "off";
    skills.external_dirs = [ ];
  };

  workerConfigFile = (pkgs.formats.yaml { }).generate "hermes-worker-config.yaml" workerSettings;
in
{
  sops.secrets."hermes-env" = {
    sopsFile = ../../secrets/hermes.env;
    format = "dotenv";
    mode = "0400";
  };

  # thinceller-hermes (GitHub machine account) の SSH 秘密鍵。vault (knowledge-base)
  # を含む招待済み repo への git push に使う。GIT_SSH_COMMAND 経由で ssh が直接
  # 読むため、エージェントのコンテキストに秘密鍵が乗ることはない。
  sops.secrets."hermes-github-ssh-key" = {
    sopsFile = ../../secrets/oberon.yaml;
    owner = "hermes";
    mode = "0400";
    restartUnits = [ "hermes-agent.service" ];
  };

  # thinceller-hermes の PAT (PR 作成用)。gh wrapper (extraPackages) が実行時に
  # 読むため、systemd の Environment= には載せない。
  sops.secrets."hermes-github-pat" = {
    sopsFile = ../../secrets/oberon.yaml;
    owner = "hermes";
    mode = "0400";
    restartUnits = [ "hermes-agent.service" ];
  };

  # hermes user の git-over-ssh 用に GitHub のホスト鍵をシステム known_hosts へ供給。
  programs.ssh.knownHosts."github.com".publicKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;

    # Slack/Discord ライブラリ (slack-bolt 等) を sealed venv に事前ベイク。
    # v0.16.0 で [all] から除外されたため、サーバーデプロイでは明示が必要。
    extraDependencyGroups = [ "messaging" ];

    settings = lib.recursiveUpdate sharedSettings {
      # 低リスクなコマンドは自動承認し、高リスクな操作は確認を取る。
      # default profile は Slack 越しに対話できるので smart が使える (worker は off)。
      approvals.mode = "smart";
      # 全タスクが単一の worker プロファイルに assign され、workspace は
      # リポジトリの共有チェックアウト (dir:) なので、同時に2つ以上走ると
      # 同じ作業ツリーで別ブランチを取り合って壊れる。1本に直列化する。
      kanban.max_in_progress_per_profile = 1;
    };

    # セッション終了時に knowledge-base vault へ Markdown を書き出して push する
    # プラグイン。~/.hermes/plugins/nix-managed-session-vault-export へ symlink される。
    extraPlugins = [
      (pkgs.runCommand "session-vault-export" { } ''
        mkdir -p $out
        cp -r ${./hermes-plugins/session-vault-export}/. $out/
      '')
    ];

    environmentFiles = [ config.sops.secrets."hermes-env".path ];

    # knowledge-base vault 連携 (Mnemos 経路C)。
    # AGENTS.md は workingDirectory に配置され、cwd がそこになる planner の
    # system prompt に自動注入される (agent/prompt_builder.py の context files 機構は
    # cwd 直下を1ファイルだけ読む)。
    # dispatcher は worker の cwd を workspace のリポジトリに移すため、この AGENTS.md は
    # worker には届かない。worker 側の規約は hermes-profiles/worker/SOUL.md と
    # 各リポジトリの CLAUDE.md / AGENTS.md が担う。
    # SOUL.md は HERMES_HOME からしか読まれないため documents では扱えない
    # (hermes-worker-profile activation script で配置する)。
    documents."AGENTS.md" = ./hermes-documents/AGENTS.md;

    # service path には git はあるが ssh がないため openssh を追加。
    # gh は PAT を実行時に sops path から読む wrapper として提供する
    # (トークンを systemd Environment= に載せない)。
    extraPackages = [
      pkgs.openssh
      (pkgs.writeShellScriptBin "gh" ''
        GH_TOKEN="$(cat ${config.sops.secrets."hermes-github-pat".path})" \
          exec ${pkgs.gh}/bin/gh "$@"
      '')
      # to-kanban skill から呼ぶ変換スクリプト。store path を SKILL.md に
      # 埋め込まずに済むよう、PATH に載るコマンドとして提供する。
      (pkgs.writeShellScriptBin "to-kanban" ''
        exec ${pkgs.python3}/bin/python3 ${./hermes-scripts/to-kanban.py} "$@"
      '')
    ];

    environment = {
      # git push 用 (machine user thinceller-hermes の鍵。招待済み repo すべてに届く)。
      # ホスト鍵検証は programs.ssh.knownHosts (上記) が担う。
      GIT_SSH_COMMAND = "ssh -i ${
        config.sops.secrets."hermes-github-ssh-key".path
      } -o IdentitiesOnly=yes";
      # hermes user は ~/.gitconfig を持たないため commit 時の identity を env で供給する。
      # ドメインは保持している thinceller.dev (Cloudflare Email Routing 利用可)。
      # 将来 machine user 化する場合はこのアドレスを GitHub で検証すればよい。
      GIT_AUTHOR_NAME = "Hermes Agent";
      GIT_AUTHOR_EMAIL = "hermes@thinceller.dev";
      GIT_COMMITTER_NAME = "Hermes Agent";
      GIT_COMMITTER_EMAIL = "hermes@thinceller.dev";
    };
  };

  # nixosModule が systemd Environment= に MESSAGING_CWD をセットするため、
  # プロセス環境から削除して deprecated 警告を解消する。
  # environment 全体を lib.mkForce で置換すると、nixosModule が `path`
  # オプション経由で注入する PATH キー (environment.PATH へ展開される) ごと
  # 消えてしまい、cat/rm 等の基本コマンドが見つからなくなる。そのため
  # MESSAGING_CWD キーだけを null 上書きして除外する (null のキーは
  # systemd unit 生成時に出力されない)。
  # TimeoutStopSec も drain_timeout (180s) + 30s バッファに合わせて延長する。
  systemd.services.hermes-agent = {
    serviceConfig.TimeoutStopSec = lib.mkForce 210;
    environment.MESSAGING_CWD = lib.mkForce null;
    restartTriggers = [ hermesConfigHash ];
  };

  # default profile の SOUL.md と worker プロファイルを HERMES_HOME 配下へ配置する。
  # hermes は SOUL.md を HERMES_HOME からしか読まず、named profile は
  # HERMES_HOME/profiles/<name>/ をそのまま新しい HERMES_HOME として扱う。
  # NixOS モジュールにはこれらを配置するオプションがないため自前で行う。
  system.activationScripts.hermes-worker-profile = {
    deps = [ "hermes-agent-setup" ];
    text =
      let
        inherit (config.services.hermes-agent) stateDir user group;
      in
      ''
        install -o ${user} -g ${group} -m 0660 -D \
          ${./hermes-documents/SOUL.md} ${stateDir}/.hermes/SOUL.md

        # profile の起動には profiles/<name>/ が実在する必要がある。
        # サブディレクトリの一覧は hermes_cli/profiles.py の _PROFILE_DIRS
        # (profile 作成時に bootstrap されるもの) に合わせている。
        install -o ${user} -g ${group} -m 2770 -d \
          ${stateDir}/.hermes/profiles \
          ${workerProfileDir} \
          ${workerProfileDir}/memories \
          ${workerProfileDir}/sessions \
          ${workerProfileDir}/skills \
          ${workerProfileDir}/skins \
          ${workerProfileDir}/logs \
          ${workerProfileDir}/plans \
          ${workerProfileDir}/workspace \
          ${workerProfileDir}/cron \
          ${workerProfileDir}/home \
          ${workerProfileDir}/plugins

        install -o ${user} -g ${group} -m 0660 \
          ${./hermes-profiles/worker/SOUL.md} ${workerProfileDir}/SOUL.md
        install -o ${user} -g ${group} -m 0660 \
          ${workerConfigFile} ${workerProfileDir}/config.yaml

        # worker profile には .env を置かない。dispatcher は gateway の os.environ を
        # そのまま子プロセスへ渡すので、API キー等は継承される。
        # 人間が `hermes -p worker chat` を直接叩くときだけ認証が無い点に注意。

        # plugins は HERMES_HOME/plugins/ から解決されるため、worker プロファイルにも
        # default プロファイルと同じ nix-managed symlink を張る。
        # hermes-agent の nix/nixosModules.nix にある default プロファイル向けの
        # 同じ処理を写したもの。input を更新したときは向こうの変更を確認すること。
        find ${workerProfileDir}/plugins -maxdepth 1 -type l -name 'nix-managed-*' -delete 2>/dev/null || true
        ${lib.concatMapStringsSep "\n" (plugin: ''
          if [ ! -f "${plugin}/plugin.yaml" ]; then
            echo "ERROR: extraPlugins entry '${plugin}' has no plugin.yaml" >&2
            exit 1
          fi
          ln -sfn ${plugin} ${workerProfileDir}/plugins/nix-managed-${lib.getName plugin}
          chown -h ${user}:${group} ${workerProfileDir}/plugins/nix-managed-${lib.getName plugin}
        '') config.services.hermes-agent.extraPlugins}
      '';
  };

  # hermes gateway は native systemd mode でダッシュボードを自動起動しない。
  # HERMES_DASHBOARD 環境変数は Docker/s6 entrypoint のみ参照しており、
  # Python の hermes gateway バイナリは読まない。
  # 独立 unit で hermes dashboard を 127.0.0.1:9119 に常駐させる。
  systemd.services.hermes-agent-dashboard = {
    description = "Hermes Agent Dashboard";
    wantedBy = [ "multi-user.target" ];
    after = [ "hermes-agent.service" ];

    environment = {
      HOME = "/var/lib/hermes";
      HERMES_HOME = "/var/lib/hermes/.hermes";
      HERMES_MANAGED = "true";
    };

    serviceConfig = {
      User = "hermes";
      Group = "hermes";
      ExecStart = "${config.services.hermes-agent.package}/bin/hermes dashboard --no-open --host 127.0.0.1 --port 9119";
      Restart = "always";
      RestartSec = 5;
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = false;
      ReadWritePaths = [ "/var/lib/hermes" ];
      PrivateTmp = true;
    };
  };

  # Slack Socket Mode の dead-session 無限リトライ検知 watchdog。
  # ネットワーク瞬断で aiohttp ClientSession が close されると slack_sdk が
  # 死んだセッションを掴んだまま `Session is closed` を10秒ごとに投げ続け、
  # プロセスは active のまま無反応になる。hermes 内蔵 watchdog は「再接続
  # タスクは生きているが永久に失敗する」この状態を検知できないため補う。
  # 現プロセスの起動時刻 (ActiveEnterTimestamp) 以降のログでシグネチャが
  # 連続したときだけ再起動する。再起動で起点がリセットされるので、直前世代の
  # ログを数えて再起動ループに陥ることはない (健全時は0件で何もしない)。
  systemd.services.hermes-agent-watchdog = {
    description = "Restart hermes-agent when Slack Socket Mode is stuck in a dead-session reconnect loop";
    after = [ "hermes-agent.service" ];
    path = [
      pkgs.systemd
      pkgs.gnugrep
    ];
    serviceConfig.Type = "oneshot";
    script = ''
      if [ "$(systemctl is-active hermes-agent || true)" != "active" ]; then
        exit 0
      fi
      start=$(systemctl show hermes-agent -p ActiveEnterTimestamp --value)
      if [ -z "$start" ]; then
        exit 0
      fi
      count=$(journalctl -u hermes-agent --since "$start" -q \
              | grep -c "Failed to connect (error: Session is closed)" || true)
      if [ "$count" -ge 3 ]; then
        echo "Detected $count dead-session reconnect failures since $start; restarting hermes-agent"
        systemctl restart hermes-agent
      fi
    '';
  };

  systemd.timers.hermes-agent-watchdog = {
    description = "Periodic health check for hermes-agent Slack Socket Mode connection";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "1min";
    };
  };

  # kanban board はランタイム状態 (kanban.db) なので NixOS モジュールの管理外だが、
  # 別マシンへ復元したときに手動作成が要らないよう、宣言した board を冪等に用意する。
  # `boards create` は `mkdir -p` 相当で冪等なので、毎回実行して構わない。
  systemd.services.hermes-kanban-boards =
    let
      workspace = config.services.hermes-agent.workingDirectory;
      boards = [
        {
          slug = "thinceller-net";
          name = "thinceller.net";
          workdir = "${workspace}/thinceller.net";
        }
        {
          slug = "dotfiles";
          name = "dotfiles";
          workdir = "${workspace}/dotfiles";
        }
      ];
    in
    {
      description = "Ensure Hermes kanban boards exist";
      wantedBy = [ "multi-user.target" ];
      before = [ "hermes-agent.service" ];

      environment = {
        HOME = config.services.hermes-agent.stateDir;
        HERMES_HOME = "${config.services.hermes-agent.stateDir}/.hermes";
        HERMES_MANAGED = "true";
      };

      serviceConfig = {
        Type = "oneshot";
        User = config.services.hermes-agent.user;
        Group = config.services.hermes-agent.group;
      };

      script = lib.concatMapStringsSep "\n" (b: ''
        ${config.services.hermes-agent.package}/bin/hermes kanban boards create ${b.slug} \
          --name ${lib.escapeShellArg b.name} \
          --default-workdir ${lib.escapeShellArg b.workdir}
      '') boards;
    };
}
