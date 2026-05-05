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

  # darwin-rebuild switch のたびに ~/Applications/Home Manager Apps/*.app への
  # touch チェックで tccutil reset が走り、App Management 権限がリセットされる問題があるため無効化
  # （Alacritty などから darwin-rebuild が打てなくなる）
  # GUI アプリは Homebrew cask で管理する方針
  # TODO: Ghostty / WezTerm / AppCleaner / pinentry-mac を Homebrew cask に移行後、
  # targets.darwin ブロック自体を削除する
  targets.darwin = {
    copyApps.enable = false;
    linkApps.enable = false;
  };

  home.stateVersion = "24.05";
}
