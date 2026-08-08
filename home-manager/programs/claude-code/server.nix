# oberon (サーバー) 用の Claude Code 設定。darwin 版 (default.nix) から
# macOS sandbox (Seatbelt) / cage / Mnemos (vault) / codex plugin を除き、
# herdr integration と statusline を維持したもの。
{
  pkgs,
  config,
  ...
}:
let
  common = import ./common.nix { inherit pkgs; };
in
{
  imports = [ ./deploy.nix ];

  programs.claude-code = {
    enable = true;
    package = common.package;

    settings = common.settings;

    memory.source = ./user-memory.md;

    # user-memory.md の Lead Agent Policy が explorer / worker への委譲を
    # 指示するため、agent 定義 (guard スクリプト込み) をサーバーにも配る。
    agentsDir = ./agents;

    skills = {
      herdr = ./skills/herdr;
    };
  };

  # release-25.11 の claude-code module は skills 値が「文字列」だと inline
  # content として .md ファイル化してしまう (lib.isPath 判定)。hunk package の
  # store path 文字列はディレクトリなので、home.file で直接 symlink する。
  home.file.".claude/skills/hunk-review".source =
    "${config.programs.hunk.package}/skills/hunk-review";
}
