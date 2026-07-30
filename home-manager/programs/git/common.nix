# git の portable 設定 (darwin / linux 共通)。
# darwin 専用 (1Password SSH 署名, Cloudflare Access include, wt, gpg) は
# default.nix に置き、サーバーは server.nix がこのファイルだけを import する。
{ ... }:
{
  programs.git = {
    enable = true;
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
        # dotfiles (~/.dotfiles) も ghq list に載せるため root を複数指定する。
        # ghq 1.9.4 では git config の解決順 (last wins) で最後のエントリが
        # primary root (ghq get の clone 先) になるため ~/src を末尾に置く。
        root = [
          "~/.dotfiles"
          "~/src"
        ];
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
      ".claude/worktrees"
    ];
  };
}
