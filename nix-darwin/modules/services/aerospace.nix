{
  ...
}:
{
  # NOTE: services.aerospace を有効にすると AeroSpace.app が /Applications/Nix Apps/ に配置され、
  # darwin-rebuild switch のたびに macOS の "App Management" TCC 権限がリセットされる問題があるため無効化
  # （Alacritty などから darwin-rebuild が打てなくなる）
  # Homebrew でインストールする（nix-darwin/modules/homebrew.nix を参照）
  # 設定は configs/.config/aerospace/aerospace.toml で管理（home-manager/files.nix の symlink 経由）
  services.aerospace.enable = false;
}
