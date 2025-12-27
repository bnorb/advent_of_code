mod snafu;

use self::snafu::Snafu;

pub fn part1(input: &str) -> Snafu {
    let snafus: Vec<Snafu> = input.lines().map(|line| Snafu::parse(line)).collect();
    snafus.into_iter().reduce(|sum, snafu| sum + snafu).unwrap()
}

pub fn part2(_input: &str) -> u8 {
    //stub
    0
}
