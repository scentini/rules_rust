use crate_three;

pub fn add_one(i: i32) -> i32 {
    i + 1
}

pub fn get_forty_three() -> i32 {
    add_one(crate_three::get_forty_two())
}