{ self, username, ... }:
{
  system = {
    # configurationRevision = self.rev or self.dirtyRev or null;
    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    stateVersion = 5;

    primaryUser = username;

    defaults = {
      controlcenter = {
        BatteryShowPercentage = true;
        Bluetooth = true;
      };
      dock = {
        autohide = true;
        orientation = "bottom";
        magnification = true;
        tilesize = 45;
        largesize = 70;
        mru-spaces = false;
        show-recents = false;
        expose-group-apps = true;
      };
      trackpad = {
        Clicking = true;
        FirstClickThreshold = 2;
      };
      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        ShowPathbar = true;
      };
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        AppleShowScrollBars = "Always";
        ApplePressAndHoldEnabled = false;
      };
      WindowManager = {
        EnableStandardClickToShowDesktop = true;
      };
      menuExtraClock = {
        Show24Hour = true;
      };
    };

    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };
  };
}
