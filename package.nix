{
  stdenv,
  unzip,
  fetchurl,
  makeWrapper,
  writeText,
  lib,
  libglvnd,
  libxcb,
  libxkbcommon,
  wayland,
  xkeyboard-config,
  xcb-util-cursor,
  libxcb-util,
  libxcb-image,
  libxcb-keysyms,
  libxcb-render-util,
  libxcb-wm,
  xdg-utils,
}:
let
  pname = "g3m";
  version = "3.4.5";

  src = fetchurl {
    url = "https://github.com/y114git/G3M/releases/download/${version}/G3M-Linux-x86_64-${version}.zip";
    hash = "sha256-mxX4qo8AJzrptWPWzt1QzxLjqRstOMsRpuuBz+q59MA=";
  };

  icon = fetchurl {
    url = "https://raw.githubusercontent.com/y114git/G3M/${version}/src/assets/icons/g3m_icon.svg";
    hash = "sha256-MgfLvzsw2//4YIKhI4EPApNnJGe9BxgLFpkhG1OYBGk=";
  };

  desktopFile = writeText "g3m.desktop" ''
    [Desktop Entry]
    Type=Application
    Name=G3M
    GenericName=GameMaker Mod Manager
    Comment=Mod Manager for GameMaker games (Deltarune, Pizza Tower, ...)
    Exec=g3m %U
    Icon=g3m
    Terminal=false
    StartupNotify=true
    StartupWMClass=G3M
    Categories=Game;
    Keywords=gamemaker;mods;modding;deltarune;pizza tower;
    MimeType=x-scheme-handler/g3m;x-scheme-handler/deltahub;
  '';
in
stdenv.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = [
    unzip
    makeWrapper
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm555 G3M $out/libexec/G3M
    install -Dm444 LICENSE $out/share/licenses/g3m/LICENSE

    install -Dm444 ${icon} $out/share/icons/hicolor/scalable/apps/g3m.svg
    install -Dm444 ${desktopFile} $out/share/applications/g3m.desktop

    # Create bin directory and xdg-desktop-menu shim to block rogue G3M.desktop creation
    mkdir -p $out/bin

    cat << 'EOF' > $out/bin/xdg-desktop-menu
    #!/usr/bin/env bash
    for arg in "$@"; do
        if [[ "$arg" == *G3M.desktop* ]]; then
            exit 0
        fi
    done
    exec ${xdg-utils}/bin/xdg-desktop-menu "$@"
    EOF
    chmod +x $out/bin/xdg-desktop-menu

    makeWrapper $out/libexec/G3M $out/bin/g3m \
      --prefix LD_LIBRARY_PATH : ${
        lib.makeLibraryPath [
          libglvnd
          libxcb
          libxkbcommon
          wayland
          xkeyboard-config
          xcb-util-cursor
          libxcb-util
          libxcb-image
          libxcb-keysyms
          libxcb-render-util
          libxcb-wm
        ]
      } \
      --set XKB_CONFIG_ROOT ${xkeyboard-config}/share/X11/xkb \
      --prefix PATH : "$out/bin:${lib.makeBinPath [ xdg-utils ]}"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Mod Manager for GameMaker games (Deltarune, Pizza Tower, ...)";
    longDescription = ''
      G3M is an open-source GUI mod manager for GameMaker games such as
      Deltarune, Pizza Tower and Undertale. It handles downloading mods,
      patching and restoring saves and game files. Packaged from the
      official upstream release (PyInstaller build) with the PyQt6 runtime
      libraries wrapped in for NixOS.
    '';
    homepage = "https://github.com/y114git/G3M";
    changelog = "https://github.com/y114git/G3M/releases/tag/${version}";
    license = licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    mainProgram = "g3m";
  };
}
