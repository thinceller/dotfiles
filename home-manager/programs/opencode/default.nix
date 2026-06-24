{
  lib,
  userConfig,
  ...
}:
lib.mkIf userConfig.isPersonal {
  programs.opencode = {
    enable = true;
  };
}
