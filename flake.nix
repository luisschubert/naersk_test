{
  inputs = {
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = { self, fenix, flake-utils, nixpkgs }:
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
      packages.${system}.default = rustPlatform.buildRustPackage {
        pname = "naersk_test";
        version = "0.1.0";
        src = ./.;
        cargoLock = {
          lockFile = ./Cargo.lock;
        };
        nativeBuildInputs = [
          rustPlatform.bindgenHook
          pkgs.pkg-config
          pkgs.pkgsCross.aarch64-multiplatform.stdenv.cc
          pkgs.llvmPackages.libclang
          pkgs.llvmPackages.clang
        ];
        buildInputs = [
          pkgs.pkgsCross.aarch64-multiplatform.stdenv.cc
        ];
        CARGO_BUILD_TARGET = target;
        CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER =
          "${pkgs.pkgsCross.aarch64-multiplatform.stdenv.cc}/bin/aarch64-unknown-linux-gnu-gcc";
        CC_aarch64_unknown_linux_gnu = "${pkgs.pkgsCross.aarch64-multiplatform.stdenv.cc}/bin/aarch64-unknown-linux-gnu-gcc";
        LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
        BINDGEN_CLANG_PATH = "${pkgs.llvmPackages.clang}/bin/clang";
        RUST_BACKTRACE = "full";
        RUST_LOG = "clang_sys=debug";
        LIBCLANG_NO_LIBCXX = "1";
        CARGO_PROFILE_RELEASE_BUILD_OVERRIDE_DEBUG = "true";
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
          pkgs.llvmPackages.clang
        ];
        buildInputs = [
          toolchain
          pkgs.cargo
          pkgs.rustc
        ];
        LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
        BINDGEN_CLANG_PATH = "${pkgs.llvmPackages.clang}/bin/clang";
        CC_aarch64_unknown_linux_gnu = "${pkgs.pkgsCross.aarch64-multiplatform.stdenv.cc}/bin/aarch64-unknown-linux-gnu-gcc";
        RUST_BACKTRACE = "full";
        RUST_LOG = "clang_sys=debug";
        LIBCLANG_NO_LIBCXX = "1";
        PATH = "${toolchain}/bin:${pkgs.cargo}/bin:${pkgs.rustc}/bin:" + (pkgs.lib.makeBinPath [ pkgs.pkgsCross.aarch64-multiplatform.stdenv.cc ]);
      };
    };
}