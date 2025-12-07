use std::collections::{HashMap, HashSet, LinkedList};

use itertools::Itertools;

fn parse_input(input: &str) -> ((isize, isize), Vec<Vec<char>>) {
    let mut start = (0, 0);

    let map = input
        .trim_end()
        .lines()
        .enumerate()
        .map(|(row, line)| {
            line.chars()
                .enumerate()
                .inspect(|(col, char)| {
                    if *char == 'S' {
                        start = (row as isize, *col as isize)
                    }
                })
                .map(|(_, char)| char)
                .collect()
        })
        .collect();

    (start, map)
}

pub fn part1(input: &str) -> i32 {
    let (start, map) = parse_input(input);

    let (_, counter) = find_loop(start, &map);
    (counter - 1) / 2 + 1
}


pub fn part2(input: &str) -> i32 {
    let (start, map) = parse_input(input);

    let (loop_parts, _) = find_loop(start, &map);
    let (mut zoomed_map, loop_parts) = zoom_in(&map, &loop_parts);

    zoomed_map.insert(0, vec!['#'; zoomed_map.first().unwrap().len()]);
    zoomed_map.iter_mut().for_each(|row| row.insert(0, '#'));

    let loop_parts: HashSet<(isize, isize)> = loop_parts
        .into_iter()
        .map(|(r, c)| (r + 1, c + 1))
        .collect();

    let flooded = flood(&zoomed_map, &loop_parts);
    zoomed_map.iter().enumerate().fold(0, |sum, (r_id, row)| {
        sum + row
            .iter()
            .enumerate()
            .filter(|(c_id, val)| {
                let pos = (r_id as isize, *c_id as isize);
                !flooded.contains(&pos) && !loop_parts.contains(&pos) && **val != '#'
            })
            .fold(0, |r_sum, _| r_sum + 1)
    })
}


const DIR: [(isize, isize); 4] = [(-1, 0), (0, -1), (1, 0), (0, 1)]; // N, W, S, E

fn find_connecting((row, col): (isize, isize), map: &Vec<Vec<char>>) -> Vec<(isize, isize)> {
    let curr_val = *map.get(row as usize).unwrap().get(col as usize).unwrap();
    DIR.iter()
        .map(|(r, c)| (row + *r, col + *c))
        .enumerate()
        .filter(|(_, (r, c))| {
            *r >= 0 && *c >= 0 && *r < map.len() as isize && *c < map.get(0).unwrap().len() as isize
        })
        .filter(|(dir_id, (r, c))| {
            let val = *map.get(*r as usize).unwrap().get(*c as usize).unwrap();

            match (curr_val, *dir_id) {
                ('S' | '|' | 'L' | 'J', 0) => val == '|' || val == '7' || val == 'F' || val == 'S',
                ('S' | '|' | '7' | 'F', 2) => val == '|' || val == 'L' || val == 'J' || val == 'S',
                ('S' | '-' | 'J' | '7', 1) => val == '-' || val == 'L' || val == 'F' || val == 'S',
                ('S' | '-' | 'L' | 'F', 3) => val == '-' || val == '7' || val == 'J' || val == 'S',
                _ => false,
            }
        })
        .map(|(_, v)| v)
        .collect()
}

fn find_loop(start: (isize, isize), map: &Vec<Vec<char>>) -> (HashSet<(isize, isize)>, i32) {
    let mut curr = Some(start);
    let mut counter = 0;
    let mut visited = HashSet::new();

    while let Some(pos) = curr {
        visited.insert(pos);
        counter += 1;

        curr = find_connecting(pos, map)
            .into_iter()
            .find(|v| !visited.contains(v));
    }

    (visited, counter)
}

