{ pkgs }:
{
  programs.mise = {
    enable = true;
    globalConfig = {
      settings = {
        legacy_version_file = true;
      };
    };
  };
}
