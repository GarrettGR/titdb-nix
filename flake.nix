{
  description = "Trackpad Is Too Damn Big - Virtual Trackpad Resizer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};

        trackpad-is-too-damn-big = pkgs.callPackage ./trackpad-is-too-damn-big.nix {};
      in {
        packages = {
          default = trackpad-is-too-damn-big;
          trackpad-is-too-damn-big = trackpad-is-too-damn-big;
        };

        devShells.default = pkgs.mkShell {
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

        checks = {
          build = trackpad-is-too-damn-big;
        };
      }
    )
    // {
      nixosModules.default = import ./titdb-module.nix;
      nixosModules.titdb = import ./titdb-module.nix;

      overlays.default = final: prev: {
        trackpad-is-too-damn-big = final.callPackage ./trackpad-is-too-damn-big.nix {};
      };
    };
}
