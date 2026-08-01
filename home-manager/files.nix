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
  # NOTE: ~/.homebrew/trust.json は nix-darwin/modules/homebrew.nix の preActivation で
  # 管理する (home.file 経由だと trust.json が Nix store への symlink になり、Homebrew 6.x が
  # brew bundle 後に trust store を書き戻そうとして "Refusing to write insecure trust store" で
  # 停止するため)。
  home.file = {
    ".bashrc" = {
      source = symlink /${rootDir}/.bashrc;
    };
    ".bash_profile" = {
      source = symlink /${rootDir}/.bash_profile;
    };
    # herdr プロジェクトランチャー (configs/bin/herdr-launch)。
    ".local/bin/herdr-launch" = {
      source = symlink /${rootDir}/bin/herdr-launch;
    };
    # Hermes worker profile for kanban auto-implementation.
    # The default profile SOUL.md is managed via the NixOS module's documents option.
    ".hermes/profiles/worker/SOUL.md" = {
      source = symlink /${rootDir}/hermes/profiles/worker/SOUL.md;
    };
    ".hermes/profiles/worker/config.yaml" = {
      source = symlink /${rootDir}/hermes/profiles/worker/config.yaml;
    };
    ".hermes/scripts/to-kanban.py" = {
      source = symlink /${rootDir}/hermes/scripts/to-kanban.py;
      executable = true;
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
    "ghostty/config.ghostty" = {
      source = symlink /${rootDir}/.config/ghostty/config.ghostty;
    };
    # herdr
    # 単一ファイル symlink にする理由: herdr は ~/.config/herdr/ 配下に
    # herdr.log / herdr-server.log / agent-detection/ ローカル override を
    # 書くため、ディレクトリごと symlink すると書き込みが弾かれる。
    "herdr/config.toml" = {
      source = symlink /${rootDir}/.config/herdr/config.toml;
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
