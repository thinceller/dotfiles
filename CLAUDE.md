# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Nix-based dotfiles repository using Nix Flakes, Nix Darwin, and Home Manager to manage macOS system and user configurations across multiple machines.

## Common Development Commands

### Building and Applying Configuration
```bash
# Apply configuration for a specific host
sudo darwin-rebuild switch --flake .#kohei-m4-mac-mini
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
# Edit encrypted secrets file (automatically decrypts/encrypts)
sops secrets/default.yaml

# Generate new age encryption key for a new machine
mkdir -p ~/.config/sops/age
nix-shell -p age --run "age-keygen -o ~/.config/sops/age/keys.txt"

# Display public key to add to .sops.yaml
age-keygen -y ~/.config/sops/age/keys.txt

# Re-encrypt secrets after adding/removing keys
sops -r secrets/default.yaml
```

See `docs/SOPS.md` for comprehensive secrets management documentation.

### Verification (for coding agents)
```bash
# Build configuration without applying (use for verification)
nix build .#darwinConfigurations.kohei-m4-mac-mini.system --no-link
nix build .#darwinConfigurations.SC-N-843.system --no-link

# Format check
nix fmt
```

**Important**: When creating new files, you must stage them with `git add` before running `nix build`, as Nix Flakes only sees files tracked by git.

## Architecture

### Directory Structure
- `flake.nix`: Main entry point defining inputs, outputs, and host configurations
- `hosts/`: Machine-specific configurations that combine nix-darwin and home-manager
  - Each host defines a `userConfig` with username, homeDir, hostname, and dotfilesDir
  - Work machines (like SC-N-843) use `nix-darwin/minimum-for-work.nix` instead of the default
- `nix-darwin/`: System-level macOS configurations (fonts, homebrew, services)
  - `default.nix`: Full configuration for personal machines
  - `minimum-for-work.nix`: Minimal configuration for work machines
- `home-manager/`: User-level configurations
  - `programs/`: Individual CLI tool configurations (each tool has its own directory)
  - `pkgs/`: Single file (`default.nix`) containing all packages to install
  - `services/`: User-level services
  - `files.nix`: Symlink configuration for files in `configs/`
- `configs/`: Raw configuration files (e.g., Neovim, Karabiner, ccstatusline)
- `secrets/`: SOPS-encrypted secrets (default.yaml)
- `_sources/`: Auto-generated external package sources (managed by nvfetcher)
- `.github/workflows/`: CI configuration (Cachix + nix build)

### Key Design Patterns

#### 1. Host Configuration with userConfig
Each host directory contains a `default.nix` that defines a `userConfig` object:
```nix
userConfig = {
  username = "thinceller";  # or "kawakami.kohei" for work
  homeDir = "/Users/${username}";
  hostname = "kohei-m4-mac-mini";
  dotfilesDir = homeDir + "/.dotfiles";
  uid = 501;  # Optional, only for work machines
};
```
This config is passed to both nix-darwin and home-manager modules via `specialArgs`.

#### 2. Module Import Pattern
Modules are organized into separate concerns and imported as lists:
```nix
# home-manager/default.nix
let
  programs = import ./programs { ... };  # Returns a list
  files = import ./files.nix { ... };    # Returns a list
  packages = import ./pkgs { ... };      # Returns a list
  services = import ./services;          # Returns a list
in
{
  imports = programs ++ files ++ packages ++ services;
}
```

Each module list is constructed by importing individual modules and collecting them. For example, `programs/default.nix` imports each program configuration and returns them as a list.

#### 3. Out-of-Store Symlinks for Mutable Configs
Files that need to be edited outside Nix (like Karabiner, Neovim configs) use out-of-store symlinks:
```nix
xdg.configFile."nvim" = {
  source = config.lib.file.mkOutOfStoreSymlink /${rootDir}/.config/nvim;
  recursive = true;
};
```
This allows editing configs directly without rebuilding the Nix store.

#### 4. External Package Management with nvfetcher
Packages not in nixpkgs are fetched via nvfetcher:
1. Define sources in `nvfetcher.toml`
2. Run `nvfetcher` to generate `_sources/generated.nix`
3. Import sources: `sources = pkgs.callPackage ../_sources/generated.nix { };`
4. Use in programs: `package = sources.package-name;`

#### 5. Claude Code with claude-code-overlay
The `claude-code-overlay` provides the claude-code package built from Anthropic's official binary:
```nix
pkgs = import nixpkgs {
  overlays = [ claude-code-overlay.overlays.default ];
};
# Then use: pkgs.claude-code
```

#### 6. MCP Servers Configuration
Claude Code MCP servers are configured using `mcp-servers-nix` in `home-manager/programs/claude-code/default.nix`. This includes both NPM-based servers (context7, chrome-devtools) and HTTP-based servers (Notion, Figma).

#### 7. Claude Code Global Skills and Commands
Global (user-level, not project-level) custom skills and commands for Claude Code are managed under `home-manager/programs/claude-code/`:
- `skills/`: Custom skills (e.g., `skill-creator`, `team-task`)
- `commands/`: Custom slash commands (e.g., `commit-staged-changes`)
- `home-manager/programs/claude-code/CLAUDE.md`: Claude Code project-specific memory

These are symlinked into `~/.claude/` via the `skillsDir` / `commandsDir` options, making them available globally across all projects.

#### 8. Homebrew Management
Homebrew packages are declaratively managed in `nix-darwin/modules/homebrew.nix`:
- `taps`: Third-party taps (e.g., `arto-app/tap`, `k1LoW/tap`)
- `brews`: CLI tools (e.g., `tcmux`)
- `casks`: GUI applications
- `onActivation.cleanup = "uninstall"`: Automatically removes undeclared packages

### Adding New Configurations

#### New Program
1. Create directory: `home-manager/programs/new-program/`
2. Add `default.nix` that returns a module (attrset with `programs.new-program = { ... }`)
3. Import in `home-manager/programs/default.nix`:
   ```nix
   let
     new-program = import ./new-program { inherit pkgs; };
   in
   [
     # ... existing programs
     new-program
   ]
   ```

#### New Package
Add directly to the packages list in `home-manager/pkgs/default.nix`:
```nix
home.packages = with pkgs; [
  # ... existing packages
  new-package
];
```

#### New Config File for Symlinking
1. Place file in `configs/.config/new-app/`
2. Add to `home-manager/files.nix`:
   ```nix
   xdg.configFile."new-app" = {
     source = symlink /${rootDir}/.config/new-app;
     recursive = true;
   };
   ```

#### New Homebrew Package
Add to `nix-darwin/modules/homebrew.nix`:
```nix
# For CLI tools
brews = [ "new-tool" ];
# For GUI apps
casks = [ "new-app" ];
# For third-party taps
taps = [ "owner/tap" ];
```

#### New Claude Code Skill
1. Create directory: `home-manager/programs/claude-code/skills/new-skill/`
2. Add `SKILL.md` with frontmatter (description, trigger patterns)
3. Optionally add `references/` directory for supplementary content

#### New Host
1. Create `hosts/new-hostname/default.nix`
2. Define `userConfig` with username, homeDir, hostname, dotfilesDir
3. Choose nix-darwin module: `../../nix-darwin` or `../../nix-darwin/minimum-for-work.nix`
4. Import home-manager with correct user configuration
5. Add to `flake.nix` darwinConfigurations

#### New Secret
1. Edit secrets: `sops secrets/default.yaml`
2. Add secret value in the editor
3. Define in module: `sops.secrets.my-secret = { };`
4. Use: `config.sops.secrets.my-secret.path`
