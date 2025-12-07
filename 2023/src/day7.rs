use itertools::Itertools;

use self::hand::Hand;

mod hand;

fn parse_input(input: &str) -> Vec<(String, u32)> {
    input
        .lines()
        .map(|line| {
            let (hand, bid): (&str, &str) = line.split(" ").collect_tuple().unwrap();
            (hand.to_owned(), bid.parse::<u32>().unwrap())
        })
        .collect()
}

pub fn part1(input: &str) -> u32 {
    let hands = parse_input(input);

    hands
        .iter()
        .map(|(cards, bid)| (Hand::new(&cards, false), bid))
        .sorted_by(|(h_a, _), (h_b, _)| h_a.cmp(h_b))
        .enumerate()
        .fold(0, |sum, (idx, (_, bid))| sum + ((idx as u32 + 1) * bid))
}

pub fn part2(input: &str) -> u32 {
    let hands = parse_input(input);

    hands
        .iter()
        .map(|(cards, bid)| (Hand::new(&cards, true), bid))
        .sorted_by(|(h_a, _), (h_b, _)| h_a.cmp(h_b))
        .enumerate()
        .fold(0, |sum, (idx, (_, bid))| sum + ((idx as u32 + 1) * bid))
}
