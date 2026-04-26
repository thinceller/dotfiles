{
  pkgs,
  sources,
}:

let
  inherit (pkgs) lib rustPlatform tmuxPlugins;
  inherit (sources.tmux-agent-sidebar) pname version src;

  package = rustPlatform.buildRustPackage {
    inherit pname version src;

    cargoHash = "sha256-2vMq5kUYK7Z4JAFYgZhiEOkhgmoHAthjvIflAgU7ZCg=";
    doCheck = false;

    meta = {
      description = "tmux sidebar that monitors AI coding agents across all windows and sessions in real-time";
      homepage = "https://github.com/hiroppy/tmux-agent-sidebar";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  };
in
{
  inherit package;

  plugin = tmuxPlugins.mkTmuxPlugin {
    pluginName = pname;
    rtpFilePath = "${pname}.tmux";
    inherit version src;

    postInstall = ''
      mkdir -p $target/bin
      ln -s ${lib.getExe package} $target/bin/${pname}
    '';
  };
}
