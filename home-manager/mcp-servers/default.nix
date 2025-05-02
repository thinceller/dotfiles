{
  pkgs,
  config,
  mcp-servers-nix,
  ...
}:
let
  mcp-config = mcp-servers-nix.lib.mkConfig pkgs {
    programs = {
      brave-search = {
        enable = true;
        envFile = config.sops.secrets.brave-api-key.path;
      };
      github = {
        enable = true;
        envFile = config.sops.secrets.github-token.path;
      };
      playwright = {
        enable = true;
        args = [ "--headless" ];
      };
    };
    # settings.servers = {
    #   mcp-claude-code = {
    #     command = "${pkgs.lib.getExe' pkgs.nodejs "npx"}";
    #     args = [
    #       "-y"
    #       "@anthropic-ai/claude-code"
    #       "mcp"
    #       "serve"
    #     ];
    #   };
    #   mcp-obsidian = {
    #     command = "${pkgs.lib.getExe' pkgs.nodejs "npx"}";
    #     args = [
    #       "-y"
    #       "mcp-obsidian"
    #       "Users/thinceller/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian Vault"
    #     ];
    #   };
    # };
  };
in
[
  {
    sops.secrets.brave-api-key = { };
    sops.secrets.github-token = { };

    home.file."Library/Application Support/Claude/claude_desktop_config.json" = {
      source = mcp-config;
    };
  }
]
