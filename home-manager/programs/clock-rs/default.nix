{ pkgs }:
{
  programs.clock-rs = {
    enable = true;
    settings = {
      date = {
        fmt = "%Y-%m-%d";
      };
    };
  };
}
