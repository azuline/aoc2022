{
  description = "advent of code 2022";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/nixos-unstable;
    flake-utils.url = github:numtide/flake-utils;
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system}; in rec {
        devShell = pkgs.mkShell {
          buildInputs = [
            (pkgs.buildEnv {
              name = "aoc2022-shell";
              paths = with pkgs; [
                zig
              ];
            })
          ];
          shellHook = ''
            find-up () {
              path=$(pwd)
              while [[ "$path" != "" && ! -e "$path/$1" ]]; do
                path=''${path%/*}
              done
              echo "$path"
            }

            # Isolate build stuff to this repo's directory.
            export PRESAGE_ROOT="$(find-up .root)"
            export PRESAGE_CACHE_ROOT="$(pwd)/.cache"
          '';
        };
      }
    );
}
