// Include generated bindings
include!(concat!(env!("OUT_DIR"), "/bindings.rs"));

// Original my_add for comparison
fn my_add(a: i32, b: i32) -> i32 {
    a + b
}

// Call C function (marked unsafe due to FFI)
extern "C" {
    fn c_add(a: i32, b: i32) -> i32;
}

fn main() {
    let a = 3;
    let b = 4;
    println!("Rust my_add({}, {}): {}", a, b, my_add(a, b));
    unsafe {
        println!("C c_add({}, {}): {}", a, b, c_add(a, b));
    }
}