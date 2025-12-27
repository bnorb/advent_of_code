mod cube;
mod map;
mod quaternion;

use regex::Regex;

use self::map::{CubeMap, Instruction, Map, Tile, Turn};

fn parse_input(input: &str) -> (Map, Vec<Instruction>) {
    let mut parts = input.split("\n\n");
    let map = parts.next().unwrap().trim_end();
    let instructions = parts.next().unwrap().trim_end();

    let width = map.lines().fold(0, |max, line| max.max(line.len()));

    let map = map
        .lines()
        .map(|line| {
            format!("{:width$}", line)
                .chars()
                .map(|char| Tile::parse(char))
                .collect()
        })
        .collect();

    let re = Regex::new(r"[A-Z]").unwrap();
    let inst_nums: Vec<u8> = re
        .split(instructions)
        .filter_map(|num| num.parse().ok())
        .collect();

    let re = Regex::new(r"[0-9]+").unwrap();
    let inst_dirs: Vec<Turn> = re
        .split(format!("{instructions}S").as_str())
        .filter_map(|dir| Turn::parse(dir))
        .collect();

    (
        Map::new(map),
        inst_nums.into_iter().zip(inst_dirs).collect(),
    )
}

pub fn part1(input: &str) -> usize {
    let (map, instructions) = parse_input(input);

    let mut pos = map.find_start();
    instructions.iter().for_each(|inst| {
        pos = map.make_move(pos, inst);
    });

    1000 * (pos.0 + 1) + 4 * (pos.1 + 1) + pos.2.val()
}

pub fn part2(input: &str) -> usize {
    let (map, instructions) = parse_input(input);

    let side_len = 50;
    let mut pos = map.find_start();

    let map = CubeMap::from_map(&map, side_len);

    instructions.iter().for_each(|inst| {
        pos = map.make_move(pos, inst);
    });

    1000 * (pos.0 + 1) + 4 * (pos.1 + 1) + pos.2.val()
}
