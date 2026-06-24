# dotfiles

management dotfiles

## Documentation

ドキュメントは `docs/reference/` (ストック: 継続参照) と `docs/plans/` (フロー: 実装計画の履歴) に分けて管理している。

### Reference (ストック)

- [SOPS Manual](docs/reference/SOPS.md) - Comprehensive guide for secrets management with SOPS
- [Oberon deploy methods](docs/reference/oberon-deploy.md) - 経路系変更・復旧時の deploy 方法 (Tailscale / on-server tmux / VNC / boot)
- [Sakura VPS + NixOS + Forgejo lessons](docs/reference/sakura-vps-nixos-lessons.md) - oberon 構築・運用で得た知見集 (deploy 戦略、復旧、cloudflared 挙動、VNC fallback など)
- [Linux builder](docs/reference/LINUX_BUILDER.md) / [bootstrap](docs/reference/linux-builder-bootstrap.md) - nix-darwin の Linux builder VM

### Plans (フロー)

- [oberon Tailscale 導入](docs/plans/oberon-tailscale-plan.md) - admin SSH を Tailscale 経路に分離 (実装済み)
- [oberon 初回セットアップ手順 (HTML)](docs/plans/oberon-setup.html) - 初回構築時の実施記録

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
復旧では別の方式を使う。詳細は [docs/reference/oberon-deploy.md](docs/reference/oberon-deploy.md)
を参照。

