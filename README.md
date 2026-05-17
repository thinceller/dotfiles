# dotfiles

management dotfiles

## Documentation

- [SOPS Manual](docs/SOPS.md) - Comprehensive guide for secrets management with SOPS
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

oberon は cloudflared tunnel 経由でのみ外部到達可能で、network / cloudflared
を触る変更は SSH 経路自身を巻き込むため deploy 方法を使い分ける必要がある。
詳しい背景は [lessons doc §6](docs/sakura-vps-nixos-lessons.md#6-nixos-deployment-戦略-switch-vs-boot)
と [§15](docs/sakura-vps-nixos-lessons.md#15-on-server-deploy-workflow-経路系の変更用) を参照。

#### 方式 A: Mac から `--target-host` (アプリ層の変更用)

forgejo / postgres / アプリケーションの変更で経路サービス (cloudflared, sshd) を
restart しないなら最も速い。

```bash
$ nixos-rebuild switch \
    --flake .#oberon \
    --target-host oberon \
    --build-host oberon \
    --sudo --ask-sudo-password
```

`--ask-sudo-password` はローカルで oberon の sudo password を聞くオプション
(`wheelNeedsPassword = true` 環境では必須)。oberon は `wheelNeedsPassword = false`
にしているので不要だが、互換のため付けても害は無い。

#### 方式 B: on-server で tmux (経路系の変更用、推奨)

cloudflared / sshd / firewall / network を触る場合。SSH 切断 → SIGHUP で
nixos-rebuild が中断する事故を避けるため、必ず tmux 内で実行する。

```bash
$ git push origin master
$ ssh oberon
$ tmux new -s deploy
$ cd ~/.dotfiles && git pull && sudo nixos-rebuild switch --flake .#oberon
# SSH 切れても tmux session 内のプロセスは生存。再接続: tmux attach -t deploy
```

#### 方式 C: VNC コンソール (最終手段・最も確実)

Sakura パネルから VNC コンソールを開いて thinceller で login (password は
1Password 参照、[lessons doc §14](docs/sakura-vps-nixos-lessons.md#14-vnc-fallback-とユーザー-password-の-declarative-管理))。
SSH を一切介在させないので、cloudflared が落ちようが何が起きても deploy が
中断しない。Mac から SSH が完全に到達不能になった場合の復旧経路でもある。

```bash
# VNC コンソール内で
$ cd ~/.dotfiles && git pull && sudo nixos-rebuild switch --flake .#oberon
```

#### 方式 D: `boot` + reboot (network 切替時の atomic 適用)

network 系の大きな変更で安全側に倒したい場合。`boot` は activation せず
次回 boot エントリを更新するだけなので在線への影響無し。

```bash
$ nixos-rebuild boot \
    --flake .#oberon \
    --target-host oberon \
    --build-host oberon \
    --sudo --ask-sudo-password
$ ssh oberon sudo reboot
```

#### deploy 方式の選び分け

| 変更内容 | 推奨方式 |
|---|---|
| forgejo / postgres / アプリ層 | A (Mac --target-host) |
| cloudflared / sshd / firewall | B (on-server tmux) または C (VNC) |
| network (interface, gateway, DNS) | D (boot + reboot) または C (VNC) |
| 初回 deploy / 完全復旧 | nixos-anywhere or C (VNC で nixos-rebuild) |

