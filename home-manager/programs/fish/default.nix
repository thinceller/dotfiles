{ pkgs, sources }: {
  programs.fish = {
    enable = true;
    shellAbbrs = {
      gs = "git status --short --branch";
      gcim = "git commit -m";
      gcf = "git commit --fixup";
      gri = "git rebase -i";
      gsw = "git switch -c";
      gca = "git commit --amend --no-edit";
      gd = "git diff --no-index";
      null = ">/dev/null 2>&1";
    };
    plugins = [
      {
        name = sources.fish-ghq.pname;
        src = sources.fish-ghq.src;
      }
    ];
    interactiveShellInit = ''
      op completion fish | source
      source /Users/thinceller/.config/op/plugins.sh
    '';
  };
}
