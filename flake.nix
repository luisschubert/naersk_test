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
      system = "x86_64-linux";
      target = "aarch64-unknown-linux-gnu";
      pkgs = import nixpkgs {
        inherit system;
        crossSystem = {
          config = target;
        };
      };
      toolchain = with fenix.packages.${system}; combine [
        complete.cargo
        complete.rustc
        targets.${target}.latest.rust-std
      ];
      rustPlatform = pkgs.makeRustPlatform {
        cargo = toolchain;
        rustc = toolchain;
      };
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
          BINDGEN_EXTRA_CLANG_ARGS_aarch64_unknown_linux_gnu = "--target=aarch64-unknown-linux-gnu";
          # CARGO_BUILD_RUSTFLAGS = "--target ${target}";
          nativeBuildInputs = [
            rustPlatform.bindgenHook
            pkgs.pkg-config
            pkgs.pkgsCross.aarch64-multiplatform.stdenv.cc
          ];
          buildInputs = [
            pkgs.pkgsCross.aarch64-multiplatform.stdenv.cc
          ];
          LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
          doCheck = false;
        };
      devShells.${system}.default = pkgs.mkShell {
        shellHook = ''
          export PS1="(naersk_test shell) $PS1"
        '';
        nativeBuildInputs = [
          rustPlatform.bindgenHook
          pkgs.pkg-config
          pkgs.pkgsCross.aarch64-multiplatform.stdenv.cc
        ];
        buildInputs = [
          toolchain
          pkgs.cargo
          pkgs.rustc
        ];
        LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
        PATH = "${toolchain}/bin:${pkgs.cargo}/bin:${pkgs.rustc}/bin:" + (pkgs.lib.makeBinPath [ pkgs.pkgsCross.aarch64-multiplatform.stdenv.cc ]);
        CARGO_BUILD_RUSTFLAGS = "--target ${target}";
      };
    };
}