{
  pkgs,
  config,
  sources,
  userConfig,
  ...
}:
let
  inherit (userConfig) homeDir dotfilesDir;
in
{
  programs.fish = {
    enable = true;
    functions = {
      cc = {
        body = ''
          set git_root (git rev-parse --show-toplevel 2>/dev/null)
          if test $status -eq 0
            cd $git_root
            claude --dangerously-skip-permissions $argv
          else
            echo "Not in a git repository"
            return 1
          end
        '';
        description = "Move to git root and run claude with arguments";
      };
    };
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
      gw = "git wt";
      cgw = "cd (git-wt | fzf | awk '{print $1}')";
      null = {
        position = "anywhere";
        expansion = ">/dev/null 2>&1";
      };
      fbr = "git branch --list | fzf --preview \"git log --pretty=format:'%h %cd %s' --date=format:'%Y-%m-%d %H:%M' {}\" | xargs git switch";
      dc = "docker compose";
    };
    plugins = [
      {
        name = sources.fish-ghq.pname;
        src = sources.fish-ghq.src;
      }
    ];
    interactiveShellInit = ''
      if test -f "${dotfilesDir}/env.fish"
        source "${dotfilesDir}/env.fish"
      end

      fish_add_path /opt/homebrew/bin
      fish_add_path ${homeDir}/.local/bin
      git wt --init fish | source
      op completion fish | source
      export TEST=$(cat ${config.sops.secrets.test.path})
    '';
  };
}
