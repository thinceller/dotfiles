# Package Management

## Standard Packages (nixpkgs)

Add packages in `home-manager/pkgs/default.nix`:

```nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    # Add new packages here
  ];
}
```

## Claude Code (claude-code-overlay)

The claude-code package is provided via claude-code-overlay, which builds from Anthropic's official binary:

```nix
{ pkgs, ... }:
{
  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code;
  };
}
```

The overlay is configured in each host's `default.nix`:

```nix
pkgs = import nixpkgs {
  overlays = [ claude-code-overlay.overlays.default ];
};
```

## External Packages (nvfetcher)

For packages not in nixpkgs, use nvfetcher.

### Step 1: Define Source

Add to `nvfetcher.toml`:

```toml
# GitHub release
[package-name]
src.github = "owner/repo"
fetch.github = "owner/repo"

# Git repository
[another-package]
src.git = "https://github.com/owner/repo.git"
fetch.git = "https://github.com/owner/repo.git"

# Specific branch
[branch-package]
src.git = "https://github.com/owner/repo.git"
src.branch = "main"
fetch.git = "https://github.com/owner/repo.git"
```

### Step 2: Generate Sources

```bash
nvfetcher
```

This updates `_sources/generated.nix`.

### Step 3: Use in Configuration

```nix
{ pkgs, ... }:
let
  sources = pkgs.callPackage ../_sources/generated.nix { };
in
{
  programs.my-program = {
    enable = true;
    package = pkgs.stdenv.mkDerivation {
      name = "my-package";
      src = sources.package-name.src;
      # ... build instructions
    };
  };
}
```

## Package Search

Find packages in nixpkgs:

```bash
# Search nixpkgs
nix search nixpkgs package-name

# Search with more details
nix search nixpkgs#package-name --json | jq
```

## Common Patterns

### Conditional Packages by Host

```nix
{ pkgs, userConfig, ... }:
{
  home.packages = with pkgs; [
    # Common packages
    ripgrep
  ] ++ lib.optionals (userConfig.hostname == "kohei-m4-mac-mini") [
    # Personal machine only
    discord
  ];
}
```

### Platform-Specific Packages

```nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Common
    curl
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    # macOS only
    cocoapods
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    # Linux only
    xclip
  ];
}
```
