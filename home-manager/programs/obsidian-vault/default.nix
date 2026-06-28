{
  pkgs,
  lib,
  userConfig,
  ...
}:
lib.mkIf userConfig.isPersonal {
  programs.mcp = {
    enable = true;
    servers.obsidian-vault = {
      command = "${pkgs.nodejs_24}/bin/npx";
      args = [
        "-y"
        "@oomkapwn/enquire-mcp"
        "serve"
        "--vault"
        "${userConfig.homeDir}/src/github.com/thinceller/knowledge-base"
        "--persistent-index"
        "--enable-write"
      ];
    };
  };
}
