mod range;

use self::range::Range;

fn parse_input(input: &str) -> Vec<(Range, Range)> {
    input
        .lines()
        .map(|l| {
            let mut parts = l.split(',');
            (
                Range::parse(parts.next().unwrap()),
                Range::parse(parts.next().unwrap()),
            )
        })
        .collect()
}

pub fn part1(input: &str) -> usize {
    let ranges = parse_input(input);

    ranges
        .iter()
        .filter(|(first_range, second_range)| {
            first_range.contains(second_range) || second_range.contains(first_range)
        })
        .count()
}

pub fn part2(input: &str) -> usize {
    let ranges = parse_input(input);

    ranges
        .iter()
        .filter(|(first_range, second_range)| first_range.overlaps(second_range))
        .count()
}
