{
  config,
  userConfig,
  ...
}:
let
  inherit (userConfig) dotfilesDir;
  # TODO: 固定値ではなく、実行時のカレントディレクトリを取得するようにする
  rootDir = /. + dotfilesDir + /configs;
  symlink = config.lib.file.mkOutOfStoreSymlink;
in
{
  # ホームディレクトリ直下のファイル
  home.file = {
    ".bashrc" = {
      source = symlink /${rootDir}/.bashrc;
    };
    ".bash_profile" = {
      source = symlink /${rootDir}/.bash_profile;
    };
    # Homebrew 6.0+ は brew bundle 実行時に非公式 tap の trust を要求する。
    # darwin-rebuild の activation は XDG_CONFIG_HOME を引き継がず HOME のみ設定するため、
    # Homebrew は ~/.homebrew/trust.json を参照する。taps は nix-darwin/modules/homebrew.nix と一致させる。
    ".homebrew/trust.json" = {
      force = true;
      text = builtins.toJSON {
        trustedtaps = [
          "k1low/tap"
          "manaflow-ai/cmux"
          "nikitabobko/tap"
        ];
      };
    };
  };

  xdg.configFile = {
    # AeroSpace
    "aerospace" = {
      source = symlink /${rootDir}/.config/aerospace;
      recursive = true;
    };
    # Alacritty
    "alacritty" = {
      source = symlink /${rootDir}/.config/alacritty;
      recursive = true;
    };
    # Ghostty
    "ghostty/config" = {
      source = symlink /${rootDir}/.config/ghostty/config;
    };
    # karabiner
    # https://github.com/pqrs-org/Karabiner-Elements/issues/3248
    "karabiner" = {
      source = symlink /${rootDir}/.config/karabiner;
    };
    # Neovim
    # init.lua は programs.neovim が生成するため、lua/ 配下のみを symlink する。
    "nvim/lua" = {
      source = symlink /${rootDir}/.config/nvim/lua;
      recursive = true;
    };
    # 1Password CLI
    "op/plugins.sh" = {
      source = symlink /${rootDir}/.config/op/plugins.sh;
    };
    # pnpm
    "pnpm" = {
      source = symlink /${rootDir}/.config/pnpm;
      recursive = true;
    };
    "cage" = {
      source = symlink /${rootDir}/.config/cage;
      recursive = true;
    };
    # WezTerm
    "wezterm/wezterm.lua" = {
      source = symlink /${rootDir}/.config/wezterm/wezterm.lua;
    };
  };
}
