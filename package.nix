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

    mkdir -p $out/bin

    cat << 'EOF' > $out/bin/g3m
    #!/usr/bin/env bash
    ROGUE_FILE="$HOME/.local/share/applications/G3M.desktop"

    # Background monitor to instantly wipe out the rogue file if G3M drops it
    (
        while sleep 0.2; do
            if [ -f "$ROGUE_FILE" ]; then
                if grep -q "libexec/G3M" "$ROGUE_FILE" 2>/dev/null; then
                    rm -f "$ROGUE_FILE"
                    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
                    break
                fi
            fi
        done
    ) &
    MONITOR_PID=$!

    # Ensure monitor background process cleans up when we exit
    trap "kill $MONITOR_PID 2>/dev/null" EXIT

    # Run the actual wrapped binary
    exec ${placeholder "out"}/libexec/G3M "$@"
    EOF

    substituteInPlace $out/bin/g3m --subst-var out
    chmod +x $out/bin/g3m

    # Wrap the binary with runtime libraries and search paths
    wrapProgram $out/bin/g3m \
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
      --prefix PATH : ${lib.makeBinPath [ xdg-utils ]}

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
