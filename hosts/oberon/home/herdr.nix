# herdr: agent-aware terminal multiplexer。スマホ → SSH/mosh → `herdr` で
# claude / opencode の永続セッションにアタッチする、リモートエージェント
# コーディングの中核。
{ pkgs, sources, ... }:
let
  # 上流 release の static musl binary をそのまま配置する (ldd 不要、
  # autoPatchelf 不要)。ソースビルド (rust + zig) は 2GB RAM の VPS では
  # 現実的でないため採らない。
  # TODO: locked nixpkgs が herdr (master に収載済み) に追いついたら
  # pkgs.herdr に切り替え、nvfetcher.toml の herdr-bin エントリを削除する。
  herdr = pkgs.runCommand "herdr-${sources.herdr-bin.version}" { } ''
    install -Dm755 ${sources.herdr-bin.src} $out/bin/herdr
  '';
in
{
  home.packages = [
    herdr
    # configs/.config/herdr/config.toml の popup キーバインドが参照するツールの
    # うち安価なもの。hunk / gh-dash / herdr-launch (ghq + nvim 前提) は
    # サーバーでは初期スコープ外 — 該当 popup が失敗するだけで実害はない。
    pkgs.lazygit
    pkgs.bottom
    pkgs.gh
  ];

  # Mac と同じ config.toml を共有し、キーバインドの筋肉記憶を揃える。
  # 単一ファイル symlink なのは Mac (home-manager/files.nix) と同じ理由:
  # herdr は ~/.config/herdr/ にログや agent 検出 state を書くため、
  # ディレクトリごと read-only にはできない。
  # Mac と違い out-of-store ではなく store path を使う: oberon の標準 deploy
  # (方式A --target-host) は ~/.dotfiles checkout を更新しないため、
  # out-of-store だと config が deploy 世代とズレる。
  xdg.configFile."herdr/config.toml".source = ../../../configs/.config/herdr/config.toml;

  programs.fish.interactiveShellInit = ''
    herdr completion fish | source
  '';
}
