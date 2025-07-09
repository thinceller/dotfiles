{ pkgs }:
[
  {
    home.packages = with pkgs; [
      age
      container
      curl
      deno
      docker
      docker-credential-helpers
      dotenvx
      ghq
      graphviz
      mactop
      nix-search-cli
      nixfmt-rfc-style
      nodejs_22
      nvfetcher
      sops
      tig
      uv
      wget
      _1password-cli
    ];
  }
]
