# darwin (default.nix) / server (server.nix) 共通の Claude Code 設定。
# ホスト固有分 (macOS sandbox, voiceEnabled, Mnemos, codex plugin 等) は
# それぞれの呼び出し元で `common.settings // { ... }` として上書き・追加する。
{ pkgs }:
let
  claudeCodePackage = import ./package.nix { inherit pkgs; };
  herdrIntegration = import ./herdr-hooks.nix { inherit pkgs; };
  herdrClaudeHooks = herdrIntegration.hooks;
  statuslineScript = pkgs.writeShellScript "claude-statusline" (
    builtins.readFile ./statusline-command.sh
  );
in
{
  package = claudeCodePackage;
  inherit herdrIntegration;

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
    # fullscreen (alt-screen) レンダラー。旧 env CLAUDE_CODE_NO_FLICKER=1 と等価。
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

      # wrapper の --set DISABLE_AUTOUPDATER は wrapper 経由の起動しか守れない。
      # native binary (chrome-native-host 等) も settings.json の env は読むため、
      # ここで無効化しないと updater が ~/.local/bin/claude を再生成し
      # Nix wrapper を PATH shadow する (2026-06-28, 2026-07-05 に再発)。
      DISABLE_AUTOUPDATER = "1";

      CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
      CLAUDE_CODE_NEW_INIT = "1";
    };

    hooks = herdrClaudeHooks // {
      # herdr の汎用 PreToolUse エントリ。
      PreToolUse = herdrClaudeHooks.PreToolUse ++ [
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
    };

    enabledPlugins = {
      # thinceller-claude-plugins
      "git-toolkit@thinceller-claude-plugins" = true;
      "engineering@thinceller-claude-plugins" = true;
    };
  };
}
