# gh pr-graph — 自分が関わる PR を base/head ブランチ単位のグラフで一覧する gh 拡張。
# nixpkgs 未収録なので nvfetcher + buildGoModule で自前ビルドする (tcmux と同じ形)。
# home-manager の programs.gh.extensions は pname をそのまま
# ~/.local/share/gh/extensions/<pname> に link farm するため、
# pname と $out/bin のバイナリ名を両方 "gh-pr-graph" に揃える必要がある。
{ pkgs, sources }:
pkgs.buildGoModule {
  pname = "gh-pr-graph";
  inherit (sources.gh-pr-graph) version src;
  # go.mod に require が無い (依存ゼロ) ため vendoring 不要。
  vendorHash = null;
  subPackages = [ "cmd/gh-pr-graph" ];
  ldflags = [ "-X main.version=${sources.gh-pr-graph.version}" ];
}
