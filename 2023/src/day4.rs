use std::collections::HashSet;

use regex::Regex;

fn parse_input(input: &str) -> Vec<(HashSet<u8>, Vec<u8>)> {
    let re = Regex::new(r"^Card\s+\d+:\s+([\d\s]+)\s\|\s+([\d\s]+)$").unwrap();

    input
        .lines()
        .map(|line| {
            let cap = re.captures(line).unwrap();
            let winning = cap.get(1).unwrap().as_str();
            let actual = cap.get(2).unwrap().as_str();

            let winning = winning
                .split_whitespace()
                .map(|num| num.parse::<u8>().unwrap())
                .collect::<HashSet<u8>>();
            let actual = actual
                .split_whitespace()
                .map(|num| num.parse::<u8>().unwrap())
                .collect::<Vec<u8>>();

            (winning, actual)
        })
        .collect()
}

pub fn part1(input: &str) -> u32 {
    let cards = parse_input(input);

    cards.iter().fold(0, |sum, (winning, actual)| {
        let mut count = 0;
        actual.iter().for_each(|num| {
            if winning.contains(num) {
                count += 1;
            }
        });

        if count == 0 {
            return sum;
        }

        sum + u32::pow(2, count - 1)
    })
}

pub fn part2(input: &str) -> u32 {
    let cards = parse_input(input);
    let mut counts = vec![1; cards.len()];

    cards
        .iter()
        .enumerate()
        .for_each(|(idx, (winning, actual))| {
            let mut count = 0;
            actual.iter().for_each(|num| {
                if winning.contains(num) {
                    count += 1;
                }
            });

            let idx_count = counts.get(idx).unwrap().to_owned();

            for i in idx + 1..idx + 1 + count {
                if let Some(elem) = counts.get_mut(i) {
                    *elem += idx_count;
                } else {
                    break;
                }
            }
        });

    counts.into_iter().reduce(|sum, c| sum + c).unwrap()
}
