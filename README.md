# naersk test

simple example of using fenix and naersk to cross compile a rust binary from x86 to aarch64.

run `nix build` to generate the binary

run `nix develop` to get into a dev shell

```
.
├── Cargo.lock
├── Cargo.toml
├── flake.lock
├── flake.nix
├── result -> /nix/store/9bhnl39q77yjzbmpj8lqsandbk6dw48n-naersk_test-0.1.0
└── src
    └── main.rs

/nix/store/9bhnl39q77yjzbmpj8lqsandbk6dw48n-naersk_test-0.1.0
└── bin
    └── naersk_test
```