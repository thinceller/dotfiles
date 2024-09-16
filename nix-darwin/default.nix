{ pkgs, inputs, ... }: {
  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  # network configurations
  networking.computerName = "kohei-macbook-air";
  networking.hostName = "kohei-macbook-air";

  environment.shells = [ pkgs.bashInteractive pkgs.zsh pkgs.fish ];

  users.knownUsers = [ "thinceller" ];
  users.users."thinceller" = {
    uid = 501;
    home = "/Users/thinceller";
    shell = pkgs.fish;
  };

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  # nix.package = pkgs.nix;

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true;
  programs.fish.enable = true;

  # Use Touch ID for sudo authentication.
  security.pam.enableSudoTouchIdAuth = true;

  # Set Git commit hash for darwin-version.
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  system.defaults = {
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
      EnableStandardClickToShowDesktop = false;
    };
    menuExtraClock = {
      Show24Hour = true;
    };
  };
}
