{
  config,
  pkgs,
  ...
}:
{
  # forgejo バイナリと、`forgejo-admin` ラッパー (sudo + --config 自動指定) を入れる。
  # 通常運用 (admin user create / dump / migrate 等) はラッパーで完結する。
  environment.systemPackages = [
    config.services.forgejo.package
    (pkgs.writeShellScriptBin "forgejo-admin" ''
      exec sudo -u ${config.services.forgejo.user} \
        ${config.services.forgejo.package}/bin/forgejo \
        --config ${config.services.forgejo.customDir}/conf/app.ini \
        --work-path ${config.services.forgejo.stateDir} \
        "$@"
    '')
  ];

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "forgejo" ];
    ensureUsers = [
      {
        name = "forgejo";
        ensureDBOwnership = true;
      }
    ];
  };

  services.forgejo = {
    enable = true;

    database = {
      type = "postgres";
      user = "forgejo";
      name = "forgejo";
      socket = "/run/postgresql";
    };

    settings = {
      server = {
        DOMAIN = "forgejo.thinceller.dev";
        ROOT_URL = "https://forgejo.thinceller.dev/";
        HTTP_ADDR = "127.0.0.1";
        HTTP_PORT = 3000;
        # Forgejo 上の SSH 鍵設定 UI ごと無効化し、HTTPS clone のみとする。
        DISABLE_SSH = true;
      };

      service = {
        DISABLE_REGISTRATION = true;
        REQUIRE_SIGNIN_VIEW = false;
      };

      session = {
        COOKIE_SECURE = true;
        SESSION_LIFE_TIME = 86400;
      };

      log = {
        LEVEL = "Info";
        MODE = "console";
      };
    };
  };
}
