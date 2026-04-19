{
  ...
}:
{
  programs.mcp.enable = true;

  mcp-servers.programs = {
    context7.enable = true;
  };

  mcp-servers.settings.servers = {
    figma = {
      type = "http";
      url = "https://mcp.figma.com/mcp";
    };
  };
}
