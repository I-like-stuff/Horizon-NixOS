{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
  libxcb,
  libxkbcommon,
  vulkan-loader,
  wayland,
  procps,
  xdg-utils,
}:

let
  source = lib.importJSON ./source.json;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "horizon-launcher";
  inherit (source) version;

  src = fetchurl {
    url = "https://github.com/0CYBER/horizon-free/releases/download/launcher@${finalAttrs.version}/horizon-launcher-linux-x86_64.tar.gz";
    inherit (source) hash;
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
  ];

  buildInputs = [
    (lib.getLib stdenv.cc.cc)
    libxcb
    libxkbcommon
  ];

  # Loaded with dlopen, so autoPatchelfHook can't find them in DT_NEEDED.
  runtimeDependencies = [
    vulkan-loader
    wayland
  ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  desktopItems = [
    (makeDesktopItem {
      name = "horizon-launcher";
      desktopName = "Horizon";
      genericName = "Game launcher";
      comment = "Install, prepare and play Horizon, Minecraft: Java Edition rewritten in Rust";
      exec = "horizon-launcher";
      icon = "horizon";
      categories = [ "Game" ];
      startupWMClass = "horizon-launcher";
    })
  ];

  # The binary keeps its own file name in libexec instead of wrapProgram's
  # .horizon-launcher-wrapped. Nix updates the launcher, so it must not replace
  # itself in the read-only store, and the menu entries it writes for instances
  # call the wrapper on PATH rather than a store path that garbage collection
  # would remove.
  installPhase = ''
    runHook preInstall

    install -Dm755 horizon-launcher $out/libexec/horizon-launcher/horizon-launcher
    makeWrapper $out/libexec/horizon-launcher/horizon-launcher $out/bin/horizon-launcher \
      --set HORIZON_LAUNCHER_NO_SELF_UPDATE 1 \
      --set-default HORIZON_LAUNCHER_DESKTOP_EXEC horizon-launcher \
      --suffix PATH : ${
        lib.makeBinPath [
          procps
          xdg-utils
        ]
      }

    install -Dm444 ${./assets/horizon.svg} $out/share/icons/hicolor/scalable/apps/horizon.svg
    install -Dm444 ${./assets/horizon-256.png} $out/share/icons/hicolor/256x256/apps/horizon.png

    runHook postInstall
  '';

  meta = {
    description = "Launcher for Horizon, Minecraft: Java Edition rewritten in Rust";
    longDescription = ''
      Installs, prepares, updates and plays Horizon, an unofficial rewrite of
      Minecraft: Java Edition in Rust. Horizon prepares its resources from your
      own copy of Minecraft: Java Edition.
    '';
    homepage = "https://github.com/0CYBER/horizon-free";
    changelog = "https://github.com/0CYBER/horizon-free/releases/tag/launcher@${finalAttrs.version}";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "horizon-launcher";
  };
})
