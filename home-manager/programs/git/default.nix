{ pkgs, ... }:
{
  programs.gpg.enable = true;

  programs.git = {
    enable = true;
    signing = {
      format = "ssh";
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILQwsbXl/1tHIdW/f+fZE7TJArqzvmbbaUsdKRFPoyZB";
      signByDefault = true;
    };
    settings = {
      alias = {
        pushf = "push --force-with-lease --force-if-includes";
      };
      user = {
        email = "thinceller@gmail.com";
        name = "thinceller";
      };
      core = {
        editor = "vim";
      };
      ghq = {
        root = "~/src";
      };
      wt = {
        basedir = "./.git/wt";
        copy = [
          ".claude/settings.local.json"
        ];
      };
      gpg = {
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
      ".claude/worktrees"
    ];
  };
}
