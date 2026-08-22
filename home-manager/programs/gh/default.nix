{ pkgs, sources, ... }:
let
  gh-pr-graph = import ./gh-pr-graph.nix { inherit pkgs sources; };
in
{
  programs.gh-prism.enable = true;

  programs.gh = {
    enable = true;
    extensions = [
      pkgs.gh-dash
      pkgs.gh-poi
      pkgs.gh-stack
      gh-pr-graph
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
