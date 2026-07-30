# Oberon Deploy Methods

**デフォルトは comin による pull 型 GitOps** (2026-07-26 導入)。master へ push
するだけで oberon 上の comin が 60 秒間隔 polling で検知し on-server build →
自動 switch する。以下の手動方式 A〜D は fallback (network 系の大変更や
comin 自体の障害時など) として残す。

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
| forgejo / postgres / アプリ層 | **0** (comin: master へ push) | SSH 不要、60 秒 polling で自動 switch |
| cloudflared / sshd / firewall / Tailscale | **0** (comin: master へ push) | on-server local 実行なので経路系変更でも安全 |
| network (interface, gateway, DNS) | **D** (`boot` + reboot、merge 前に手動適用) | 誤設定が自動 switch されるとロックアウトの恐れがあるため comin を経由させない |
| 初回 deploy / 完全復旧 / comin 自体の障害 | nixos-anywhere または **C** (VNC で `nixos-rebuild`) | |

---

## 方式 0: comin による自動 deploy (デフォルト)

設定は [`hosts/oberon/comin.nix`](../../hosts/oberon/comin.nix)。master へ push
するだけで、手元での操作は一切不要。

- GitHub の master を 60 秒間隔で polling し、新しい commit を検知すると
  oberon 上で `nixosConfigurations.oberon` をビルドして自動 **switch** する
- switch は SSH を介さず systemd service としてローカル実行されるため、
  従来の「SSH 切断 → SIGPIPE で switch-to-configuration が死ぬ」問題
  ([lessons doc §6](sakura-vps-nixos-lessons.md#6-nixos-deployment-戦略-switch-vs-boot))
  とは無縁。cloudflared / sshd / firewall / Tailscale の変更も安全に適用される
- `testing-oberon` ブランチへの push は **test** (再起動で消える一時適用) になる

状態確認:

```bash
ssh oberon systemctl status comin
ssh oberon journalctl -u comin -f
```

**注意 1**: CI の `build-nixos` job ([`.github/workflows/build.yml`](../../.github/workflows/build.yml))
が master の eval/build を検証するが、失敗する commit を push しても comin は
その commit を単に skip するだけで気づきにくい。push 後は CI の結果を確認すること。

**注意 2**: network 設定の誤りも自動 switch されてしまう。interface / gateway /
DNS のような大きな network 変更は、master へ merge する前に方式 D
(`boot` + reboot) 等で慎重に検証するか、VNC コンソールを確保した状態で行うこと。

## 方式 A: Mac から `--target-host` (comin 導入前のデフォルト、現在は fallback)

comin 導入前のデフォルト方式。comin を使わず手動で当てたい場合の fallback として残す。

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
