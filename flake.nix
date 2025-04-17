{
  inputs = {
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    naersk = {
      url = "github:nix-community/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = { self, fenix, flake-utils, naersk, nixpkgs }:
    let
      system = "x86_64-linux"; # Host system
      target = "aarch64-unknown-linux-gnu";
      pkgs = import nixpkgs {
        inherit system;
        crossSystem = {
          config = target;
        };
      };
      toolchain = with fenix.packages.${system}; combine [
        minimal.cargo
        minimal.rustc
        targets.${target}.latest.rust-std
      ];
    in
    {
      packages.${system}.default =
        (naersk.lib.${system}.override {
          cargo = toolchain;
          rustc = toolchain;
        }).buildPackage {
          src = ./.;
          CARGO_BUILD_TARGET = target;
          CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER =
            "${pkgs.pkgsCross.aarch64-multiplatform.stdenv.cc}/bin/aarch64-unknown-linux-gnu-gcc";
          nativeBuildInputs = [ pkgs.clang ]; # For bindgen
          buildInputs = [ pkgs.pkgsCross.aarch64-multiplatform.stdenv.cc ]; # Cross-compiler
        };
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          toolchain
          pkgs.clang # For bindgen in dev shell
          pkgs.pkgsCross.aarch64-multiplatform.stdenv.cc # Cross-compiler
        ];
      };
    };
}
