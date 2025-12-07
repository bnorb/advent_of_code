mod game;

use regex::Regex;

use self::game::{Balls, Game};

fn get_color(re: &Regex, part: &str) -> u8 {
    re.captures(part)
        .map(|cap| cap.get(1).unwrap().as_str())
        .or(Some("0"))
        .unwrap()
        .parse::<u8>()
        .unwrap()
}

fn parse_input(input: &str) -> Vec<Game> {
    let game_re = Regex::new(r"^Game (\d+):").unwrap();
    let red = Regex::new(r"(\d+) red").unwrap();
    let green = Regex::new(r"(\d+) green").unwrap();
    let blue = Regex::new(r"(\d+) blue").unwrap();

    input
        .lines()
        .map(|line| {
            let id = game_re
                .captures(line)
                .unwrap()
                .get(1)
                .unwrap()
                .as_str()
                .parse::<u8>()
                .unwrap();

            let rev: Vec<Balls> = line
                .split(";")
                .map(|part| {
                    (
                        get_color(&red, part),
                        get_color(&green, part),
                        get_color(&blue, part),
                    )
                })
                .collect();

            Game::new(id, rev)
        })
        .collect()
}

pub fn part1(input: &str) -> u32 {
    let games = parse_input(input);
    let max = (12, 13, 14);

    games.iter().fold(0, |mut sum, game| {
        if game.is_possible(max) {
            sum += game.id() as u32
        }

        sum
    })
}

pub fn part2(input: &str) -> u32 {
    let games = parse_input(input);
    games.iter().fold(0, |sum, game| {
        let min = game.min_possible();
        sum + (min.0 as u32 * min.1 as u32 * min.2 as u32)
    })
}
