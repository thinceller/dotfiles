# 全ホスト共通の gh 設定。
# oberon は nixpkgs-stable (nixos-25.11) を使うため、ここには stable にも
# 存在するものだけを置く。unstable 限定の拡張は default.nix 側で足す。
{ pkgs, ... }:
{
  programs.gh-prism.enable = true;

  programs.gh = {
    enable = true;
    extensions = [
      pkgs.gh-dash
      pkgs.gh-poi
    ];
    settings = {
      git_protocol = "ssh";
      prompt = "enabled";
      aliases = {
        co = ''!id="$(gh pr list -L100 | fzf | cut -f1)"; [ -n "$id" ] && gh pr checkout "$id"'';
      };
    };
  };
}
