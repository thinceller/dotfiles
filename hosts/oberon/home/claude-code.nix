# oberon 専用の Claude Code 設定 (サーバー向けリーン構成)。
#
# darwin 版 (home-manager/programs/claude-code/default.nix) とは独立で、
# 共有するのは実ファイルのみ: herdr hook / skills / user-memory.md。
# macOS 前提の要素 (Seatbelt sandbox、1Password、statusline の BSD date、
# Mnemos vault hooks、plugins/marketplaces、MCP 統合) は持ち込まない。
# 必要になったら個別に足す。
#
# 認証は初回のみ手動: SSH で入って `claude` → /login。状態は ~/.claude に永続化。
{ pkgs, ... }:
let
  shared = ../../../home-manager/programs/claude-code;

  # herdr integration hook (darwin と同一ファイルを共有)。
  # `herdr integration install claude` が書き出すものの vendor 版で、
  # HERDR_INTEGRATION_VERSION=7。上流 bump 時は darwin 側と同時に更新される。
  herdrAgentStateScript = pkgs.writeShellScript "claude-herdr-agent-state" (
    builtins.readFile (shared + "/hooks/herdr-agent-state.sh")
  );

  herdrClaudeHook = arg: {
    matcher = "*";
    hooks = [
      {
        type = "command";
        command = "${herdrAgentStateScript} ${arg}";
        timeout = 10;
      }
    ];
  };

  # darwin 版と同じ意図の override: binary を .claude-wrapped にリネームさせず
  # libexec/claude に置き、process 名を "claude" に保つ (herdr / tcmux の
  # エージェント検出が process 名に依存するため)。
  claudeCodePackage = pkgs.edge.claude-code-bin.overrideAttrs (_old: {
    installPhase = ''
      runHook preInstall

      mkdir -p $out/libexec $out/bin
      install -m755 $src $out/libexec/claude

      makeBinaryWrapper $out/libexec/claude $out/bin/claude \
        --inherit-argv0 \
        --set DISABLE_AUTOUPDATER 1 \
        --set USE_BUILTIN_RIPGREP 0 \
        --set DISABLE_INSTALLATION_CHECKS 1 \
        --prefix PATH : ${
          pkgs.lib.makeBinPath (
            with pkgs;
            [
              procps
              ripgrep
            ]
          )
        }

      runHook postInstall
    '';
  });
in
{
  # herdr の claude hook は python3 を要求する (無ければ hook が早期 exit して
  # sidebar の状態検出が働かない)。
  home.packages = [ pkgs.python3 ];

  programs.claude-code = {
    enable = true;
    package = claudeCodePackage;

    settings = {
      theme = "dark";
      language = "japanese";
      alwaysThinkingEnabled = true;
      autoMemoryEnabled = true;

      model = "opus";

      # sandbox は設定しない: darwin 版の sandbox 設定は macOS Seatbelt 前提。
      # Linux (bubblewrap) 対応はサーバー運用が固まってから別途検討する。
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
          "Edit(~/.ssh/**)"
          "Edit(.env*)"
        ];
        defaultMode = "auto";
      };

      env = {
        BASH_DEFAULT_TIMEOUT_MS = "60000";
        BASH_MAX_TIMEOUT_MS = "180000";
        CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR = "1";
        USE_BUILTIN_RIPGREP = "1";

        ANTHROPIC_DEFAULT_OPUS_MODEL = "claude-opus-4-7[1m]";

        # wrapper の --set は wrapper 経由の起動しか守れないため settings でも無効化
        # (darwin 側で updater が ~/.local/bin/claude を再生成した実績あり)。
        DISABLE_AUTOUPDATER = "1";
      };

      hooks = {
        SessionStart = [ (herdrClaudeHook "session") ];
        Stop = [ (herdrClaudeHook "idle") ];
        SubagentStop = [ (herdrClaudeHook "working") ];
        SessionEnd = [ (herdrClaudeHook "release") ];
        UserPromptSubmit = [ (herdrClaudeHook "working") ];
        PreToolUse = [ (herdrClaudeHook "working") ];
        PostToolUse = [ (herdrClaudeHook "working") ];
      };
    };

    # user memory と skills は darwin と共有 (herdr スキル等をそのまま使う)。
    context = shared + "/user-memory.md";
    skills = shared + "/skills";
  };
}
