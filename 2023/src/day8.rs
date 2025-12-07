use std::collections::HashMap;

use itertools::Itertools;
use regex::Regex;

fn parse_input(input: &str) -> (Vec<char>, HashMap<String, (String, String)>) {
    let re = Regex::new(r"^([A-Z]{3}) = \(([A-Z]{3}), ([A-Z]{3})\)$").unwrap();

    let (steps, nodes): (&str, &str) = input.split("\n\n").collect_tuple().unwrap();

    let map: HashMap<String, (String, String)> = nodes
        .lines()
        .map(|line| {
            let cap = re.captures(line).unwrap();
            (
                cap.get(1).unwrap().as_str().to_owned(),
                (
                    cap.get(2).unwrap().as_str().to_owned(),
                    cap.get(3).unwrap().as_str().to_owned(),
                ),
            )
        })
        .collect();

    (steps.chars().collect(), map)
}

fn count_steps(
    start: &str,
    zzz: bool,
    steps: &Vec<char>,
    map: &HashMap<String, (String, String)>,
) -> u64 {
    let mut current = map.get(start).unwrap();

    let mut count = 0;
    for step in steps.iter().cycle() {
        count += 1;
        let next = match step {
            'L' => &current.0,
            _ => &current.1,
        };

        if zzz {
            if next == "ZZZ" {
                break;
            }
        } else {
            if next.ends_with('Z') {
                break;
            }
        }

        current = map.get(next).unwrap();
    }

    count
}

fn gcd(a_start: u64, b_start: u64) -> u64 {
    let mut a = a_start;
    let mut b = b_start;

    // recursive algo runs out of stack on default rust config
    loop {
        if a == b {
            return a;
        }

        if a > b {
            a = a - b;
            continue;
        }

        b = b - a;
    }
}

fn lcm(a: u64, b: u64) -> u64 {
    a * b / gcd(a, b)
}

pub fn part1(input: &str) -> u64 {
    let (steps, map) = parse_input(input);
    count_steps("AAA", true, &steps, &map)
}

pub fn part2(input: &str) -> u64 {
    let (steps, map) = parse_input(input);

    let starts = map
        .iter()
        .filter(|(point, _)| point.ends_with('A'))
        .map(|(point, _)| point.to_owned())
        .collect::<Vec<String>>();

    starts
        .iter()
        .map(|start| count_steps(start, false, &steps, &map))
        .unique()
        .reduce(|ans, count| lcm(ans, count))
        .unwrap()
}
