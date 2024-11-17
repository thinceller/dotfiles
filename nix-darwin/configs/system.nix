{ self, ... }:
{
  system = {
    # configurationRevision = self.rev or self.dirtyRev or null;
    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    stateVersion = 4;

    defaults = {
      dock = {
        autohide = true;
        orientation = "bottom";
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
      };
      WindowManager = {
        EnableStandardClickToShowDesktop = true;
      };
      menuExtraClock = {
        Show24Hour = true;
      };
    };
  };
}
