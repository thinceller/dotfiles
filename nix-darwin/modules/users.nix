{
  pkgs,
  userConfig,
  ...
}:
let
  inherit (userConfig) username homeDir;
  uid = userConfig.uid or 501;
in
{
  users.knownUsers = [ username ];
  users.users."${username}" = {
    inherit uid;
    home = homeDir;
    shell = pkgs.bashInteractive;
  };
}
