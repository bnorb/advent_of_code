pub mod day1;
pub mod day2;
pub mod day3;
pub mod day4;
pub mod day5;
pub mod day6;
pub mod day7;
pub mod day8;
pub mod day9;

pub mod day10;
pub mod day11;
pub mod day12;
pub mod day13;
pub mod day14;
pub mod day15;
pub mod day16;
pub mod day17;
pub mod day18;
pub mod day19;

pub mod day20;
pub mod day21;
pub mod day22;
pub mod day23;
pub mod day24;
pub mod day25;

#[macro_export]
macro_rules! oof {
    ($day:expr, $part:expr) => {
        println!("{:?} and {:?}", stringify!($day), stringify!($part))
    };
}

#[macro_export]
macro_rules! build_runner_fn {
    ($($d:literal => $module:ident),+) => {
      $(
        use aoc2023::$module;
      )+

      fn run(day: u8, part: u8) {
        let path = format!("./input/day{}.txt", day);
        let input = std::fs::read_to_string(path).expect("could not read input file");

        match day {
            $(
              $d if part == 1 => {
                  let sol = $module::part1(&input);
                  println!("{}", sol);
              },
              $d if part == 2 => {
                  let sol = $module::part2(&input);
                  println!("{}", sol);
              },
            )+
            _ => panic!("invalid day or part")
        }
      }
    };
}
