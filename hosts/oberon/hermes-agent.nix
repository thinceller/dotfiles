{ config, lib, ... }:
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
}
