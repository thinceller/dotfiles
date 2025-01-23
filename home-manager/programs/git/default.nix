{ pkgs }:
{
  programs.gpg.enable = true;

  programs.git = {
    enable = true;
    aliases = {
      pushf = "push --force-with-lease --force-if-includes";
    };
    delta = {
      enable = true;
    };
    signing = {
      key = "2AF8844D09D0ACAB67D5539D961BEC4D4FE5E3C3";
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
      commit = {
        gpgsign = true;
      };
      tag = {
        gpgsign = true;
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
