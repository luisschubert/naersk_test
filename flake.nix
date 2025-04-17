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
          nativeBuildInputs = [
            pkgs.clang
            pkgs.llvmPackages.libclang # For bindgen
            pkgs.pkg-config
          ];
          buildInputs = [
            pkgs.pkgsCross.aarch64-multiplatform.stdenv.cc
          ];
          LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib"; # For bindgen
          doCheck = false; # Skip tests to avoid dependency issues
        };
      devShells.${system}.default = pkgs.mkShell {
        shellHook = ''
          export PS1="(naersk_test shell) $PS1"
        '';
        buildInputs = [
          toolchain
          pkgs.clang
          pkgs.llvmPackages.libclang
          pkgs.pkg-config
          pkgs.pkgsCross.aarch64-multiplatform.stdenv.cc
        ];
        LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
        PATH = "${toolchain}/bin:" + (pkgs.lib.makeBinPath [ pkgs.clang pkgs.pkgsCross.aarch64-multiplatform.stdenv.cc ]);
      };
    };
}