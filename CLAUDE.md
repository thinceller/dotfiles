# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Nix-based dotfiles repository using Nix Flakes, Nix Darwin, and Home Manager to manage macOS system and user configurations across multiple machines.

## Common Development Commands

### Building and Applying Configuration
```bash
# Apply configuration for a specific host
sudo darwin-rebuild switch --flake .#kohei-m4-mac-mini
sudo darwin-rebuild switch --flake .#mf-0962-mm02
sudo darwin-rebuild switch --flake .#SC-N-843

# Update all dependencies (flake.lock and external sources)
nix run .#update

# Format all Nix and lua files
nix fmt

# Run pre-commit hooks manually
nix develop -c pre-commit run --all-files
```

### Working with Secrets
```bash
# Edit encrypted secrets file
sops secrets/secrets.yaml

# Add new encryption key
mkdir -p ~/.config/sops/age
nix-shell -p age --run "age-keygen -o ~/.config/sops/age/keys.txt"
```

## Architecture

### Directory Structure
- `flake.nix`: Main entry point defining inputs, outputs, and host configurations
- `hosts/`: Machine-specific configurations that combine nix-darwin and home-manager
- `nix-darwin/`: System-level macOS configurations (fonts, homebrew, services)
- `home-manager/`: User-level configurations
  - `programs/`: Individual CLI tool configurations
  - `pkgs/`: Package lists organized by category
  - `mcp-servers/`: Claude MCP server configurations
- `configs/`: Raw configuration files that get symlinked to home directory
- `secrets/`: SOPS-encrypted secrets

### Key Design Patterns
1. **Host Configuration**: Each machine has its own directory under `hosts/` with a `default.nix` that imports both nix-darwin and home-manager modules
2. **Module Organization**: Configurations are split into logical modules (e.g., `fonts.nix`, `homebrew.nix`) for reusability
3. **Package Management**: Uses Nix for CLI tools and development packages, Homebrew Casks for GUI applications
4. **File Management**: Configuration files in `configs/` are symlinked using `home-manager/files.nix`

### Adding New Configurations
1. **New Program**: Create a new file in `home-manager/programs/` and import it in `home-manager/default.nix`
2. **New Package**: Add to appropriate list in `home-manager/pkgs/` (cli.nix, development.nix, etc.)
3. **New Config File**: Place in `configs/.config/` and add to `home-manager/files.nix`
4. **New Host**: Create directory under `hosts/` with `default.nix` following existing patterns

### External Dependencies
- Uses `nvfetcher` to manage packages not in nixpkgs (configured in `nvfetcher.toml`)
- External sources are generated in `_sources/` directory
