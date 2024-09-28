{ pkgs, wezterm-flake }: {
  programs.wezterm = {
    enable = true;
    package = wezterm-flake.packages.${pkgs.system}.default;
    extraConfig = ''
      return {
        font = wezterm.font("HackGen Console NF"),
        use_ime = true,
      }
    '';
  };
}
