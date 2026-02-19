{ ... }:
{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = true;

      format = builtins.concatStringsSep "" [
        "$directory"
        "$git_branch"
        "$git_status"
        "$line_break"
        "$character"
      ];

      right_format = builtins.concatStringsSep "" [
        "$cmd_duration"
        "$jobs"
        "$nix_shell"
        "$nodejs"
        "$python"
        "$ruby"
        "$golang"
        "$rust"
        "$php"
      ];

      character = {
        success_symbol = "[❯](bold #7aa2f7)";
        error_symbol = "[❯](bold #f7768e)";
      };

      directory = {
        style = "bold #7dcfff";
        truncation_length = 3;
        truncate_to_repo = true;
      };

      git_branch = {
        style = "bold #bb9af7";
        format = "[$symbol$branch]($style) ";
      };

      git_status.style = "bold #e0af68";

      cmd_duration = {
        style = "bold #e0af68";
        min_time = 2000;
      };

      nix_shell = {
        style = "bold #7aa2f7";
        format = "[$symbol$state]($style) ";
      };

      nodejs.style = "bold #73daca";
      python.style = "bold #e0af68";
      golang.style = "bold #7dcfff";
      rust.style = "bold #f7768e";

      kubernetes.disabled = true;
      aws.disabled = true;
      gcloud.disabled = true;
      azure.disabled = true;
    };
  };
}
