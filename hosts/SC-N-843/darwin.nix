{
  ...
}:
{
  imports = [
    ../../nix-darwin/modules/users.nix
    ../../nix-darwin/modules/shells.nix
    ../../nix-darwin/modules/fonts.nix
    ../../nix-darwin/modules/nix.nix
    ../../nix-darwin/modules/system.nix
    ../../nix-darwin/modules/homebrew.nix
    ../../nix-darwin/modules/services/aerospace.nix
    ../../nix-darwin/modules/services/karabiner-elements.nix
    ../../nix-darwin/modules/programs/1password.nix
    ../../nix-darwin/modules/hosts/SC-N-843.nix
    # networkingは会社管理のため含めない
  ];
}
