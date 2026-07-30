# fish の portable 設定 (darwin / linux 共通)。
# darwin 専用 (homebrew PATH, op/wt completion, sops env, cage 系) は
# default.nix、サーバー追加分は server.nix に置く。
{
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
        name = sources.fish-ghq.pname;
        src = sources.fish-ghq.src;
      }
      {
        name = sources.hydro.pname;
        src = sources.hydro.src;
      }
    ];
    interactiveShellInit = ''
      if test -f "${dotfilesDir}/env.fish"
        source "${dotfilesDir}/env.fish"
      end

      fish_add_path ${homeDir}/.local/bin
      herdr completion fish | source

      # hydro prompt (tokyonight palette)
      set -g hydro_color_pwd 7dcfff
      set -g hydro_color_git bb9af7
      set -g hydro_color_prompt 7aa2f7
      set -g hydro_color_error f7768e
      set -g hydro_color_duration e0af68
      set -g hydro_multiline true

      # starship の add_newline 相当: prompt の前に空行を挟む
      if not functions -q _hydro_original_prompt
        functions -c fish_prompt _hydro_original_prompt
        function fish_prompt
          echo
          _hydro_original_prompt
        end
      end

      # nvim の :terminal から起動された fish では direnv state が継承されるが
      # fish_add_path / mise activate に PATH を上書きされる。reload で復元する。
      if set -q NVIM; and set -q DIRENV_DIR
        direnv reload 2>/dev/null
      end
    '';
  };
}
