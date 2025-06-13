{ config, dotfilesDir, ... }:
let
  # TODO: 固定値ではなく、実行時のカレントディレクトリを取得するようにする
  rootDir = /. + dotfilesDir + /configs;
  symlink = config.lib.file.mkOutOfStoreSymlink;
in
[
  {
    home.file = {
      # Claude Code
      ".claude/CLAUDE.md" = {
        source = symlink /${rootDir}/.claude/CLAUDE.md;
      };
      ".claude/settings.json" = {
        source = symlink /${rootDir}/.claude/settings.json;
      };
    };
    xdg.configFile = {
      # karabiner
      # https://github.com/pqrs-org/Karabiner-Elements/issues/3248
      "karabiner" = {
        source = symlink /${rootDir}/.config/karabiner;
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
]
