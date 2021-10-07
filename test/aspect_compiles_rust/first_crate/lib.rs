use crate_two;
use crate_three;

pub fn do_math(i: i32) -> i32 {
    crate_two::get_forty_three() + crate_three::get_forty_two() + i
}
