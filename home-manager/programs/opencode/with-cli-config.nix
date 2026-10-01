# opencode v2 の CLI/TUI 設定を OPENCODE_CLI_CONFIG_CONTENT で渡すラッパー。
# v2 は ~/.config/opencode/cli.json を tmp → rename で書き換えるため、HM で symlink 管理すると
# TUI から設定を変えた時点で実ファイルに置き換わり、次回 activation が衝突で失敗する。
# 環境変数の値は cli.json に重ねてマージされ、設定中は優先される (cli.json 自体は client に任せる)。
{ pkgs, lib }:
cliConfig:
pkgs.symlinkJoin {
  name = "opencode-${pkgs.opencode.version}";
  paths = [ pkgs.opencode ];
  nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
  postBuild = ''
    wrapProgram $out/bin/opencode \
      --set-default OPENCODE_CLI_CONFIG_CONTENT ${lib.escapeShellArg (builtins.toJSON cliConfig)}
  '';
  inherit (pkgs.opencode) meta;
}
