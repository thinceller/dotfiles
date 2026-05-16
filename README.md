# dotfiles

management dotfiles

## Documentation

- [SOPS Manual](docs/SOPS.md) - Comprehensive guide for secrets management with SOPS

## Usage

### Update dependencies

```bash
# update flake.lock and _sources by nvfetcher
$ nix run .#update
```

### Apply macOS configuration (nix-darwin)

```bash
$ sudo darwin-rebuild switch --flake .#kohei-m4-mac-mini
# or for the work machine
$ sudo darwin-rebuild switch --flake .#SC-N-843
```

### Apply NixOS server configuration (oberon)

```bash
# 通常運用: cloudflared tunnel 経由でデプロイ
$ nixos-rebuild switch \
    --flake .#oberon \
    --target-host oberon \
    --build-host oberon \
    --sudo

# 在線で activation したくない変更 (network / sshd / firewall など) は
# 次回 boot に予約する `boot` で安全に切り替える
$ nixos-rebuild boot \
    --flake .#oberon \
    --target-host oberon \
    --build-host oberon \
    --sudo
$ ssh oberon sudo reboot
```

