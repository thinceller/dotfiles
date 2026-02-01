{
  config,
  userConfig,
  ...
}:
let
  inherit (userConfig) username homeDir;
in
{
  home.username = username;
  home.homeDirectory = homeDir;

  home.sessionVariables = {
    LANG = "ja_JP.UTF-8";
    LC_ALL = "ja_JP.UTF-8";
  };

  sops = {
    defaultSopsFile = ../../secrets/default.yaml;
    age = {
      keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
    };
    secrets.test = { };
  };

  # mac-app-util の代わりに home-manager 組み込みの copyApps を使用
  # Spotlight でアプリを検出可能にする
  targets.darwin = {
    copyApps.enable = true;
    linkApps.enable = false;
  };

  home.stateVersion = "24.05";
}
