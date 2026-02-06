{
  ...
}:
{
  ids.gids.nixbld = 350;

  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
    watchIdAuth = true;
  };

  homebrew.casks = [
    "antigravity"
    "discord"
    "google-chrome"
    "obsidian"
    "readdle-spark"
    "slack"
    "steam"
    "zoom"
  ];
}
