# g3m-flake

G3M — Mod Manager for GameMaker games (Deltarune, Pizza Tower, ...) — packaged
from the official upstream GitHub release.

- Upstream: https://github.com/y114git/G3M
- Source: `https://github.com/y114git/G3M/releases/download/<ver>/G3M-Linux-x86_64-<ver>.zip`
- Binary: `g3m` (static PyInstaller build + PyQt6 runtime, wrapped for NixOS)
- Menu integration: ships its own `g3m.desktop` and SVG icon — no manual
  `~/.local/share/applications` hacking needed, it shows up in the app
  menu by just installing the package
- Platform: `x86_64-linux`

## Try it

```bash
nix run github:Matko802/g3m-flake
```

## Use in your NixOS flake

```nix
# flake.nix inputs
g3m-flake = {
  url = "github:Matko802/g3m-flake";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

```nix
# overlay
nixpkgs.overlays = [ inputs.g3m-flake.overlays.default ];
```

```nix
users.users."you".packages = with pkgs; [
  g3m
];
```

Then rebuild — G3M appears in the start menu / app launcher automatically,
because the Nix package installs `share/applications/g3m.desktop` and the
icon into the system profile (no `.local/share/applications` files needed).

## Update to a newer release

```bash
./update.sh <version>
```

The script fetches the release zip for the given version, prefetches the
hash, and rewrites `version` and both hashes in `package.nix`.
