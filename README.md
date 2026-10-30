# Horizon NixOS Flake

A NixOS flake that packages the [Horizon](https://playhorizon.dev) launcher natively, with no FHS sandbox. Horizon is Minecraft: Java Edition 26.3 rewritten in Rust ([source](https://github.com/horizon-rust/horizon)).

Horizon is an unofficial fan project. It is not affiliated with, endorsed by or connected to Mojang Studios or Microsoft. It contains none of Minecraft's code, textures or sounds. The launcher builds them from your own copy of Minecraft: Java Edition, so you need to own the game.

## Quick Start

Add this flake as an input to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    horizon = {
      url = "github:forge-sa/horizon-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

Then import the module in your NixOS configuration and enable it:

```nix
{ inputs, ... }:
{
  imports = [ inputs.horizon.nixosModules.default ];

  programs.horizon.enable = true;
}
```

Pass `inputs` to your modules with `specialArgs = { inherit inputs; };` in `nixpkgs.lib.nixosSystem`. Rebuild, then start **Horizon** from your app menu or run `horizon-launcher`. You may need to log out and back in once so that the `NIX_LD` variables reach your desktop session.

### What the Module Does

| Setting | Why |
| --- | --- |
| Installs `horizon-launcher` | The launcher, patched to run natively on NixOS |
| `programs.nix-ld.enable = true` | The launcher downloads game builds and Mojang's Java runtime. These are ordinary Linux binaries, and nix-ld lets them run on NixOS. The launcher itself suggests this setting. |
| Adds to `programs.nix-ld.libraries` | Vulkan, EGL, Wayland, X11, xkbcommon, udev and ALSA for the game, plus the X11, freetype and fontconfig libraries Java needs. Nix-ld's default libraries are kept. |
| `hardware.graphics.enable = mkDefault true` | GPU drivers for Vulkan and OpenGL |

To use a different build of the package, set `programs.horizon.package`.

### Without the Module

The package works on its own too, for example with Home Manager or `nix profile`. On NixOS, downloaded game versions then only start if you enable `programs.nix-ld` yourself with the libraries listed in [`module.nix`](module.nix).

```nix
home.packages = [ inputs.horizon.packages.${pkgs.stdenv.hostPlatform.system}.default ];
```

```bash
nix profile add github:forge-sa/horizon-nixos
nix run github:forge-sa/horizon-nixos
```

An overlay is available as `inputs.horizon.overlays.default`. It provides `pkgs.horizon-launcher`.

## How It Works

- **Native package.** `autoPatchelfHook` points the launcher at Nix's glibc and libraries. Vulkan and Wayland, which it loads at runtime, are added to its library search path (`RUNPATH`). Nothing is sandboxed.
- **Updates come from Nix.** The launcher's self-update is turned off (`HORIZON_LAUNCHER_NO_SELF_UPDATE=1`) because it can't replace itself in the read-only Nix store. To get a newer launcher, run `nix flake update horizon` and rebuild. Game versions are a separate matter: the launcher installs and updates them in your home folder, as it does on any other distribution.
- **Desktop integration.** The package installs a `horizon-launcher.desktop` entry and the Horizon icon. Menu entries that the launcher creates for instances call `horizon-launcher` from your `PATH`, so they keep working after updates and garbage collection.

## Notes

- **Sound** goes through ALSA. NixOS's PipeWire and PulseAudio modules route ALSA automatically.
- **Old game versions** that prepare with Python need `python3` installed.
- Only `x86_64-linux` is supported, because upstream ships no other Linux builds.

## Development

```bash
nix build          # build the package into ./result
nix run            # run the launcher
nix fmt            # format the Nix files
.github/update.sh  # bump source.json to the newest launcher release (needs curl, jq, nix)
```

`source.json` holds the launcher version and hash. `package.nix` holds the package and `module.nix` the NixOS module. `assets/` holds the Horizon icon, taken from the launcher.

## Automated Maintenance

`.github/workflows/update.yml` runs every 6 hours and can also be started by hand. It looks for a new `launcher@X.Y.Z` release, updates `source.json`, builds the package and commits the change only if the build succeeds. For the commit to go through, set **Settings → Actions → General → Workflow permissions** to *Read and write* on GitHub.

## License

The Nix packaging in this repository is MIT licensed, the same as Horizon.
