{
  ...
}:
{
  # NOTE: services.karabiner-elements は Karabiner-Elements v15.0 以降で壊れているため無効化
  # 詳細: https://github.com/LnL7/nix-darwin/issues/1041
  # Homebrewでインストールする（nix-darwin/modules/homebrew.nix を参照）
  services.karabiner-elements.enable = false;
}
