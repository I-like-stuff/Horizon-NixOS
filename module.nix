{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.horizon;
in
{
  options.programs.horizon = {
    enable = lib.mkEnableOption "the Horizon launcher, Minecraft: Java Edition rewritten in Rust";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { };
      defaultText = lib.literalMD "the `horizon-launcher` package from this flake";
      description = "The Horizon launcher package to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    # The launcher downloads game builds and Mojang's Java runtime and runs
    # them. They are ordinary Linux binaries, so nix-ld provides their loader
    # and these libraries, on top of nix-ld's own defaults.
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        # Game window and rendering (winit + wgpu)
        vulkan-loader
        libglvnd
        wayland
        libxkbcommon
        libx11
        libxcb
        libxcursor
        libxext
        libxi
        libxrandr

        # Game input and sound
        systemd
        alsa-lib

        # Mojang's Java runtime, which prepares the game's resources
        libxrender
        libxtst
        freetype
        fontconfig
      ];
    };

    hardware.graphics.enable = lib.mkDefault true;
  };
}
