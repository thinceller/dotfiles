{ pkgs, ... }:
{
  programs.mise = {
    enable = true;
    enableFishIntegration = true;
    globalConfig = {
      tools = {
        # Cloudflare CLI。mise は prerelease を latest 候補から外すため、"latest" だと
        # npm 上の無関係な旧パッケージ cf@0.15.0 に解決される。beta の間は明示 pin する
        "npm:cf" = "1.0.0-beta.10";
      };
      settings = {
        legacy_version_file = true;
        idiomatic_version_file_enable_tools = [
          "node"
          "ruby"
        ];
      };
    };
  };
}
