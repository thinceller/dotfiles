# oberon (サーバー) 用の Claude Code 設定。darwin 版 (default.nix) から
# macOS sandbox (Seatbelt) / cage / Mnemos (vault) / codex plugin を除き、
# herdr integration と statusline を維持したもの。
{
  pkgs,
  config,
  ...
}:
let
  statuslineScript = pkgs.writeShellScript "claude-statusline" (
    builtins.readFile ./statusline-command.sh
  );
  claudeCodePackage = import ./package.nix { inherit pkgs; };
  herdrIntegration = import ./herdr-hooks.nix { inherit pkgs; };
in
{
  programs.claude-code = {
    enable = true;
    package = claudeCodePackage;

    settings = {
      theme = "dark";
      autoCompactEnabled = false;
      alwaysThinkingEnabled = true;
      language = "japanese";
      autoMemoryEnabled = true;
      cleanupPeriodDays = 9999;

      model = "opus";
      skipAutoPermissionPrompt = true;
      useAutoModeDuringPlan = true;
      tui = "fullscreen";

      permissions = {
        allow = [
          "WebFetch"
          "WebSearch"
          "Bash(ls:*)"
          "Bash(grep:*)"
        ];
        ask = [
          "Bash(rm:*)"
          "Bash(git merge:*)"
          "Bash(git rebase:*)"
          "Bash(git push:*)"
        ];
        deny = [
          "Read(~/.ssh/**)"
          "Read(.env*)"
          "Bash(sudo:*)"
          "Bash(git commit --no-gpg-sign:*)"
          "Edit(~/.ssh/**)"
          "Edit(.env*)"
        ];
        defaultMode = "auto";
      };

      env = {
        BASH_DEFAULT_TIMEOUT_MS = "60000";
        BASH_MAX_TIMEOUT_MS = "180000";
        CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR = "1";
        DISABLE_AUTOUPDATER = "1";
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
        CLAUDE_CODE_NEW_INIT = "1";
      };

      hooks = herdrIntegration.hooks // {
        PreToolUse = herdrIntegration.hooks.PreToolUse ++ [
          {
            matcher = "*";
            hooks = [
              {
                type = "command";
                command = herdrIntegration.toolMetadataScript;
                timeout = 10;
              }
            ];
          }
        ];
      };

      statusLine = {
        type = "command";
        command = statuslineScript;
      };

      extraKnownMarketplaces = {
        "thinceller-claude-plugins" = {
          source = {
            source = "github";
            repo = "thinceller/claude-plugins";
          };
        };
        "superpowers-dev" = {
          source = {
            source = "github";
            repo = "obra/superpowers";
          };
        };
      };

      enabledPlugins = {
        "superpowers@superpowers-dev" = true;
        "git-toolkit@thinceller-claude-plugins" = true;
      };
    };

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
