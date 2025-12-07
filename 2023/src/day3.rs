use std::collections::HashMap;

use regex::Regex;

use self::part_number::PartNumber;

mod part_number;

fn parse_input(input: &str) -> (Vec<PartNumber>, Vec<Vec<char>>) {
    let re = Regex::new(r"\d+").unwrap();

    let numbers = input
        .lines()
        .enumerate()
        .flat_map(|(row, line)| {
            re.find_iter(line)
                .map(|mtch| {
                    PartNumber::new(
                        mtch.as_str().parse::<u32>().unwrap(),
                        row,
                        mtch.start(),
                        mtch.end(),
                    )
                })
                .collect::<Vec<PartNumber>>()
        })
        .collect();

    let map = input.lines().map(|line| line.chars().collect()).collect();

    (numbers, map)
}

pub fn part1(input: &str) -> u32 {
    let (parts, map) = parse_input(input);

    parts
        .iter()
        .filter(|num| num.is_valid(&map))
        .fold(0, |sum, num| sum + num.value())
}

pub fn part2(input: &str) -> u32 {
    let (parts, map) = parse_input(input);

    let mut gear_map = HashMap::new();

    parts
        .iter()
        .map(|num| (num, num.get_gears(&map)))
        .filter(|(_, gears)| gears.len() > 0)
        .for_each(|(num, gears)| {
            gears.into_iter().for_each(|gear| {
                if !gear_map.contains_key(&gear) {
                    gear_map.insert(gear, vec![num]);
                } else {
                    gear_map.get_mut(&gear).unwrap().push(num);
                }
            });
        });

    gear_map
        .into_iter()
        .filter(|(_, numbers)| numbers.len() == 2)
        .map(|(_, numbers)| numbers.get(0).unwrap().value() * numbers.get(1).unwrap().value())
        .reduce(|sum, curr| sum + curr)
        .unwrap()
}
