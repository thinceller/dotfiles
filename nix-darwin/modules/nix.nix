{
  pkgs,
  system,
  userConfig,
  ...
}:
{
  nix = {
    enable = true;
    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [
        "root"
        userConfig.username
      ];
      # devenv を使う flake (例: trihermes) は nixConfig で devenv.cachix.org を
      # 宣言するが、このマシンは accept-flake-config = false のため direnv 経由の
      # 非対話な shell 進入では untrusted 扱いで無視される。グローバル設定に明示
      # 追加して devenv 関連の derivation をローカルビルドしないようにする。
      # デフォルトの cache.nixos.org を潰さないよう `extra-` プレフィックス必須。
      extra-substituters = [
        "https://devenv.cachix.org"
      ];
      extra-trusted-public-keys = [
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      ];
    };
    optimise.automatic = true;
    registry = {
      dev = {
        to = {
          type = "github";
          owner = "thinceller";
          repo = "flake-templates";
        };
      };
    };
    package = pkgs.nix;
  };
  nixpkgs = {
    hostPlatform = system;
    config.allowUnfree = true;
  };
}
