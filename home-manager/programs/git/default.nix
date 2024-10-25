{ pkgs }: {
  programs.git = {
    enable = true;
    aliases = {
      pushf = "push --force-with-lease --force-if-includes";
    };
    delta = {
      enable = true;
    };
    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILQwsbXl/1tHIdW/f+fZE7TJArqzvmbbaUsdKRFPoyZB";
      signByDefault = true;
    };
    userEmail = "thinceller@gmail.com";
    userName = "thinceller";
    extraConfig = {
      core = {
        editor = "vim";
      };
      ghq = {
        root = "~/src";
      };
      gpg = {
        format = "ssh";
        ssh = {
          program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
        };
      };
      rebase = {
        autostash = true;
        autosquash = true;
      };
      pull = {
        rebase = true;
      };
      merge = {
        ff = false;
      };
      init = {
        defaultBranch = "main";
      };
    };
    ignores = [
      ".DS_Store"
    ];
  };
}
