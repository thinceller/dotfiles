{
  pkgs,
  lib,
  sources,
  homeDir,
  config,
}:
{
  programs.fish = {
    enable = true;
    shellAbbrs = {
      gs = "git status --short --branch";
      gcim = {
        setCursor = true;
        expansion = "git commit -m '%'";
      };
      gcf = "git commit --fixup";
      gri = "git rebase -i";
      gsw = {
        setCursor = true;
        expansion = "git switch -c '%'";
      };
      gca = "git commit --amend --no-edit";
      gd = "git diff --no-index";
      null = {
        position = "anywhere";
        expansion = ">/dev/null 2>&1";
      };
      fbr = "git branch --list | fzf --preview \"git log --pretty=format:'%h %cd %s' --date=format:'%Y-%m-%d %H:%M' {}\" | xargs git switch";
      dc = "docker compose";
    };
    plugins = [
      {
        name = "tide";
        src = pkgs.fishPlugins.tide.src;
      }
      {
        name = sources.fish-ghq.pname;
        src = sources.fish-ghq.src;
      }
    ];
    interactiveShellInit = ''
      fish_add_path /opt/homebrew/bin
      op completion fish | source
      export TEST=$(cat ${config.sops.secrets.test.path})
    '';
  };

  home.activation.configure-tide = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.fish}/bin/fish -c "tide configure --auto --style=Lean --prompt_colors='True color' --show_time=No --lean_prompt_height='Two lines' --prompt_connection=Disconnected --prompt_spacing=Sparse --icons='Many icons' --transient=No"
  '';
}
