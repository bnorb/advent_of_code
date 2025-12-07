use std::{collections::HashMap, ops::Range};

enum Cardinal {
    N,
    S,
    W,
    E,
}

fn parse_input(input: &str) -> Vec<Vec<char>> {
    input.lines().map(|row| row.chars().collect()).collect()
}

fn tilt(direction: Cardinal, map: &Vec<Vec<char>>) -> Vec<Vec<char>> {
    let height = map.len();
    let width = map[0].len();

    let mut last_blocks = match direction {
        Cardinal::N => vec![-1; width],
        Cardinal::S => vec![height as isize; width],
        Cardinal::W => vec![-1; height],
        Cardinal::E => vec![width as isize; height],
    };
    let mut tilted_map = map.clone();

    let (outer, inner): (Box<dyn Iterator<Item = usize>>, Range<usize>) = match direction {
        Cardinal::N => (Box::new(0..height), 0..width),
        Cardinal::S => (Box::new((0..height).rev()), 0..width),
        Cardinal::W => (Box::new(0..width), 0..height),
        Cardinal::E => (Box::new((0..width).rev()), 0..height),
    };

    for o in outer {
        let inner = inner.clone();
        for i in inner {
            let (row_id, col_id) = match direction {
                Cardinal::N | Cardinal::S => (o, i),
                Cardinal::W | Cardinal::E => (i, o),
            };

            let (block_id, block_value) = match direction {
                Cardinal::N | Cardinal::S => (col_id, row_id),
                Cardinal::W | Cardinal::E => (row_id, col_id),
            };

            let tile = map[row_id][col_id];

            match tile {
                '#' => last_blocks[block_id] = block_value as isize,
                'O' => {
                    let modifier = match direction {
                        Cardinal::N | Cardinal::W => 1,
                        Cardinal::S | Cardinal::E => -1,
                    };

                    let open_position = (last_blocks[block_id] + modifier) as usize;
                    tilted_map[row_id][col_id] = '.';
                    match direction {
                        Cardinal::N | Cardinal::S => tilted_map[open_position][col_id] = 'O',
                        Cardinal::W | Cardinal::E => tilted_map[row_id][open_position] = 'O',
                    };
                    last_blocks[block_id] += modifier;
                }
                _ => (),
            }
        }
    }

    tilted_map
}

fn get_state(map: &Vec<Vec<char>>) -> Vec<(usize, usize)> {
    map.iter()
        .enumerate()
        .map(|(row_id, row)| {
            row.iter()
                .enumerate()
                .filter(|(_, tile)| **tile == 'O')
                .map(|(col_id, _)| (row_id, col_id))
                .collect::<Vec<(usize, usize)>>()
        })
        .flatten()
        .collect()
}

pub fn part1(input: &str) -> usize {
    let map = parse_input(input);

    let tilted_map = tilt(Cardinal::N, &map);

    tilted_map
        .iter()
        .enumerate()
        .map(|(row_id, row)| row.iter().filter(|tile| **tile == 'O').count() * (map.len() - row_id))
        .sum()
}

pub fn part2(input: &str) -> usize {
    let mut map = parse_input(input);
    let row_size = map.len();

    let total = 1000000000;
    let rep_size;
    let rep_start;
    let mut seen_states = HashMap::new();

    let mut i = 0;
    loop {
        let curr_state = get_state(&map);
        if let Some(last_i) = seen_states.get(&curr_state) {
            rep_size = i - last_i;
            rep_start = last_i;
            break;
        }

        seen_states.insert(curr_state, i);

        for dir in [Cardinal::N, Cardinal::W, Cardinal::S, Cardinal::E] {
            map = tilt(dir, &map);
        }

        i += 1;
    }

    let idx = ((total - rep_start) % rep_size) + rep_start;

    seen_states
        .iter()
        .find(|(_, i)| **i == idx)
        .unwrap()
        .0
        .iter()
        .map(|(r, _)| row_size - r)
        .sum()
}
