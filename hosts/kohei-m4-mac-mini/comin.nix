{
  # comin: pull 型 GitOps (oberon の hosts/oberon/comin.nix と同じ)。root の launchd
  # daemon が master を polling し、このホスト上でビルドして activate する。
  # 運用と注意点は docs/reference/mac-mini-deploy.md。
  services.comin = {
    enable = true;
    remotes = [
      {
        name = "origin";
        url = "https://github.com/thinceller/dotfiles.git";
        # comin のデフォルト main branch 名は "main" なので master に合わせる。
        branches.main.name = "master";
      }
    ];
  };
}
