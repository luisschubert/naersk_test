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
      system = "aarch64-linux"; # Emulate aarch64 natively
      pkgs = import nixpkgs {
        inherit system;
        # No crossSystem needed since we're "natively" compiling via QEMU
      };
      toolchain = with fenix.packages.${system}; combine [
        complete.cargo
        complete.rustc
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
          pkgs.llvmPackages_18.libclang
          pkgs.llvmPackages_18.clang
        ];
        buildInputs = [
          # Add runtime dependencies if needed, e.g., pkgs.openssl
        ];
        LIBCLANG_PATH = "${pkgs.llvmPackages_18.libclang.lib}/lib";
        CLANG_PATH = "${pkgs.llvmPackages_18.clang}/bin/clang";
        BINDGEN_CLANG_PATH = "${pkgs.llvmPackages_18.clang}/bin/clang";
        RUST_BACKTRACE = "full";
        RUST_LOG = "clang_sys=debug";
        LIBCLANG_NO_LIBCXX = "1";
        CARGO_PROFILE_RELEASE_BUILD_OVERRIDE_DEBUG = "true";
        doCheck = false; # Disable tests if they cause issues
      };

      devShells.${system}.default = pkgs.mkShell {
        shellHook = ''
          export PS1="(naersk_test shell) $PS1"
        '';
        nativeBuildInputs = [
          rustPlatform.bindgenHook
          pkgs.pkg-config
          pkgs.llvmPackages_18.libclang
          pkgs.llvmPackages_18.clang
        ];
        buildInputs = [
          toolchain
          pkgs.cargo
          pkgs.rustc
        ];
        LIBCLANG_PATH = "${pkgs.llvmPackages_18.libclang.lib}/lib";
        BINDGEN_CLANG_PATH = "${pkgs.llvmPackages_18.clang}/bin/clang";
        RUST_BACKTRACE = "full";
        RUST_LOG = "clang_sys=debug";
        LIBCLANG_NO_LIBCXX = "1";
        PATH = "${toolchain}/bin:${pkgs.cargo}/bin:${pkgs.rustc}/bin:" + (pkgs.lib.makeBinPath [ pkgs.llvmPackages_18.clang ]);
      };
    };
}