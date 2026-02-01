{ ... }:
{
  # brew-nixでビルドできないcasksをHomebrewで管理
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";
    };
    casks = [
      "azookey" # brew-nixだとIMEとして認識されない（copyApps有効でも解決しない）
      "hhkb-studio"
      "karabiner-elements" # nix-darwin serviceが v15.0 以降で壊れているためHomebrewで管理
      "logi-options+"
    ];
  };
}
