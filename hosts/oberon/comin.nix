{
  # comin: pull 型 GitOps。GitHub の master を 60 秒間隔でポーリングし、
  # 新しい commit を検知するとこのホスト上で nixosConfigurations.oberon を
  # ビルドして switch する。push 型 (SSH 越しの nixos-rebuild) と違い
  # SSH 切断でデプロイが中断しないため、経路系 (cloudflared/sshd/network)
  # の変更も安全に適用できる。
  services.comin = {
    enable = true;
    remotes = [
      {
        name = "origin";
        url = "https://github.com/thinceller/dotfiles.git";
        # comin のデフォルト main branch 名は "main" なので master に合わせる。
        branches.main.name = "master";
        # なお testing-oberon ブランチに push すると switch ではなく
        # test (再起動で消える一時適用) になる (comin のデフォルト挙動)。
      }
    ];
  };
}
