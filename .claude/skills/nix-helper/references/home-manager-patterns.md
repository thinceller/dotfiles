# Home Manager Patterns

## Module Structure

### Standard Program Module

```nix
# home-manager/programs/program-name/default.nix
{ pkgs, ... }:
{
  programs.program-name = {
    enable = true;
    settings = {
      # Configuration options
    };
  };
}
```

### Module with Extra Config Files

```nix
{ pkgs, config, ... }:
{
  programs.program-name = {
    enable = true;
  };

  xdg.configFile."program-name/extra.conf".text = ''
    # Additional configuration
  '';
}
```

### Module with Dependencies

```nix
{ pkgs, lib, ... }:
{
  programs.program-name = {
    enable = true;
    package = pkgs.program-name;
  };

  home.packages = with pkgs; [
    dependency-1
    dependency-2
  ];
}
```

## Import Patterns

### Program List Pattern

The repository uses a list-based import pattern:

```nix
# home-manager/programs/default.nix
{ pkgs, ... }:
let
  git = import ./git { inherit pkgs; };
  fish = import ./fish { inherit pkgs; };
  starship = import ./starship { inherit pkgs; };
in
[
  git
  fish
  starship
]
```

### With userConfig

```nix
{ pkgs, userConfig, ... }:
let
  git = import ./git { inherit pkgs userConfig; };
in
[
  git
]
```

## Configuration Patterns

### Environment Variables

```nix
{
  home.sessionVariables = {
    EDITOR = "nvim";
    PAGER = "less";
    MY_VAR = "value";
  };
}
```

### Shell Aliases

```nix
{
  home.shellAliases = {
    ll = "ls -la";
    ".." = "cd ..";
    g = "git";
  };
}
```

### XDG Configuration Files

```nix
{
  # Single file
  xdg.configFile."app/config.toml".source = ./config.toml;

  # Generated content
  xdg.configFile."app/settings.json".text = builtins.toJSON {
    theme = "dark";
    fontSize = 14;
  };

  # Directory
  xdg.configFile."app" = {
    source = ./app-config;
    recursive = true;
  };
}
```

### Out-of-Store Symlinks

For configs that need editing without rebuild:

```nix
{ config, userConfig, ... }:
let
  rootDir = userConfig.dotfilesDir + "/configs";
  symlink = config.lib.file.mkOutOfStoreSymlink;
in
{
  xdg.configFile."nvim" = {
    source = symlink /${rootDir}/.config/nvim;
    recursive = true;
  };
}
```

## Conditional Configuration

### By Hostname

```nix
{ userConfig, lib, ... }:
{
  programs.git.extraConfig = lib.mkIf (userConfig.hostname == "kohei-m4-mac-mini") {
    commit.gpgsign = true;
  };
}
```

### By Platform

```nix
{ pkgs, lib, ... }:
{
  programs.my-program = {
    enable = true;
    settings = {
      path = if pkgs.stdenv.isDarwin
        then "/opt/homebrew/bin"
        else "/usr/bin";
    };
  };
}
```

## Service Integration

### Launchd Services (macOS)

```nix
{
  launchd.agents.my-service = {
    enable = true;
    config = {
      ProgramArguments = [ "${pkgs.my-program}/bin/my-program" "--daemon" ];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
```

## Common Home Manager Options

### Useful Program Options

```nix
{
  programs.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "email@example.com";
    extraConfig = { };
    aliases = { };
    ignores = [ ".DS_Store" ];
  };

  programs.fish = {
    enable = true;
    shellInit = "";
    interactiveShellInit = "";
    plugins = [ ];
    functions = { };
  };

  programs.starship = {
    enable = true;
    settings = { };
  };
}
```

### Home State Version

Always set the state version for reproducibility:

```nix
{
  home.stateVersion = "24.05";
}
```
