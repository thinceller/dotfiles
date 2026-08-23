# darwin (nixpkgs unstable) 用の gh 設定。
{ pkgs, sources, ... }:
let
  gh-pr-graph = import ./gh-pr-graph.nix { inherit pkgs sources; };
in
{
  imports = [ ./common.nix ];

  # ここに置く拡張が oberon に載らないのは意図的:
  # - gh-stack は nixpkgs unstable にしか無い (nixos-25.11 には未収録)。
  # - gh-pr-graph はローカルサーバを立ててブラウザを開くツールなので、
  #   ヘッドレスな oberon では使えない。
  # programs.gh.extensions は list なので common.nix の定義とマージされる。
  programs.gh.extensions = [
    pkgs.gh-stack
    gh-pr-graph
  ];
}
