mod stacks;

use self::stacks::{Move, Stacks};

fn parse_input(input: &str) -> (Stacks, Vec<Move>) {
    let mut parts = input.split("\n\n");
    let stacks = Stacks::parse(parts.next().unwrap());

    let moves = parts
        .next()
        .unwrap()
        .lines()
        .map(|line| Move::parse(line))
        .collect();

    (stacks, moves)
}

pub fn part1(input: &str) -> String {
    let (initial_stacks, moves) = parse_input(input);

    let mut stacks = initial_stacks.clone();
    moves.iter().for_each(|mv| stacks.make_move(mv));
    stacks.top()
}

pub fn part2(input: &str) -> String {
    let (initial_stacks, moves) = parse_input(input);

    let mut stacks = initial_stacks.clone();
    moves.iter().for_each(|mv| stacks.make_move_at_once(mv));
    stacks.top()
}