fn find_real_s(map: &Vec<Vec<char>>, pos: (isize, isize)) -> char {
    let ord: HashMap<char, u8> =
        HashMap::from_iter("|-LJ7F".chars().enumerate().map(|(id, c)| (c, id as u8)));

    let ((mut r1, mut c1), (mut r2, mut c2)): ((isize, isize), (isize, isize)) =
        find_connecting(pos, map)
            .into_iter()
            .collect_tuple()
            .unwrap();

    let mut v1 = *map.get(r1 as usize).unwrap().get(c1 as usize).unwrap();
    let mut v2 = *map.get(r2 as usize).unwrap().get(c2 as usize).unwrap();

    if ord.get(&v1).unwrap() > ord.get(&v2).unwrap() {
        (v2, v1) = (v1, v2);
        (r2, r1) = (r1, r2);
        (c2, c1) = (c1, c2);
    }

    match (v1, v2) {
        ('|', '|') => '|',
        ('-', '-') => '-',
        ('L', 'L') => '7',
        ('J', 'J') => 'F',
        ('7', '7') => 'L',
        ('F', 'F') => 'J',

        ('|', '-') if r1 < r2 && c1 < c2 => 'L',
        ('|', '-') if r1 < r2 && c1 > c2 => 'J',
        ('|', '-') if r1 > r2 && c1 < c2 => 'F',
        ('|', '-') if r1 > r2 && c1 > c2 => '7',

        ('|', 'L') if r1 < r2 && c1 == c2 => '|',
        ('|', 'L') if r1 < r2 && c1 > c2 => 'J',
        ('|', 'L') if r1 > r2 && c1 > c2 => '7',

        ('|', 'J') if r1 < r2 && c1 == c2 => '|',
        ('|', 'J') if r1 < r2 && c1 < c2 => 'L',
        ('|', 'J') if r1 > r2 && c1 < c2 => 'F',

        ('|', '7') if r1 > r2 && c1 == c2 => '|',
        ('|', '7') if r1 > r2 && c1 < c2 => 'F',
        ('|', '7') if r1 < r2 && c1 < c2 => 'L',

        ('|', 'F') if r1 > r2 && c1 == c2 => '|',
        ('|', 'F') if r1 > r2 && c1 > c2 => '7',
        ('|', 'F') if r1 < r2 && c1 > c2 => 'J',

        ('-', 'L') if r1 < r2 && c1 < c2 => '7',
        ('-', 'L') if r1 == r2 && c1 > c2 => '-',
        ('-', 'L') if r1 < r2 && c1 > c2 => 'F',

        ('-', 'J') if r1 < r2 && c1 < c2 => '7',
        ('-', 'J') if r1 == r2 && c1 < c2 => '-',
        ('-', 'J') if r1 < r2 && c1 > c2 => 'F',

        ('-', '7') if r1 > r2 && c1 < c2 => 'J',
        ('-', '7') if r1 == r2 && c1 < c2 => '-',
        ('-', '7') if r1 > r2 && c1 > c2 => 'L',

        ('-', 'F') if r1 > r2 && c1 < c2 => 'J',
        ('-', 'F') if r1 == r2 && c1 > c2 => '-',
        ('-', 'F') if r1 > r2 && c1 > c2 => 'L',

        ('L', 'J') if r1 < r2 && c1 < c2 => '7',
        ('L', 'J') if r1 == r2 && c1 < c2 => '-',
        ('L', 'J') if r1 > r2 && c1 < c2 => 'F',

        ('L', '7') if r1 == r2 && c1 < c2 => '-',
        ('L', '7') if r1 > r2 && c1 == c2 => '|',
        ('L', '7') if r1 > r2 && c1 < c2 && r1 == pos.0 => 'J',
        ('L', '7') if r1 > r2 && c1 < c2 && r1 > pos.0 => 'F',

        ('L', 'F') if r1 > r2 && c1 < c2 => 'J',
        ('L', 'F') if r1 > r2 && c1 == c2 => '|',
        ('L', 'F') if r1 > r2 && c1 > c2 => '7',

        ('J', '7') if r1 > r2 && c1 < c2 => 'F',
        ('J', '7') if r1 > r2 && c1 == c2 => '|',
        ('J', '7') if r1 > r2 && c1 > c2 => 'L',

        ('J', 'F') if r1 == r2 && c1 > c2 => '-',
        ('J', 'F') if r1 > r2 && c1 == c2 => '|',
        ('J', 'F') if r1 > r2 && c1 > c2 && r1 == pos.0 => 'L',
        ('J', 'F') if r1 > r2 && c1 > c2 && r1 > pos.0 => '7',

        ('7', 'F') if r1 < r2 && c1 > c2 => 'J',
        ('7', 'F') if r1 == r2 && c1 > c2 => '-',
        ('7', 'F') if r1 > r2 && c1 > c2 => 'L',

        _ => {
            println!("{}, {}, {}, {}, {}, {}, {:?}", v1, v2, r1, r2, c1, c2, pos);
            panic!("can't happen")
        }
    }
}

fn zoom_in(
    map: &Vec<Vec<char>>,
    loop_parts: &HashSet<(isize, isize)>,
) -> (Vec<Vec<char>>, HashSet<(isize, isize)>) {
    let mut zoomed: Vec<Vec<char>> = vec![0; map.len() * 2]
        .into_iter()
        .map(|_| vec!['#'; map.first().unwrap().len() * 2])
        .collect();

    let mut new_loop_parts: HashSet<(isize, isize)> = HashSet::new();

    map.iter().enumerate().for_each(|(row, line)| {
        line.into_iter().enumerate().for_each(|(col, val)| {
            let pos = (row as isize, col as isize);
            *zoomed.get_mut(row * 2).unwrap().get_mut(col * 2).unwrap() = *val;

            if !loop_parts.contains(&pos) {
                return;
            }

            new_loop_parts.insert((pos.0 * 2, pos.1 * 2));

            let mut c = *val;
            if c == 'S' {
                c = find_real_s(map, pos)
            }

            let (right, down) = match c {
                '|' => ('#', '|'),
                '-' => ('-', '#'),
                'L' => ('-', '#'),
                'J' => ('#', '#'),
                '7' => ('#', '|'),
                'F' => ('-', '|'),
                _ => panic!("can't happen"),
            };

            if right != '#' {
                new_loop_parts.insert((pos.0 * 2, pos.1 * 2 + 1));
                *zoomed
                    .get_mut(row * 2)
                    .unwrap()
                    .get_mut(col * 2 + 1)
                    .unwrap() = right;
            }

            if down != '#' {
                new_loop_parts.insert((pos.0 * 2 + 1, pos.1 * 2));
                *zoomed
                    .get_mut(row * 2 + 1)
                    .unwrap()
                    .get_mut(col * 2)
                    .unwrap() = down;
            }
        });
    });

    (zoomed, new_loop_parts)
}

fn flood(map: &Vec<Vec<char>>, loop_parts: &HashSet<(isize, isize)>) -> HashSet<(isize, isize)> {
    let mut queue = LinkedList::new();
    let mut flooded = HashSet::new();

    queue.push_back((0, 0));
    while !queue.is_empty() {
        let (row, col) = queue.pop_front().unwrap();
        let next: Vec<(isize, isize)> = DIR
            .iter()
            .map(|(r, c)| (row + *r, col + *c))
            .filter(|(r, c)| {
                *r >= 0
                    && *c >= 0
                    && *r < map.len() as isize
                    && *c < map.first().unwrap().len() as isize
            })
            .filter(|pos| !flooded.contains(pos) && !loop_parts.contains(pos))
            .collect();

        for pos in next {
            flooded.insert(pos);
            queue.push_back(pos);
        }
    }

    flooded
}
