{
  lib,
  userConfig,
  ...
}:
lib.mkIf userConfig.isPersonal {
  programs.codex = {
    enable = true;
  };
}
