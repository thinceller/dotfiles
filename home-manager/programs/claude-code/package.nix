# Override edgepkgs' wrapProgram to place the binary in libexec/ instead of
# renaming it to .claude-wrapped. This preserves the process name as "claude"
# (via p_comm), which tools like tcmux rely on for session detection.
{ pkgs }:
pkgs.edge.claude-code-bin.overrideAttrs (_old: {
  installPhase = ''
    runHook preInstall

    mkdir -p $out/libexec $out/bin
    install -m755 $src $out/libexec/claude

    makeBinaryWrapper $out/libexec/claude $out/bin/claude \
      --inherit-argv0 \
      --set DISABLE_AUTOUPDATER 1 \
      --set USE_BUILTIN_RIPGREP 0 \
      --set DISABLE_INSTALLATION_CHECKS 1 \
      --prefix PATH : ${
        pkgs.lib.makeBinPath (
          with pkgs;
          [
            procps
            ripgrep
          ]
        )
      }

    runHook postInstall
  '';
})
