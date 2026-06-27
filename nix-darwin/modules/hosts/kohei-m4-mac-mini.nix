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
    "codex-app"
    "discord"
    "google-chrome"
    "obsidian"
    "readdle-spark"
    "slack"
    "steam"
    "tailscale-app"
    "zoom"
  ];
}
