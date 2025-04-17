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
          CC_aarch64_unknown_linux_gnu = "${pkgs.pkgsCross.aarch64-multiplatform.stdenv.cc}/bin/aarch64-unknown-linux-gnu-gcc";
          CLANG_PATH = "${pkgs.llvmPackages.clang}/bin/clang";
          LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
          BINDGEN_CLANG_PATH = "${pkgs.llvmPackages.clang}/bin/clang";
          RUST_BACKTRACE = "1";
          # Force clang-sys to use host libclang
          CLANG_SYS_STATIC = "1";
          nativeBuildInputs = [
            rustPlatform.bindgenHook
            pkgs.pkg-config
            pkgs.pkgsCross.aarch64-multiplatform.stdenv.cc
            pkgs.llvmPackages.libclang
          ];
          buildInputs = [
            pkgs.pkgsCross.aarch64-multiplatform.stdenv.cc
          ];
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
          pkgs.llvmPackages.libclang
        ];
        buildInputs = [
          toolchain
          pkgs.cargo
          pkgs.rustc
        ];
        LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
        CLANG_PATH = "${pkgs.llvmPackages.clang}/bin/clang";
        BINDGEN_CLANG_PATH = "${pkgs.llvmPackages.clang}/bin/clang";
        CC_aarch64_unknown_linux_gnu = "${pkgs.pkgsCross.aarch64-multiplatform.stdenv.cc}/bin/aarch64-unknown-linux-gnu-gcc";
        RUST_BACKTRACE = "1";
        CLANG_SYS_STATIC = "1";
        PATH = "${toolchain}/bin:${pkgs.cargo}/bin:${pkgs.rustc}/bin:" + (pkgs.lib.makeBinPath [ pkgs.pkgsCross.aarch64-multiplatform.stdenv.cc ]);
      };
    };
}