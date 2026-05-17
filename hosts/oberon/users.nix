{
  config,
  userConfig,
  ...
}:
let
  secretName = "${userConfig.username}_hashed_password";
in
{
  # ============================================================
  # User password (VNC fallback 用)
  # ------------------------------------------------------------
  # cloudflared tunnel が落ちると SSH 経路が完全に塞がるため、Sakura パネル
  # の VNC コンソールから login できる手段が必須。SSH 公開鍵だけだと VNC で
  # は使えない (password 入力 UI なので) ので、sops 経由でホストユーザーの
  # hashed password を読み込んで `users.users.<username>.hashedPasswordFile`
  # に渡す。
  #
  # password hash 生成: `nix run nixpkgs#mkpasswd -- -m sha-512 -s`
  # 平文 password は 1Password に保管しておくこと (VNC で打ち込む用)。
  # sops の key 名は `<username>_hashed_password` で固定。
  #
  # neededForUsers = true は sops-nix の特例で、users 作成より前の
  # activation 段階で /run/secrets-for-users/<name> に展開される。これが
  # 無いと hashedPasswordFile を参照したタイミングでファイルが存在せず
  # activation が失敗する。
  # ============================================================
  sops.secrets.${secretName} = {
    sopsFile = ../../secrets/oberon.yaml;
    neededForUsers = true;
  };

  users.users.${userConfig.username}.hashedPasswordFile = config.sops.secrets.${secretName}.path;

  # users / groups を Nix 設定と厳密一致させる (完全 declarative)。
  # mutableUsers = true のままだと nixpkgs update-users-groups.pl の
  # shadow 書き込み分岐 (`!$spec->{mutableUsers}` 条件、# FIXME 付き) により
  # 既存ユーザーへの hashedPasswordFile が activation で無視される。
  # password は sops 経由でのみ管理するため false にする。
  #
  # 注意: nixos-rebuild test は使わない (Issue #161072 で credentials 永続消失)。
  # 必ず `switch` を使う。
  users.mutableUsers = false;
}
