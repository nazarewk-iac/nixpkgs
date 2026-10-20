{
  appimageTools,
  lib,
  fetchurl,
  makeDesktopItem,
  procps,
  runtimeShell,
  extraPkgs ? (_: [ ]),
}:

let
  pname = "rambox";
  version = "3.1.1";

  src = fetchurl {
    url = "https://github.com/ramboxapp/download/releases/download/v${version}/Rambox-${version}-linux-x64.AppImage";
    hash = "sha256-u/g1WDA/Tgfprykh2dcHYB2cvABp6UBJVJKS19rAyF8=";
  };

  desktopItem = makeDesktopItem {
    desktopName = "Rambox";
    name = "rambox";
    exec = "rambox %u";
    icon = "rambox";
    categories = [ "Network" ];
    mimeTypes = [ "x-scheme-handler/rambox" ];
  };

  appimageContents = appimageTools.extract {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit
    pname
    version
    src
    desktopItem
    appimageContents
    ;

  extraInstallCommands = ''
    mkdir -p $out/share/applications $out/share/icons/hicolor/256x256/apps
    install -Dm644 ${appimageContents}/usr/share/icons/hicolor/256x256/apps/rambox*.png $out/share/icons/hicolor/256x256/apps/rambox.png
    install -Dm644 ${desktopItem}/share/applications/* $out/share/applications

    # `$out/bin/rambox` is a symlink to the sandbox wrapper. Replace it with a
    # shim that exports the host path as `$APPIMAGE` and execs the real wrapper:
    # Rambox reads `$APPIMAGE` to build its deep-link handler, and the sandbox
    # hides the wrapper's own path.
    mv $out/bin/rambox $out/bin/.rambox-sandbox
    cat > $out/bin/rambox <<EOF
    #!${runtimeShell}
    export APPIMAGE="$out/bin/rambox"
    exec "$out/bin/.rambox-sandbox" "\$@"
    EOF
    chmod +x $out/bin/rambox
  '';

  extraPkgs = pkgs: [ procps ] ++ extraPkgs pkgs;

  meta = {
    description = "Workspace Simplifier - a cross-platform application organizing web services into Workspaces similar to browser profiles";
    homepage = "https://rambox.app";
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [ nazarewk ];
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
