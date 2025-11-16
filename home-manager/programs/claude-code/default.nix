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
      alwaysThinkinEnabled = true;

      sandbox = {
        enabled = true;
        excludedCommands = [ "git" ];
        network = {
          allowLocalBinding = true;
        };
      };

      permissions = {
        allow = [
          "WebFetch"
          "WebSearch"
        ];
        deny = [
          "Read(~/.ssh)"
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
      };

      hooks = {
        Notification = [
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = "terminal-notifier -title 'Claude Code' -message 'あなたの入力を待っています' -sound Submerge";
              }
            ];
          }
        ];
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
    };

    memory.source = ./CLAUDE.md;

    # agentsDir = ./agents;
    commandsDir = ./commands;
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
