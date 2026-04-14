{
  pkgs,
  ...
}:
let
  notificationScript = pkgs.writeShellScript "claude-notification" (
    builtins.replaceStrings [ "@iconPath@" ] [ "${./hooks/claude-icon.png}" ] (
      builtins.readFile ./hooks/notification.sh
    )
  );
  openPlanScript = pkgs.writeShellScript "claude-open-plan" (builtins.readFile ./hooks/open-plan.sh);
  statuslineScript = pkgs.writeShellScript "claude-statusline" (
    builtins.readFile ./statusline-command.sh
  );

  # Override edgepkgs' wrapProgram to place the binary in libexec/ instead of
  # renaming it to .claude-wrapped. This preserves the process name as "claude"
  # (via p_comm), which tools like tcmux rely on for session detection.
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
  programs.claude-code = {
    enable = true;
    package = claudeCodePackage;
    enableMcpIntegration = true;

    settings = {
      theme = "dark";
      autoCompactEnabled = false;
      enableAllProjectMcpServers = true;
      alwaysThinkingEnabled = true;
      language = "japanese";
      autoMemoryEnabled = true;
      cleanupPeriodDays = 9999;

      model = "opusplan";
      advisorModel = "opus";
      effortLevel = "high";
      voiceEnabled = true;
      skipAutoPermissionPrompt = true;

      # sandbox = {
      #   enabled = true;
      #   excludedCommands = [
      #     "docker"
      #     "git"
      #     "gh"
      #     "nix"
      #   ];
      #   network = {
      #     allowLocalBinding = true;
      #   };
      # };

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
          "Write(~/.ssh/**)"
          "Write(.env*)"
        ];
        defaultMode = "auto";
      };

      env = {
        BASH_DEFAULT_TIMEOUT_MS = "60000";
        BASH_MAX_TIMEOUT_MS = "180000";
        CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR = "1";
        USE_BUILTIN_RIPGREP = "1";

        ANTHROPIC_DEFAULT_OPUS_MODEL = "claude-opus-4-6[1m]";

        ENABLE_TOOL_SEARCH = true;
        ENABLE_EXPERIMENTAL_MCP_CLI = false;
        CLAUDE_CODE_ENABLE_TASKS = true;
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
        CLAUDE_CODE_NEW_INIT = "1";
        CLAUDE_CODE_NO_FLICKER = "1";
      };

      hooks = {
        Notification = [
          {
            matcher = "permission_prompt|idle_prompt|elicitation_dialog";
            hooks = [
              {
                type = "command";
                command = notificationScript;
              }
            ];
          }
        ];
        PreToolUse = [
          {
            matcher = "ExitPlanMode";
            hooks = [
              {
                type = "command";
                command = openPlanScript;
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
        "chrome-devtools-plugins" = {
          source = {
            source = "github";
            repo = "ChromeDevTools/chrome-devtools-mcp";
          };
        };
        "thinceller-claude-plugins" = {
          source = {
            source = "github";
            repo = "thinceller/claude-plugins";
          };
        };
      };

      enabledPlugins = {
        # claude-plugins-official
        "claude-code-setup@claude-plugins-official" = true;
        "claude-md-management@claude-plugins-official" = true;
        "superpowers@claude-plugins-official" = true;
        "plugin-dev@claude-plugins-official" = true;
        "skill-creator@claude-plugins-official" = true;
        "frontend-design@claude-plugins-official" = true;
        "ralph-loop@claude-plugins-official" = true;
        "code-simplifier@claude-plugins-official" = true;
        "code-review@claude-plugins-official" = true;
        "pr-review-toolkit@claude-plugins-official" = true;
        "discord@claude-plugins-official" = true;

        # chrome-devtools-plugins
        "chrome-devtools-mcp@chrome-devtools-plugins" = true;

        # thinceller-claude-plugins
        "git-toolkit@thinceller-claude-plugins" = true;
      };
    };

    memory.source = ./user-memory.md;

    # agentsDir = ./agents;
    skillsDir = ./skills;
    # hooksDir = ./hooks;
  };

  programs.mcp.enable = true;

  mcp-servers.programs = {
    context7.enable = true;
  };

  mcp-servers.settings.servers = {
    chrome-devtools = {
      command = "${pkgs.lib.getExe' pkgs.nodejs "npx"}";
      args = [
        "-y"
        "chrome-devtools-mcp@latest"
        "--headless=true"
        "--isolated=true"
      ];
    };
    notion = {
      type = "http";
      url = "https://mcp.notion.com/mcp";
    };
    figma = {
      type = "http";
      url = "https://mcp.figma.com/mcp";
    };
  };
}
