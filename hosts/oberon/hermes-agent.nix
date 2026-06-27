{
  config,
  lib,
  pkgs,
  ...
}:
{
  sops.secrets."hermes-env" = {
    sopsFile = ../../secrets/hermes.env;
    format = "dotenv";
    mode = "0400";
  };

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;

    # Slack/Discord ライブラリ (slack-bolt 等) を sealed venv に事前ベイク。
    # v0.16.0 で [all] から除外されたため、サーバーデプロイでは明示が必要。
    extraDependencyGroups = [ "messaging" ];

    settings = {
      # OpenCode Go ($10/月サブスク、オープンモデル)。
      # 認証は OPENCODE_GO_API_KEY 環境変数のみ (OAuth 不要)。
      model.provider = "opencode-go";
      model.default = "glm-5.2";
      # MESSAGING_CWD 環境変数の代替。nixosModule は systemd Environment= に
      # MESSAGING_CWD をセットするが、hermes v0.16.0 でこの変数は deprecated。
      # settings 経由で config.yaml に書き出すことで警告を解消する。
      terminal.cwd = config.services.hermes-agent.workingDirectory;
    };

    environmentFiles = [ config.sops.secrets."hermes-env".path ];
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
}
