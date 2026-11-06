{
  description = "G3M - Mod Manager for GameMaker games (Deltarune, Pizza Tower, ...) from the official release";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        g3m = pkgs.callPackage ./package.nix { };
        default = g3m;
      });

      overlays.default = final: _prev: {
        g3m = final.callPackage ./package.nix { };
      };
    };
}
