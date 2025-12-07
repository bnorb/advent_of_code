use std::collections::{HashMap, HashSet, LinkedList};

fn parse_input(input: &str) -> (usize, (usize, usize), HashSet<(usize, usize)>) {
    let mut start = (0, 0);
    let mut rocks = HashSet::new();

    input.lines().enumerate().for_each(|(row, line)| {
        line.chars().enumerate().for_each(|(col, c)| match c {
            'S' => start = (row, col),
            '#' => {
                rocks.insert((row, col));
            }
            _ => {}
        })
    });

    // input is square
    (input.lines().count(), start, rocks)
}

pub fn part1(input: &str) -> usize {
    let (size, start, rocks) = parse_input(input);

    let distances = find_distances(size, start, &rocks);

    // 64 steps
    distances
        .iter()
        .filter(|(_, distance)| {
            let d = **distance;
            d % 2 == 0 && d <= 64
        })
        .count()
}

pub fn part2(input: &str) -> usize {
    let (size, start, rocks) = parse_input(input);
    let distances = find_distances(size, start, &rocks);

    let step_target = 26501365;
    let half_size = (size - 1) / 2;
    let rings = (step_target - half_size) / size;
    let even_ring_count = rings % 2 == 0;

    let (odds, evens) = match even_ring_count {
        true => ((rings + 1).pow(2), rings.pow(2)),
        false => (rings.pow(2), (rings + 1).pow(2)),
    };

    let extra_corner_squares = rings;
    let cutoff_corner_squares = rings + 1;

    let mut even_fill = 0;
    let mut odd_fill = 0;
    let mut extra_corner_fill = 0;
    let mut cutoff_corner_fill = 0;

    distances.iter().for_each(|(_, distance)| {
        let d = *distance;

        match d % 2 == 0 {
            true => {
                even_fill += 1;
                if d <= half_size {
                    return;
                }

                match even_ring_count {
                    true => extra_corner_fill += 1,
                    false => cutoff_corner_fill += 1,
                }
            }
            false => {
                odd_fill += 1;
                if d <= half_size {
                    return;
                }

                match even_ring_count {
                    true => cutoff_corner_fill += 1,
                    false => extra_corner_fill += 1,
                }
            }
        }
    });

    odds * odd_fill + evens * even_fill + extra_corner_squares * extra_corner_fill
        - cutoff_corner_squares * cutoff_corner_fill
}

fn neighbors(size: usize, (row, col): (usize, usize)) -> Vec<(usize, usize)> {
    [(1, 0), (0, 1), (-1, 0), (0, -1)]
        .into_iter()
        .map(|(dr, dc)| (row as isize + dr, col as isize + dc))
        .filter(|(r, c)| *r >= 0 && *c >= 0 && *r < size as isize && *c < size as isize)
        .map(|(r, c)| (r as usize, c as usize))
        .collect()
}

fn find_distances(
    size: usize,
    start: (usize, usize),
    rocks: &HashSet<(usize, usize)>,
) -> HashMap<(usize, usize), usize> {
    let mut distances = HashMap::new();
    distances.insert(start, 0);

    let mut queue = LinkedList::new();
    queue.push_back((start, 0));

    while !queue.is_empty() {
        let (pos, distance) = queue.pop_front().unwrap();

        let valid_neightbors: Vec<(usize, usize)> = neighbors(size, pos)
            .into_iter()
            .filter(|n| !rocks.contains(n))
            .filter(|n| !distances.contains_key(n))
            .collect();

        for n in valid_neightbors {
            distances.insert(n, distance + 1);
            queue.push_back((n, distance + 1));
        }
    }

    distances
}
