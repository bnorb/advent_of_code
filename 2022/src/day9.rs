mod rope;

use self::rope::{Direction, Move, Point, Rope};

fn parse_input(input: &str) -> Vec<Move> {
    input
        .lines()
        .map(|line| (Direction::parse(&line[0..1]), line[2..].parse().unwrap()))
        .collect()
}

pub fn part1(input: &str) -> usize {
    let motions = parse_input(input);

    let mut rope = Rope::new(vec![Point::new(0, 0); 2]);
    motions.iter().for_each(|mv| rope.make_move(mv));
    rope.get_tail_history_count()
}

pub fn part2(input: &str) -> usize {
    let motions = parse_input(input);

    let mut rope = Rope::new(vec![Point::new(0, 0); 10]);
    motions.iter().for_each(|mv| rope.make_move(mv));
    rope.get_tail_history_count()
}
