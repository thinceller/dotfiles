# dotfiles

management dotfiles

## Documentation

- [SOPS Manual](docs/SOPS.md) - Comprehensive guide for secrets management with SOPS
- [Oberon deploy methods](docs/oberon-deploy.md) - 経路系変更・復旧時の deploy 方法 (on-server tmux / VNC / boot)
- [Sakura VPS + NixOS + Forgejo lessons](docs/sakura-vps-nixos-lessons.md) - oberon 構築・運用で得た知見集 (deploy 戦略、復旧、cloudflared 挙動、VNC fallback など)

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

通常運用 (アプリ層変更) は Mac から `--target-host` で deploy する:

```bash
$ nixos-rebuild switch \
    --flake .#oberon \
    --target-host oberon \
    --build-host oberon \
    --sudo --ask-sudo-password
```

cloudflared / sshd / firewall / network 等の経路系を触る変更や、SSH 不通時の
復旧では別の方式を使う。詳細は [docs/oberon-deploy.md](docs/oberon-deploy.md)
を参照。

