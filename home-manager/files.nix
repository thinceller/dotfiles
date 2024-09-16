{ config, ...}:
let
  rootDir = /Users/thinceller/.dotfiles;
  symlink = config.lib.file.mkOutOfStoreSymlink;
in {
  home.file = {
    # karabiner
    ".config/karabiner/karabiner.json" = {
      source = symlink /${rootDir}/.config/karabiner/karabiner.json;
    };
    ".config/karabiner/complex_modifications" = {
      source = symlink /${rootDir}/.config/karabiner/complex_modifications;
      recursive = true;
    };
    # 1Password CLI
    ".config/op/plugins.sh" = {
      source = symlink /${rootDir}/.config/op/plugins.sh;
    };
    # pnpm
    ".config/pnpm" = {
      source = symlink /${rootDir}/.config/pnpm;
      recursive = true;
    };
  };
}
