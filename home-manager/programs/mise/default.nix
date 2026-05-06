{ pkgs, ... }:
{
  programs.mise = {
    enable = true;
    enableFishIntegration = true;
    globalConfig = {
      settings = {
        legacy_version_file = true;
        idiomatic_version_file_enable_tools = [
          "node"
          "ruby"
        ];
      };
    };
  };
}
