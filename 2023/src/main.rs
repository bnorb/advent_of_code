use std::env;

use aoc2023::build_runner_fn;

fn main() {
    let args: Vec<String> = env::args().collect();
    let argc = args.len();

    if argc < 3 {
        panic!("Missing arguments");
    }

    let day: u8 = args[1].parse().expect("day is not a u8 number");
    let part: u8 = args[2].parse().expect("part is not a u8 number");

    if day < 1 || day > 25 {
        panic!("day must be between 1 and 25")
    }

    if part != 1 && part != 2 {
        panic!("part must be 1 or 2")
    }

    if part == 2 && day == 25 {
        panic!("day 25 only has 1 part")
    }

    build_runner_fn!(
        1 => day1,
        2 => day2,
        3 => day3,
        4 => day4,
        5 => day5,
        6 => day6,
        7 => day7,
        8 => day8,
        9 => day9,
        10 => day10,
        11 => day11,
        12 => day12,
        13 => day13,
        14 => day14,
        15 => day15,
        16 => day16,
        17 => day17,
        18 => day18,
        19 => day19,
        20 => day20,
        21 => day21,
        22 => day22,
        23 => day23,
        24 => day24,
        25 => day25
    );

    run(day, part);
}
