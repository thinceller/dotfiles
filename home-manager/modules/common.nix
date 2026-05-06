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
    # macOS のデフォルトは ~/Library/Application Support, ~/Library/Caches だが、
    # cage 等の XDG 準拠ツールが ~/.config, ~/.cache を参照するよう明示的に設定
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_CACHE_HOME = "$HOME/.cache";
  };

  sops = {
    defaultSopsFile = ../../secrets/default.yaml;
    age = {
      keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
    };
    secrets.test = { };
    secrets.discord-bot-token = { };
  };

  home.stateVersion = "24.05";
}
