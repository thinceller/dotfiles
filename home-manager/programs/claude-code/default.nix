{
  pkgs,
  mcp-servers-nix,
}:
{
  programs.claude-code = {
    enable = true;
    package = pkgs.edge.claude-code;

    settings = {
      includeCoAuthoredBy = true;
      theme = "dark";
      autoCompactEnabled = false;
      enableAllProjectMcpServers = true;
      alwaysThinkingEnabled = true;
      language = "japanese";

      model = "opus";

      sandbox = {
        enabled = true;
        excludedCommands = [
          "docker"
          "git"
          "gh"
          "nix"
        ];
        network = {
          allowLocalBinding = true;
        };
      };

      permissions = {
        allow = [
          "WebFetch"
          "WebSearch"
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
          "Bash(rm -rf:*)"
          "Write(~/.ssh/**)"
          "Write(.env*)"
        ];
        defaultMode = "plan";
      };

      env = {
        BASH_DEFAULT_TIMEOUT_MS = "60000";
        BASH_MAX_TIMEOUT_MS = "180000";
        CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR = "1";
        CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
        MAX_THINKING_TOKENS = "31999";
        USE_BUILTIN_RIPGREP = "1";

        ENABLE_TOOL_SEARCH = true;
        ENABLE_EXPERIMENTAL_MCP_CLI = false;
      };

      hooks = {
        Stop = [
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = "terminal-notifier -title 'Claude Code' -message 'タスクが完了しました！' -sound Breeze";
              }
            ];
          }
        ];
      };

      statusLine = {
        type = "command";
        command = ./statusline-command.sh;
      };

      enabledPlugins = {
        "code-review@claude-plugins-official" = true;
        "commit-commands@claude-plugins-official" = true;
        "feature-dev@claude-plugins-official" = true;
        "frontend-design@claude-plugins-official" = true;
        "plugin-dev@claude-plugins-official" = true;
        "pr-review-toolkit@claude-plugins-official" = true;
        "code-simplifier@claude-plugins-official" = true;
      };
    };

    memory.source = ./CLAUDE.md;

    # agentsDir = ./agents;
    commandsDir = ./commands;
    skillsDir = ./skills;
    # hooksDir = ./hooks;

    mcpServers =
      (mcp-servers-nix.lib.evalModule pkgs {
        programs = {
          context7.enable = true;
        };
        settings.servers = {
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
      }).config.settings.servers;
  };
}
