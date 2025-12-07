use std::collections::HashMap;

use regex::Regex;

pub fn part1(input: &str) -> i32 {
    let re = Regex::new(r"^\D*(\d).*?(\d)?\D*$").unwrap();

    input
        .lines()
        .map(|line| {
            let cap = re.captures(line).unwrap();
            let mut num: String = cap.get(1).unwrap().as_str().to_owned();

            if let Some(second) = cap.get(2) {
                num.push_str(second.as_str())
            } else {
                num.push_str(cap.get(1).unwrap().as_str())
            }

            num.parse::<i32>().unwrap()
        })
        .reduce(|sum, current| sum + current)
        .unwrap()
}

pub fn part2(input: &str) -> i32 {
    let re_first = Regex::new(r"^.*?(\d|one|two|three|four|five|six|seven|eight|nine)").unwrap();
    let re_last = Regex::new(r".*(\d|one|two|three|four|five|six|seven|eight|nine)").unwrap();
    let m = HashMap::from([
        ("one", 1),
        ("two", 2),
        ("three", 3),
        ("four", 4),
        ("five", 5),
        ("six", 6),
        ("seven", 7),
        ("eight", 8),
        ("nine", 9),
    ]);

    input
        .lines()
        .map(|line| {
            let first_digit = re_first.captures(line).unwrap().get(1).unwrap().as_str();
            let second_digit = re_last.captures(line).unwrap().get(1).unwrap().as_str();

            let mut num = 10
                * if let Some(mapped) = m.get(first_digit) {
                    *mapped
                } else {
                    first_digit.parse::<i32>().unwrap().to_owned()
                };

            num += if let Some(mapped) = m.get(second_digit) {
                *mapped
            } else {
                second_digit.parse::<i32>().unwrap().to_owned()
            };

            num
        })
        .reduce(|sum, current| sum + current)
        .unwrap()
}
