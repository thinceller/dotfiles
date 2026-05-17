{
  lib,
  pkgs,
  userConfig,
  ...
}:
let
  # ============================================================
  # Bootstrap toggle
  # ------------------------------------------------------------
  # true  (初期値): sshd を 0.0.0.0 にバインド + 22 番ポート開放。
  #               nixos-anywhere の初回 deploy 後に Mac から IP 直接 SSH 可能。
  #               age 鍵取得 / cloudflared セットアップに必要。
  # false           : sshd を 127.0.0.1 にロックダウン + firewall 全閉。
  #               cloudflared tunnel (`oberon.thinceller.dev`) 越しでのみ到達可能になる。
  #
  # 切り替えタイミング:
  #   ① nixos-anywhere 完了 (bootstrap=true) → IP 直接 SSH
  #   ② age 鍵取得 → sops で secrets/cloudflared.json 作成
  #   ③ cloudflared.nix の sops 統合を有効化
  #   ④ nixos-rebuild で再 deploy (まだ bootstrap=true)
  #   ⑤ Cloudflare ダッシュボードでトンネル HEALTHY、`ssh oberon` 到達確認
  #   ⑥ ここを false にして再 deploy → ロックダウン完成
  # ============================================================
  bootstrap = false;
in
{
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];
  };

  # NixOS のネットワーク管理は systemd-networkd に統一する。
  # Sakura VPS は DHCP 提供無しの静的 IP 構成なので、各ホストは
  # hosts/<name>/network.nix で sops.templates を使って /etc/systemd/network/
  # 以下に .network ファイルを生成する。
  networking.useNetworkd = true;
  networking.useDHCP = false;

  time.timeZone = "Asia/Tokyo";
  # defaultLocale は Hydra と同じ "en_US.UTF-8" にする。
  # ja_JP.UTF-8 にすると supportedLocales (defaultLocale から派生) が変わり、
  # glibc-locales のキャッシュキーがズレてソースビルド → 2GB RAM kexec で OOM するため。
  # サーバ用途では英語ロケールで十分。
  i18n.defaultLocale = "en_US.UTF-8";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  environment.systemPackages = with pkgs; [
    git
    vim
    htop
    # tmux: VNC / SSH 経由 deploy 時の session 切断対策 (ssh が落ちても rebuild
    # 継続できるよう、必ず tmux 内で nixos-rebuild を走らせる運用)。
    tmux
    # comma: `, <pkg> -- args` で nixpkgs パッケージを Mac と同様に ad-hoc 実行
    # する (例: `, sops -- -d secrets/oberon.yaml`)。systemPackages を汚さない。
    comma
  ];

  # sshd の到達経路は bootstrap トグルで切り替える (let 句参照)。
  # - bootstrap=true : 0.0.0.0 bind + openFirewall (22 番開放)
  # - bootstrap=false: 127.0.0.1 bind + firewall closed (cloudflared 経由のみ)
  services.openssh = {
    enable = true;
    openFirewall = bootstrap;
    listenAddresses = lib.optionals (!bootstrap) [
      {
        addr = "127.0.0.1";
        port = 22;
      }
    ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  users.users.${userConfig.username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILQwsbXl/1tHIdW/f+fZE7TJArqzvmbbaUsdKRFPoyZB thinceller@kohei-m4-mac-mini"
    ];
  };

  security.sudo.wheelNeedsPassword = false;
}
