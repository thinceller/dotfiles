{
  userConfig,
  ...
}:
let
  inherit (userConfig) hostname;
in
{
  networking.computerName = hostname;
  networking.hostName = hostname;
}
