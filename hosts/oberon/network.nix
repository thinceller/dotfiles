{ config, ... }:
let
  # ============================================================
  # Static network configuration for oberon (Sakura VPS)
  # ------------------------------------------------------------
  # Sakura VPS は DHCP / cloud-init datasource を提供していないので、
  # IP / gateway / DNS を OS 側で静的に持たせる必要がある。
  # ただし origin IP は cloudflared で隠蔽している前提なので、
  # public repo に平文で置かないよう sops で暗号化する。
  #
  # 値は secrets/oberon-network.yaml に格納し、boot 時に sops-nix が復号、
  # sops.templates が systemd-networkd 用の .network ファイルを生成して
  # /etc/systemd/network/10-oberon.network に symlink する。
  #
  # 将来別 VPS を追加する場合は:
  #   1. secrets/<host>-network.yaml に同じ key 構成で値を入れて sops 暗号化
  #   2. このファイルをコピーして sopsFile / template path / hostname を置換
  #   3. .sops.yaml に該当ホストの age 鍵を recipient として登録
  # ============================================================
  netSecrets = ../../secrets/oberon-network.yaml;
in
{
  sops.secrets.ipv4_address = {
    sopsFile = netSecrets;
  };
  sops.secrets.ipv4_prefix = {
    sopsFile = netSecrets;
  };
  sops.secrets.ipv4_gateway = {
    sopsFile = netSecrets;
  };
  sops.secrets.ipv6_address = {
    sopsFile = netSecrets;
  };
  sops.secrets.ipv6_prefix = {
    sopsFile = netSecrets;
  };
  sops.secrets.dns_v4_1 = {
    sopsFile = netSecrets;
  };
  sops.secrets.dns_v4_2 = {
    sopsFile = netSecrets;
  };
  sops.secrets.dns_v6 = {
    sopsFile = netSecrets;
  };

  # systemd-networkd 用の .network ファイルを sops の placeholder で組み立てる。
  # placeholder は build 時はリテラル文字列のまま store に入り、boot 時に
  # sops-install-secrets が secrets を復号して /run/secrets-rendered/<name>
  # 内の最終ファイルへ差し替える仕組み。
  #
  # 非機密値 (interface 名 ens3、IPv6 リンクローカル GW fe80::1) は
  # Sakura VPS 標準なので nix 上に直書きする。
  sops.templates."10-oberon.network" = {
    content = ''
      [Match]
      Name=ens3

      [Network]
      Address=${config.sops.placeholder.ipv4_address}/${config.sops.placeholder.ipv4_prefix}
      Address=${config.sops.placeholder.ipv6_address}/${config.sops.placeholder.ipv6_prefix}
      Gateway=${config.sops.placeholder.ipv4_gateway}
      Gateway=fe80::1
      DNS=${config.sops.placeholder.dns_v4_1}
      DNS=${config.sops.placeholder.dns_v4_2}
      DNS=${config.sops.placeholder.dns_v6}
    '';
    # systemd-networkd は systemd-network ユーザで動くため、
    # デフォルトの root:root 0400 だと "Permission denied" になる。
    owner = "systemd-network";
    group = "systemd-network";
    mode = "0440";
  };

  # 生成された .network を systemd-networkd が読むパスへ symlink。
  environment.etc."systemd/network/10-oberon.network".source =
    config.sops.templates."10-oberon.network".path;
}
