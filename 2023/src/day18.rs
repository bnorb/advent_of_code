use std::collections::{HashSet, LinkedList};

use itertools::{Itertools, MinMaxResult};

#[derive(Clone, Copy, PartialEq, Eq, Debug, Hash)]
pub enum Cardinal {
    N,
    S,
    W,
    E,
}

impl Cardinal {
    fn step(&self, row: isize, col: isize, size: isize) -> (isize, isize) {
        match self {
            Self::N => (row - size, col),
            Self::S => (row + size, col),
            Self::W => (row, col - size),
            Self::E => (row, col + size),
        }
    }
}

fn parse_input(input: &str) -> Vec<(Cardinal, u8, String)> {
    input
        .lines()
        .map(|row| {
            let (dir, count, color) = row.split(" ").collect_tuple().unwrap();
            let dir = match dir {
                "U" => Cardinal::N,
                "D" => Cardinal::S,
                "L" => Cardinal::W,
                "R" => Cardinal::E,
                _ => panic!("invalid direction"),
            };

            (dir, count.parse::<u8>().unwrap(), color.to_owned())
        })
        .collect()
}

fn flood(start: (isize, isize), hole: &mut HashSet<(isize, isize)>) {
    let mut queue = LinkedList::new();
    queue.push_back(start);

    while !queue.is_empty() {
        let (r, c) = queue.pop_front().unwrap();
        for next in [(r - 1, c), (r, c - 1), (r + 1, c), (r, c + 1)] {
            if !hole.contains(&next) {
                hole.insert(next);
                queue.push_back(next);
            }
        }
    }
}

pub fn part1(input: &str) -> usize {
    let steps = parse_input(input);

    let mut hole = HashSet::new();
    hole.insert((0, 0));

    let mut row = 0;
    let mut col = 0;
    steps.iter().for_each(|(dir, step, _)| {
        for _ in 0..*step {
            (row, col) = dir.step(row, col, 1);
            hole.insert((row, col));
        }
    });

    let rl;
    let rh;
    let cl;
    let ch;
    if let MinMaxResult::MinMax(min, max) = hole.iter().minmax_by(|(a, _), (b, _)| a.cmp(b)) {
        rl = min.0;
        rh = max.0;
    } else {
        panic!("not 2D")
    }

    if let MinMaxResult::MinMax(min, max) = hole.iter().minmax_by(|(_, a), (_, b)| a.cmp(b)) {
        cl = min.1;
        ch = max.1;
    } else {
        panic!("not 2D")
    }

    let mut inner_start = None;

    'outer: for r in rl..=rh {
        let mut out = true;
        let mut trench_count = 0;

        for c in cl..=ch {
            if hole.contains(&(r, c)) {
                out = false;
                trench_count += 1;
            } else {
                if trench_count > 1 {
                    continue 'outer;
                }

                if !out {
                    inner_start = Some((r, c));
                    break 'outer;
                }
            }
        }
    }

    flood(inner_start.unwrap(), &mut hole);

    hole.len()
}

pub fn part2(input: &str) -> isize {
    let steps = parse_input(input);

    let mut prev = (0, 0);
    let mut trench = 1;

    let mut coords: Vec<(isize, isize)> = steps
        .iter()
        .map(|(_, _, hex)| {
            let steps = isize::from_str_radix(&hex[2..7], 16).unwrap();
            let dir = match &hex[7..8] {
                "0" => Cardinal::E,
                "1" => Cardinal::S,
                "2" => Cardinal::W,
                "3" => Cardinal::N,
                _ => panic!("invalid dir"),
            };

            (steps, dir)
        })
        .inspect(|(steps, _)| trench += steps)
        .map(|(steps, dir)| {
            prev = dir.step(prev.0, prev.1, steps);
            prev
        })
        .collect();

    coords.push(*coords.first().unwrap());

    let mut area = 0;

    for i in 0..(coords.len() - 1) {
        let (r1, c1) = coords[i];
        let (r2, c2) = coords[i + 1];

        area += r1 * c2 - r2 * c1
    }

    area = (area.abs() / 2) + (trench / 2) + 1;

    area
}
