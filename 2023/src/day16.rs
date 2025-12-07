use std::collections::{HashSet, LinkedList};

use self::tile::{Cardinal, Tile};

mod tile;

fn parse_input(input: &str) -> Vec<Vec<Tile>> {
    input
        .lines()
        .map(|row| row.chars().map(|c| Tile::new(c).unwrap()).collect())
        .collect()
}

fn is_valid(map: &Vec<Vec<Tile>>, row: isize, col: isize) -> bool {
    row >= 0 && col >= 0 && (row as usize) < map.len() && (col as usize) < map[0].len()
}

fn simulate(map: &Vec<Vec<Tile>>, start: (isize, isize), from: Cardinal) -> usize {
    let mut energized = HashSet::new();
    let mut seen = HashSet::new();
    let mut queue = LinkedList::new();

    queue.push_back((start, from));
    energized.insert(start);
    seen.insert((start, from));

    while !queue.is_empty() {
        let ((row, col), from) = queue.pop_front().unwrap();
        let tile = &map[row as usize][col as usize];
        let (next, next_2) = tile.next(from);

        let mut process_move = |next: Cardinal| {
            let (next_row, next_col) = next.move_coord(row, col);
            let from = next.opposite();

            if !is_valid(map, next_row, next_col) {
                return;
            }

            let state = ((next_row, next_col), from);
            if seen.contains(&state) {
                return;
            }

            seen.insert(state);
            energized.insert((next_row, next_col));
            queue.push_back(state);
        };

        process_move(next);
        if let Some(next_2) = next_2 {
            process_move(next_2);
        }
    }

    energized.len()
}

pub fn part1(input: &str) -> usize {
    let map = parse_input(input);

    simulate(&map, (0, 0), Cardinal::W)
}

pub fn part2(input: &str) -> usize {
    let map = parse_input(input);

    let mut max = 0;

    for r in 0..map.len() {
        let size = simulate(&map, (r as isize, 0), Cardinal::W);
        max = max.max(size);
        let size = simulate(&map, (r as isize, (map[0].len() - 1) as isize), Cardinal::E);
        max = max.max(size);
    }

    for c in 0..map[0].len() {
        let size = simulate(&map, (0, c as isize), Cardinal::N);
        max = max.max(size);
        let size = simulate(&map, ((map.len() - 1) as isize, c as isize), Cardinal::S);
        max = max.max(size);
    }

    max
}
