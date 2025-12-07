use std::collections::{HashMap, HashSet, LinkedList};

use itertools::Itertools;

#[derive(PartialEq, Eq, Debug)]
pub enum Cardinal {
    N,
    W,
    S,
    E,
}

#[derive(PartialEq, Eq, Debug)]
pub enum Tile {
    Wall,
    Floor,
    Slope(Cardinal),
}

impl Tile {
    fn parse(c: char) -> Self {
        match c {
            '#' => Self::Wall,
            '.' => Self::Floor,
            '^' => Self::Slope(Cardinal::N),
            '<' => Self::Slope(Cardinal::W),
            'v' => Self::Slope(Cardinal::S),
            '>' => Self::Slope(Cardinal::E),
            _ => panic!(),
        }
    }
}

fn parse_input(input: &str) -> (Vec<Vec<Tile>>, (usize, usize), (usize, usize)) {
    let start = (
        0,
        input
            .lines()
            .next()
            .unwrap()
            .chars()
            .find_position(|c| *c == '.')
            .unwrap()
            .0,
    );
    let end = (
        (input.lines().count()) - 1,
        input
            .lines()
            .last()
            .unwrap()
            .chars()
            .find_position(|c| *c == '.')
            .unwrap()
            .0,
    );

    let map = input
        .lines()
        .map(|line| line.chars().map(|c| Tile::parse(c)).collect())
        .collect();

    (map, start, end)
}

pub fn part1(input: &str) -> usize {
    let (map, start, end) = parse_input(input);

    let mut visited = HashSet::from([start]);
    let mut max = 0;

    dfs(start, &end, &map, &mut visited, 0, &mut max);

    max
}

pub fn part2(input: &str) -> usize {
    let (map, start, end) = parse_input(input);

    let mut nodes = build_graph(start, &end, &map);
    make_edges_directional(start, &end, &mut nodes);

    let mut visited = HashSet::from([start]);
    let mut max = 0;

    dfs_nodes(start, &end, &nodes, &mut visited, 0, &mut max);

    max
}

fn get_neighbors(
    (row, col): (usize, usize),
    map: &Vec<Vec<Tile>>,
    use_slopes: bool,
) -> Vec<(usize, usize)> {
    let tile = &map[row][col];

    let directions = match *tile {
        Tile::Slope(Cardinal::N) if use_slopes => vec![(-1, 0)],
        Tile::Slope(Cardinal::W) if use_slopes => vec![(0, -1)],
        Tile::Slope(Cardinal::S) if use_slopes => vec![(1, 0)],
        Tile::Slope(Cardinal::E) if use_slopes => vec![(0, 1)],
        _ => vec![(-1, 0), (1, 0), (0, -1), (0, 1)],
    };

    directions
        .into_iter()
        .map(|(dr, dc)| (row as isize + dr, col as isize + dc))
        .filter(|(r, c)| *r >= 0 && *c >= 0)
        .map(|(r, c)| (r as usize, c as usize))
        .filter(|(r, c)| *r < map.len() && *c < map[0].len())
        .filter(|(r, c)| map[*r][*c] != Tile::Wall)
        .collect()
}

fn dfs(
    curr: (usize, usize),
    end: &(usize, usize),
    map: &Vec<Vec<Tile>>,
    visited: &mut HashSet<(usize, usize)>,
    steps: usize,
    max: &mut usize,
) {
    if curr == *end {
        if *max < steps {
            *max = steps;
        }
        return;
    }

    for next in get_neighbors(curr, map, true) {
        if visited.contains(&next) {
            continue;
        }

        visited.insert(next);
        dfs(next, end, map, visited, steps + 1, max);
        visited.remove(&next);
    }
}

fn dfs_nodes(
    curr: (usize, usize),
    end: &(usize, usize),
    nodes: &HashMap<(usize, usize), HashSet<((usize, usize), usize)>>,
    visited: &mut HashSet<(usize, usize)>,
    steps: usize,
    max: &mut usize,
) {
    if curr == *end {
        if *max < steps {
            *max = steps;
        }
        return;
    }

    for (next, path_steps) in nodes.get(&curr).unwrap() {
        if visited.contains(&next) {
            continue;
        }

        visited.insert(*next);
        dfs_nodes(*next, end, nodes, visited, steps + path_steps, max);
        visited.remove(next);
    }
}

// since it's a map and we're starting on the edge (corner even) it doesn't make sense to go back up the edges
fn make_edges_directional(
    start: (usize, usize),
    end: &(usize, usize),
    nodes: &mut HashMap<(usize, usize), HashSet<((usize, usize), usize)>>,
) {
    let mut queue = LinkedList::from([start]);

    while !queue.is_empty() {
        let curr = queue.pop_front().unwrap();

        let next_nodes: HashSet<((usize, usize), usize)> = nodes.get(&curr).unwrap().clone();

        for (next, steps) in next_nodes {
            if next == *end {
                break;
            }

            let next_set = nodes.get_mut(&next).unwrap();

            if next_set.len() > 3 {
                continue;
            }

            next_set.remove(&(curr, steps));
            queue.push_back(next);
        }
    }
}

fn build_graph(
    start: (usize, usize),
    end: &(usize, usize),
    map: &Vec<Vec<Tile>>,
) -> HashMap<(usize, usize), HashSet<((usize, usize), usize)>> {
    let mut nodes = HashMap::from([(start, HashSet::new())]);
    let mut node_queue = LinkedList::from([(start, vec![(start.0 + 1, start.1)])]);

    // let mut safety = 0;

    while !node_queue.is_empty() {
        // dbg!(&node_queue);
        let (current_node, branches) = node_queue.pop_front().unwrap();

        // dbg!(current_node, &branches);

        for branch in branches {
            let mut curr_tile = branch;
            let mut steps = 0;
            let mut path_visited = HashSet::from([current_node, curr_tile]);

            loop {
                steps += 1;
                // safety += 1;
                // if safety > 100 {
                //     panic!();
                // }

                let next: Vec<(usize, usize)> = get_neighbors(curr_tile, map, false)
                    .into_iter()
                    .filter(|n| !path_visited.contains(n))
                    .collect();

                // dbg!(&next);

                match next.len() {
                    // dead end
                    0 => {
                        if curr_tile == *end {
                            nodes
                                .get_mut(&current_node)
                                .unwrap()
                                .insert((curr_tile, steps));
                        }

                        break;
                    }
                    // normal path
                    1 => {
                        path_visited.insert(next[0]);
                        curr_tile = next[0];
                    }
                    // branching
                    _ => {
                        nodes
                            .get_mut(&current_node)
                            .unwrap()
                            .insert((curr_tile, steps));

                        if nodes.contains_key(&curr_tile) {
                            nodes
                                .get_mut(&curr_tile)
                                .unwrap()
                                .insert((current_node, steps));
                        } else {
                            node_queue.push_back((curr_tile, next));
                            nodes.insert(curr_tile, HashSet::from([(current_node, steps)]));
                        }

                        break;
                    }
                }
            }
        }
    }

    nodes
}
