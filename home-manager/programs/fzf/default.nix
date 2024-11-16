{ pkgs }:
{
  programs.fzf = {
    enable = true;
    defaultCommand = ''rg --files --hidden --glob "!.git"'';
    defaultOptions = [
      "--height 40%"
      "--reverse"
      "--border"
    ];
  };
}
