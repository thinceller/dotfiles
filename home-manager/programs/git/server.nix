# oberon (サーバー) 用の git 設定。common.nix だけで完結する
# (1Password SSH 署名や Cloudflare Access include は darwin 専用のため含めない)。
{ ... }:
{
  imports = [ ./common.nix ];
}
