{
  description = "Build env";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = { self, nixpkgs, crane, flake-utils, rust-overlay, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };

        rustVersion = "1.73.0";

        rust = pkgs.rust-bin.stable.${rustVersion}.default.override {
          extensions = [
            "rust-src" # rust-analyzer
          ];
        };

        nixLib = nixpkgs.lib;

        runtimeDeps = with pkgs; [
          # -- Xorg --
          # Yells not found
          xorg.libX11
          xorg.libXcursor
          xorg.libXi

          # Else "XKBNotFound" error
          libxkbcommon

          # -- Wayland --
          # Winit errors out with WaylandError(Connection(NoWaylandLib))
          wayland
        ];
      in
      {
        devShells.rust = pkgs.mkShell {
          LD_LIBRARY_PATH = nixLib.makeLibraryPath runtimeDeps;

          buildInputs = [ rust ];
        };
      });
}
