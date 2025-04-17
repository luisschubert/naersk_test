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

```
readelf -h ./result/bin/naersk_test
ELF Header:
  Magic:   7f 45 4c 46 02 01 01 00 00 00 00 00 00 00 00 00 
  Class:                             ELF64
  Data:                              2's complement, little endian
  Version:                           1 (current)
  OS/ABI:                            UNIX - System V
  ABI Version:                       0
  Type:                              DYN (Position-Independent Executable file)
  Machine:                           AArch64
  Version:                           0x1
  Entry point address:               0x6640
  Start of program headers:          64 (bytes into file)
  Start of section headers:          442288 (bytes into file)
  Flags:                             0x0
  Size of this header:               64 (bytes)
  Size of program headers:           56 (bytes)
  Number of program headers:         10
  Size of section headers:           64 (bytes)
  Number of section headers:         32
  Section header string table index: 31
```