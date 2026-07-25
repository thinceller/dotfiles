# oberon (サーバー) 用の git 設定。darwin 版 (default.nix) から
# 1Password SSH 署名 / Cloudflare Access include / wt を除いたもの。
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
