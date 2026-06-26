{
  description = "Trackpad Is Too Damn Big - Virtual Trackpad Resizer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
      perSystem = f: forAllSystems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = perSystem (
        pkgs:
        let
          trackpad-is-too-damn-big = pkgs.callPackage ./trackpad-is-too-damn-big.nix { };
        in
        {
          default = trackpad-is-too-damn-big;
          inherit trackpad-is-too-damn-big;
        }
      );

      devShells = perSystem (pkgs: {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [
            cmake
            pkg-config
            libevdev
            gcc
            gdb
            valgrind
          ];

          shellHook = ''
            echo "trackpad-is-too-damn-big development environment"
            echo "Available commands:"
            echo "  cmake, make, gcc, gdb, valgrind"
          '';
        };
      });

      checks = forAllSystems (system: {
        build = self.packages.${system}.default;
      });

      nixosModules.default = import ./titdb-module.nix;
      nixosModules.titdb = import ./titdb-module.nix;

      overlays.default = final: prev: {
        trackpad-is-too-damn-big = final.callPackage ./trackpad-is-too-damn-big.nix { };
      };
    };
}
