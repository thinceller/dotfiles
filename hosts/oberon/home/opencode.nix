# oberon 専用の OpenCode 設定 (サーバー向けリーン構成)。
#
# darwin 版 (home-manager/programs/opencode/default.nix) とは独立で、
# 共有するのは herdr integration plugin の実ファイルのみ。
# vault references / vault-session-log / superpowers / tmux-agent-sidebar は
# サーバーには持ち込まない (knowledge-base checkout が無い)。
#
# 認証: OPENCODE_GO_API_KEY 環境変数のみ (OAuth 不要)。値は hermes と共用の
# OpenCode Go トークンで、sops secret "opencode-go-api-key" (hosts/oberon/users.nix)
# → fish shellInit (hosts/oberon/home/default.nix) 経由で供給される。
{ pkgs, ... }:
{
  programs.opencode = {
    enable = true;
    # nixos-25.11 の opencode (Mac の unstable 版よりバージョンが古い可能性あり)。
    # settings のキーが古い版に拒否されたらそのキーを外す方針。unstable からの
    # 取り込みは eval RAM コストがあるため最終手段。
    # NOTE: HM release-25.11 の opencode モジュールには extraPackages / tui
    # option が無いため、依存ツールは home.packages で供給し、theme は
    # settings (opencode config) 直下に書く。
    package = pkgs.opencode;

    settings = {
      theme = "tokyonight";
      model = "opencode-go/glm-5.2";
      small_model = "opencode-go/minimax-m3";
      autoupdate = false;
      share = "manual";
      snapshot = true;

      permission = {
        bash = {
          "*" = "ask";
          "ls*" = "allow";
          "grep*" = "allow";
          "git status*" = "allow";
          "git diff*" = "allow";
          "git log*" = "allow";
          "rm*" = "ask";
          "git merge*" = "ask";
          "git rebase*" = "ask";
          "git push*" = "ask";
          "sudo*" = "deny";
        };
        webfetch = "allow";
        websearch = "allow";
        read = {
          "*" = "allow";
          "*.env" = "deny";
          "*.env.*" = "deny";
          "~/.ssh/**" = "deny";
        };
        edit = {
          "*" = "allow";
          "*.env*" = "deny";
          "~/.ssh/**" = "deny";
        };
        external_directory = "ask";
      };

      watcher = {
        ignore = [
          "node_modules/**"
          ".git/**"
          "dist/**"
          "build/**"
        ];
      };
    };
  };

  # extraPackages option が 25.11 HM に無いため、opencode が呼ぶツールを直接供給する。
  home.packages = with pkgs; [
    git
    gh
  ];

  # herdr integration (darwin と同一ファイルを共有。HERDR_INTEGRATION_VERSION=8)。
  xdg.configFile."opencode/plugins/herdr-agent-state.js".source =
    ../../../home-manager/programs/opencode/plugins/herdr-agent-state.js;
}
