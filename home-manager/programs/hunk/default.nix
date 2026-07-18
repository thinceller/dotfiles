{ ... }:
{
  programs.hunk = {
    enable = true;
    # delta が git pager を占有しているので、hunk は pager を差し替えない。
    # `hunk diff` / `hunk show` で明示起動する運用。
    enableGitIntegration = false;
    settings = {
      theme = "github-dark-default";
      mode = "auto";
      line_numbers = true;
      wrap = true;
    };
  };
}
