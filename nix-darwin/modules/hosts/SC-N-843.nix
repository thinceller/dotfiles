{
  ...
}:
{
  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
    # watchIdAuthは使わない
  };

  homebrew.casks = [
    "cursor"
    "figma"
    "sequel-ace"
  ];
}
