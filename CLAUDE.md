# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Nix-based dotfiles repository using Nix Flakes, Nix Darwin, and Home Manager to manage macOS system and user configurations across multiple machines.

### Repository Facts (also read by the auto mode classifier)

- The repository (github.com/thinceller/dotfiles) is **public**: only this repo's own work belongs in commits and pushes here.
- Merging to `master` auto-deploys the NixOS server `oberon` via comin (pull-based GitOps, ~60s polling). Treat a merge to `master` as a production deploy.
- `secrets/*.yaml` are SOPS ciphertext — safe to read and commit. The age private key (`~/.config/sops/age/keys.txt`) must never be read or printed.
- CI (GitHub Actions) pushes build results to the Cachix cache `thinceller-dotfiles.cachix.org` using `CACHIX_AUTH_TOKEN`.
- `darwin-rebuild switch` / `nixos-rebuild switch` alter live machine state and are not routine; `nix build` / `nix eval` / `nix fmt` are.

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

kohei-m4-mac-mini と oberon は master push 時に comin が自動 deploy するので手動 switch は fallback
(`docs/reference/mac-mini-deploy.md` / `docs/reference/oberon-deploy.md`)。

### Dependency update PRs

`.github/workflows/update.yml` が対象 (flake input / nvfetcher source) ごとに固定ブランチ
`update/<target>` で PR を作り、毎日 / 手動起動で更新し続ける。CI 通過後は人が
merge し、comin が deploy する。特定対象だけ更新したいときは
`gh workflow run update.yml -f target=<name>`。

更新を恒久的に拒否したい input は `flake.nix` で commit / tag 固定し、`update.yml` の
`pinned` リストにも追加する (差分ゼロで job を無駄に消費しないため)。pin を外したらリストからも消す。

bot の PR ブランチへ手で commit しても次回実行で上書きされる。手直しが必要なら PR を close して
自分のブランチで行う。

必要な設定: repository variable `DEPS_UPDATE_APP_ID`、secret `DEPS_UPDATE_APP_PRIVATE_KEY`
(GitHub App、Contents / Pull requests の write)。設計は
`docs/plans/2026-09-06-flake-update-pr-automation-design.md` を参照。

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

See `docs/reference/SOPS.md` for comprehensive secrets management documentation.

See `docs/reference/SECURE_ENCLAVE_SSH.md` for the Secure Enclave SSH key used for github.com on personal Macs (manual setup, not managed by Nix).

### Verification (for coding agents)
```bash
# Build configuration without applying (use for verification)
nix build .#darwinConfigurations.kohei-m4-mac-mini.system --no-link
nix build .#darwinConfigurations.SC-N-843.system --no-link

# Format check
nix fmt
```

**Important**: When creating new files, you must stage them with `git add` before running `nix build`, as Nix Flakes only sees files tracked by git.

### Verification on Claude Code on the web (cloud sessions)

Cloud sessions run on x86_64-linux, so darwin configurations cannot be **built** there. Use these instead:

```bash
# Evaluate darwin configurations (catches most configuration errors)
nix eval --raw .#darwinConfigurations.kohei-m4-mac-mini.system.drvPath
nix eval --raw .#darwinConfigurations.SC-N-843.system.drvPath

# oberon is x86_64-linux and can be built
nix build .#nixosConfigurations.oberon.config.system.build.toplevel --no-link

# Format check
nix fmt
```

Nix is installed automatically by the SessionStart hook (`scripts/claude-cloud-session-start.sh`) on cloud sessions. To speed up session startup, configure the cloud environment's setup script — see `docs/reference/CLAUDE_CODE_WEB.md`.

## Architecture

### Key Design Patterns

#### Claude Code Global Skills and User Memory
Global (user-level, not project-level) custom skills for Claude Code are managed under `home-manager/programs/claude-code/`:
- `skills/`: Custom skills (e.g., `playwright-cli`, `vault-capture`)
- `user-memory.md`: Global user memory for Claude Code (deployed to `~/.claude/CLAUDE.md` as a regular file copy via `deploy.nix`'s activation script, not a symlink — a nix store symlink's 1970 mtime gets treated as expired by Claude Code's retention cleanup and deleted)

Skills are symlinked into `~/.claude/` via the `skillsDir` option, making them available globally across all projects. The `playwright-cli` skill provides structured Playwright CLI (`@playwright/cli`) command documentation for browser automation via `npx`.

#### Homebrew Management
Homebrew packages are declaratively managed in `nix-darwin/modules/homebrew.nix`:
- `taps`: Third-party taps (e.g., `nikitabobko/tap`)
- `brews`: CLI tools (currently empty; CLI tools available via nixpkgs/nvfetcher are preferred, e.g. `tcmux` is managed via nvfetcher + `buildGoModule` under `home-manager/programs/tmux/`)
- `casks`: GUI applications
- `onActivation.cleanup = "uninstall"`: Automatically removes undeclared packages

### Adding New Configurations

新規パッケージ / プログラム / out-of-store symlink / host / secret の追加手順は
`nix-helper` skill (`.claude/skills/nix-helper/SKILL.md`) が持っている。
ここには skill がカバーしていないものだけを置く。

#### New Claude Code Skill
1. Create directory: `home-manager/programs/claude-code/skills/new-skill/`
2. Add `SKILL.md` with frontmatter (description, trigger patterns)
3. Optionally add `references/` directory for supplementary content

#### New CLI Tool Requiring Filesystem Access
When adding a CLI tool that writes outside the project directory (caches, daemon sockets, browser data, etc.):
1. Identify its data/cache paths (check docs or run with `fs_usage`)
2. Add the paths to `configs/.config/cage/presets.yaml` under the `claude-code` preset's `allow` list
3. A cage session restart is required for the change to take effect

## Hermes Implementation Worker

Hermes kanban から dispatch された worker プロファイルがこのリポジトリで実装するときの補足。

- ブランチ・検証・コミット・PR の手順は worker プロファイルの SOUL.md
  (`hosts/oberon/hermes-profiles/worker/SOUL.md`) が定める。
- 検証コマンドは上の「Verification on Claude Code on the web (cloud sessions)」と同じものを使う。
  worker は oberon (x86_64-linux) で動くため、darwin 構成は `nix build` ではなく
  `nix eval` で確認する。
- 新規 secret の追加など、安全に関わる変更を独自に決めない。ユーザーに確認する。
