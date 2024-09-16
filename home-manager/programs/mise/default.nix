{ pkgs }: {
  programs.mise = {
    enable = true;
    globalConfig = {
      tools = {
        node = "20";
        deno = "latest";
        go = "latest";
        ruby = "3.3.0";
        dotnet = "8.0.204";
      };

      settings = {
        legacy_version_file = true;
      };
    };
  };
}
