{ pkgs, ... }:
{
  programs.gh-prism.enable = true;

  programs.gh = {
    enable = true;
    extensions = with pkgs; [
      gh-dash
      gh-poi
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
