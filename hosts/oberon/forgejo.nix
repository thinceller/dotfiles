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
        # built-in SSH server を 127.0.0.1:2222 で起動し、cloudflared tunnel
        # (forgejo-ssh.thinceller.dev → ssh://localhost:2222) 経由で受ける。
        # clone URL は git@forgejo.thinceller.dev:owner/repo.git (Web と同一ドメイン)。
        START_SSH_SERVER = true;
        BUILTIN_SSH_SERVER_USER = "git";
        SSH_DOMAIN = "forgejo.thinceller.dev";
        SSH_PORT = 22;
        SSH_LISTEN_HOST = "127.0.0.1";
        SSH_LISTEN_PORT = 2222;
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
