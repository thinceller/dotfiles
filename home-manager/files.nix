{ config, dotfilesDir, ... }:
let
  # TODO: 固定値ではなく、実行時のカレントディレクトリを取得するようにする
  rootDir = /. + dotfilesDir + /configs;
  symlink = config.lib.file.mkOutOfStoreSymlink;
in
{
  home.file = {
    # Hammerspoon
    ".hammerspoon" = {
      source = symlink /${rootDir}/.hammerspoon;
      recursive = true;
    };
  };
  xdg.configFile = {
    # karabiner
    "karabiner/karabiner.json" = {
      source = symlink /${rootDir}/.config/karabiner/karabiner.json;
    };
    "karaibner/assets/complex_modifications" = {
      source = symlink /${rootDir}/.config/karabiner/assets/complex_modifications;
      recursive = true;
    };
    # Neovim
    "nvim" = {
      source = symlink /${rootDir}/.config/nvim;
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
    "wezterm/wezterm.lua" = {
      source = symlink /${rootDir}/.config/wezterm/wezterm.lua;
    };
  };
}
