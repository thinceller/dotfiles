{ pkgs }: {
  programs.gh = {
    enable = true;
    extensions = with pkgs; [
      gh-poi
      gh-copilot
    ];
    settings = {
      git_protocol = "https";
      prompt = "enabled";
      aliases = {
        co = "pr checkout";
      };
    };
  };
}
