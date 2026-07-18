{
  lib,
  config,
  userConfig,
  ...
}:
lib.mkIf userConfig.isPersonal {
  programs.codex = {
    enable = true;

    # hunk 同梱の agent skill を codex にも展開する。
    skills = {
      hunk-review = "${config.programs.hunk.package}/skills/hunk-review";
    };
  };
}
