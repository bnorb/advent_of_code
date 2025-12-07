use std::{
    collections::{BinaryHeap, HashMap},
    rc::Rc,
};

#[derive(Clone, Copy, PartialEq, Eq, Debug, Hash)]
enum Cardinal {
    N,
    S,
    W,
    E,
}

impl Cardinal {
    fn step(&self, row: isize, col: isize) -> (isize, isize) {
        match self {
            Self::N => (row - 1, col),
            Self::S => (row + 1, col),
            Self::W => (row, col - 1),
            Self::E => (row, col + 1),
        }
    }

    fn turn_left(&self) -> Self {
        match self {
            Self::N => Self::W,
            Self::S => Self::E,
            Self::W => Self::S,
            Self::E => Self::N,
        }
    }

    fn turn_right(&self) -> Self {
        match self {
            Self::N => Self::E,
            Self::S => Self::W,
            Self::W => Self::N,
            Self::E => Self::S,
        }
    }
}

type State = (Cardinal, (usize, usize), usize);

#[derive(Debug)]
struct Node {
    parent: Option<Rc<Self>>,
    state: State,
    f: usize,
    g: usize,
}

impl Node {
    fn new(parent: Rc<Self>, state: State, g: usize, h: usize) -> Self {
        let g = parent.g + g;
        Node {
            parent: Some(parent),
            state,
            f: g + h,
            g,
        }
    }

    fn root(state: State) -> Self {
        Node {
            parent: None,
            state,
            f: 0,
            g: 0,
        }
    }
}

impl PartialEq for Node {
    fn eq(&self, other: &Self) -> bool {
        self.f == other.f
    }
}

impl Eq for Node {}

impl PartialOrd for Node {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        other.f.partial_cmp(&self.f)
    }
}

impl Ord for Node {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        other.f.cmp(&self.f)
    }
}

fn parse_input(input: &str) -> Vec<Vec<usize>> {
    input
        .lines()
        .map(|row| {
            row.chars()
                .map(|p| p.to_string().parse::<usize>().unwrap())
                .collect()
        })
        .collect()
}

fn get_next(
    width: usize,
    height: usize,
    (curr_dir, (row, col), straight_steps): State,
    ultra: bool,
) -> Vec<State> {
    let (row, col) = (row as isize, col as isize);
    let (left_dir, right_dir) = (curr_dir.turn_left(), curr_dir.turn_right());
    let next = Vec::from([
        (left_dir, left_dir.step(row, col), 1),
        (right_dir, right_dir.step(row, col), 1),
        (curr_dir, curr_dir.step(row, col), straight_steps + 1),
    ]);

    let iter = next
        .into_iter()
        .filter(|(_, (r, c), _)| *r >= 0 && *c >= 0)
        .map(|(d, (r, c), s)| (d, (r as usize, c as usize), s))
        .filter(|(_, (r, c), _)| *r < height && *c < width);

    if ultra {
        iter.filter(|(_, _, step)| {
            if straight_steps < 4 {
                *step > 1
            } else {
                *step <= 10
            }
        })
        .collect()
    } else {
        iter.filter(|(_, _, step)| *step <= 3).collect()
    }
}

fn estimate((sr, sc): (usize, usize), (tr, tc): (usize, usize)) -> usize {
    let (lr, lc) = (tr.min(sr), tc.min(sc));
    let (hr, hc) = (tr.max(sr), tc.max(sc));

    let steps = hr - lr + hc - lc;

    steps
}

fn a_star(
    map: &Vec<Vec<usize>>,
    (sr, sc): (usize, usize),
    target: (usize, usize),
    ultra: bool,
) -> Rc<Node> {
    let mut open = BinaryHeap::new();
    let mut closed = Vec::new();

    let mut f_cache = HashMap::new();

    let width = map[0].len();
    let height = map.len();

    let root = Rc::new(Node::root((Cardinal::S, (sr, sc), 0)));
    f_cache.insert((Cardinal::S, (sr, sc), 0), 0);
    closed.push(Rc::clone(&root));

    let start_1 = Node::new(
        Rc::clone(&root),
        (Cardinal::E, (sr, sc + 1), 1),
        map[sr][sc + 1],
        estimate((sr, sc + 1), target),
    );
    f_cache.insert(start_1.state, start_1.f);
    open.push(Rc::new(start_1));

    let start_2 = Node::new(
        Rc::clone(&root),
        (Cardinal::S, (sr + 1, sc), 1),
        map[sr + 1][sc],
        estimate((sr + 1, sc), target),
    );
    f_cache.insert(start_2.state, start_2.f);
    open.push(Rc::new(start_2));

    while !open.is_empty() {
        let curr_node = open.pop().unwrap();
        for next_state in get_next(width, height, curr_node.state, ultra) {
            let (_, (nr, nc), _) = next_state;

            let next_node = Node::new(
                Rc::clone(&curr_node),
                next_state,
                map[nr][nc],
                estimate((nr, nc), target),
            );

            if (nr, nc) == target {
                return Rc::new(next_node);
            }

            if let Some(curr_best_f) = f_cache.get(&next_state) {
                if *curr_best_f <= next_node.f {
                    continue;
                }
            }

            f_cache.insert(next_state, next_node.f);
            open.push(Rc::new(next_node));
        }

        closed.push(curr_node)
    }

    panic!("");
}

fn sum_heat(map: &Vec<Vec<usize>>, mut node: &Rc<Node>) -> usize {
    let mut heat = map[node.state.1 .0][node.state.1 .1];

    while let Some(parent) = &node.parent {
        heat += map[parent.state.1 .0][parent.state.1 .1];
        node = parent;
    }

    heat -= map[node.state.1 .0][node.state.1 .1];

    heat
}

pub fn part1(input: &str) -> usize {
    let map = parse_input(input);

    let node = &a_star(&map, (0, 0), (map.len() - 1, map[0].len() - 1), false);
    sum_heat(&map, node)
}

pub fn part2(input: &str) -> usize {
    let map = parse_input(input);

    let node = &a_star(&map, (0, 0), (map.len() - 1, map[0].len() - 1), true);
    sum_heat(&map, node)
}
