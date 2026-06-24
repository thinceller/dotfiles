# Oberon Deploy Methods

oberon の admin SSH は **Tailscale (WireGuard) が主経路**、cloudflared SSH ingress が
fallback。[`oberon-tailscale-plan.md`](../plans/oberon-tailscale-plan.md) を参照。
Tailscale が独立した経路として常時通っているため、cloudflared / sshd / firewall を
触る変更でも Mac 側 SSH session は切れず、`--target-host` deploy が安全に通る。
network interface を直接触る変更だけが引き続き要注意。

詳しい背景は以下を参照:

- [lessons doc §6 NixOS deployment 戦略](sakura-vps-nixos-lessons.md#6-nixos-deployment-戦略-switch-vs-boot)
- [lessons doc §15 on-server deploy workflow](sakura-vps-nixos-lessons.md#15-on-server-deploy-workflow-経路系の変更用)
- [lessons doc §12 復旧パターン](sakura-vps-nixos-lessons.md#12-復旧パターン-ブリック時の選択肢)

## 使い分けマトリクス

| 変更内容 | 推奨方式 | 備考 |
|---|---|---|
| forgejo / postgres / アプリ層 | **A** (`--target-host`) | 経路に影響なし |
| cloudflared / sshd / firewall | **A** (`--target-host`) | Tailscale 経路は cloudflared/sshd restart の影響を受けない |
| Tailscale 自体 (`hosts/oberon/tailscale.nix`) | **B** (on-server tmux, `ssh oberon-cf`) | Tailscale 経由で deploy すると自己切断する可能性 |
| network (interface, gateway, DNS) | **D** (`boot` + reboot) または **C** (VNC) | tailnet0 共々巻き込まれるため安全側に倒す |
| 初回 deploy / 完全復旧 | nixos-anywhere または **C** (VNC で `nixos-rebuild`) | |

---

## 方式 A: Mac から `--target-host` (デフォルト)

Tailscale 経路は cloudflared / sshd の restart の影響を受けないため、
ほぼ全ての変更でこの方式が使える (Tailscale 自体と network interface 変更を除く)。

```bash
nixos-rebuild switch \
    --flake .#oberon \
    --target-host oberon \
    --build-host oberon \
    --sudo --ask-sudo-password
```

`--ask-sudo-password` はローカルで oberon の sudo password を聞くオプション
(`wheelNeedsPassword = true` 環境では必須)。oberon は `wheelNeedsPassword = false`
にしているので不要だが、互換のため付けても害は無い。

## 方式 B: on-server で tmux (Tailscale / network 変更用)

Tailscale 自体や network interface 設定など、SSH 経路自身を巻き込み得る変更を行う場合。
Tailscale を触るので主経路 (`ssh oberon`) は使わず **cloudflared 経由 (`ssh oberon-cf`)** で接続し、
SSH 切断 → SIGHUP で nixos-rebuild が中断する事故を避けるため必ず tmux 内で実行する。

```bash
# Mac で変更を push
git push origin master

# oberon に SSH (Tailscale 変更時は fallback の cloudflared 経由を使う)
ssh oberon-cf      # 通常変更なら ssh oberon でも可
tmux new -s deploy
cd ~/.dotfiles && git pull && sudo nixos-rebuild switch --flake .#oberon

# SSH 切れても tmux session 内のプロセスは生存
# 再接続: tmux attach -t deploy
```

`tmux` は `nixos/modules/common.nix` の `environment.systemPackages` に含めてある。

## 方式 C: VNC コンソール (最終手段・最も確実)

Sakura パネルから VNC コンソールを開いて `thinceller` で login。password は
1Password 参照 ([lessons doc §14](sakura-vps-nixos-lessons.md#14-vnc-fallback-とユーザー-password-の-declarative-管理))。
SSH を一切介在させないので、cloudflared が落ちようが何が起きても deploy が
中断しない。Mac から SSH が完全に到達不能になった場合の **復旧経路** でもある。

```bash
# VNC コンソール内で
cd ~/.dotfiles && git pull && sudo nixos-rebuild switch --flake .#oberon
```

## 方式 D: `boot` + reboot (network 切替時の atomic 適用)

network 系の大きな変更で安全側に倒したい場合。`boot` は activation せず次回
boot エントリを更新するだけなので在線への影響無し。

```bash
nixos-rebuild boot \
    --flake .#oberon \
    --target-host oberon \
    --build-host oberon \
    --sudo --ask-sudo-password

ssh oberon sudo reboot
```

reboot 後にフレッシュに新世代が立ち上がる。

## 代替: `systemd-run` でセッション detach (tmux が無い場合)

万一 oberon の `systemPackages` から `tmux` が外れた場合 (or 別 host) の代替。
プロセスを systemd の管理下に置いて SSH session から切り離す:

```bash
ssh oberon
sudo systemd-run --collect --unit=nixos-rebuild-deploy --pty --wait \
  nixos-rebuild switch --flake /home/thinceller/.dotfiles#oberon

# SSH 切れても unit は走り続ける。再接続後に状態確認:
sudo systemctl status nixos-rebuild-deploy
sudo journalctl -u nixos-rebuild-deploy -f
```
