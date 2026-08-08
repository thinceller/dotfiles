{ pkgs, sources }:
pkgs.buildGoModule {
  pname = "tcmux";
  inherit (sources.tcmux) version src;
  vendorHash = "sha256-NqNdgsvA0xutNGqZje3KuCmW7TJ4gD5bB/OQ9MSmpNM=";
  doCheck = false;
}
