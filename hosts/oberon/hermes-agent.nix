{ config, ... }:
{
  sops.secrets."hermes-env" = {
    sopsFile = ../../secrets/hermes.env;
    format = "dotenv";
    mode = "0400";
  };

  # hermes-auth.json はファイル全体を復号して /run/secrets/hermes-auth に書き出す。
  # format = "binary" でキー抽出なしにファイル全体を unwrap する。
  # (format = "json" は JSON 内の特定キー ["hermes-auth"] を抽出するモードのため不適切。)
  sops.secrets."hermes-auth" = {
    sopsFile = ../../secrets/hermes-auth.json;
    format = "binary";
    mode = "0400";
  };

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;

    # Slack/Discord ライブラリ (slack-bolt 等) を sealed venv に事前ベイク。
    # v0.16.0 で [all] から除外されたため、サーバーデプロイでは明示が必要。
    extraDependencyGroups = [ "messaging" ];

    settings = {
      model.provider = "openai-codex";
    };

    environmentFiles = [ config.sops.secrets."hermes-env".path ];
    authFile = config.sops.secrets."hermes-auth".path;
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
