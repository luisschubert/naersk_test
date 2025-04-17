use std::env;
use std::path::PathBuf;

fn main() {
    // Compile C library
    cc::Build::new()
        .file("csrc/mylib.c")
        .flag("-O2") // Optional: optimization
        .target("aarch64-unknown-linux-gnu") // Match cross-compilation target
        .compile("mylib"); // Outputs libmylib.a

    // Tell Cargo to link libmylib.a
    println!("cargo:rustc-link-lib=static=mylib");
    println!("cargo:rustc-link-search=native={}/csrc", env::var("OUT_DIR").unwrap());

    // Generate bindgen bindings
    let bindings = bindgen::Builder::default()
        .header("csrc/mylib.h")
        .generate()
        .expect("Unable to generate bindings");

    // Write bindings to file
    let out_path = PathBuf::from(env::var("OUT_DIR").unwrap());
    bindings
        .write_to_file(out_path.join("bindings.rs"))
        .expect("Couldn't write bindings!");
}