use std::{
    cmp::Ordering,
    collections::{HashMap, HashSet},
};

use itertools::Itertools;

type Coord = (i16, i16, i16);
type Brick = (u16, (Coord, Coord));

fn parse_input(input: &str) -> Vec<Brick> {
    let mut id = 0;
    input
        .lines()
        .map(|line| {
            let coords = line
                .split("~")
                .map(|part| {
                    part.split(",")
                        .map(|c| c.parse::<i16>().unwrap())
                        .collect_tuple::<Coord>()
                        .unwrap()
                })
                .sorted_by(|a: &Coord, b: &Coord| match a.2.cmp(&b.2) {
                    Ordering::Equal => match a.1.cmp(&b.1) {
                        Ordering::Equal => a.0.cmp(&a.0),
                        o => o,
                    },
                    o => o,
                })
                .collect_tuple()
                .unwrap();
            let brick = (id, coords);
            id += 1;

            brick
        })
        .sorted_by(|a: &Brick, b: &Brick| match a.1 .0 .2.cmp(&b.1 .0 .2) {
            Ordering::Equal => a.1 .1 .2.cmp(&b.1 .1 .2),
            ord => ord,
        })
        .collect()
}

fn does_intersect(
    (_, ((ax1, ay1, _), (ax2, ay2, _))): &Brick,
    (_, ((bx1, by1, _), (bx2, by2, _))): &Brick,
) -> bool {
    ax1 <= bx2 && ax2 >= bx1 && ay1 <= by2 && ay2 >= by1
}

fn fall(z_map: &HashMap<i16, Vec<Brick>>, brick: &mut Brick) -> Vec<u16> {
    loop {
        let below_z = brick.1 .0 .2 - 1;
        if below_z == 0 {
            return Vec::new();
        }

        if let Some(bricks) = z_map.get(&below_z) {
            let bricks_under: Vec<u16> = bricks
                .iter()
                .filter(|below_brick| does_intersect(brick, below_brick))
                .map(|(id, _)| *id)
                .collect();

            if bricks_under.len() > 0 {
                return bricks_under;
            }
        }

        let (_, ((_, _, z1), (_, _, z2))) = brick;
        *z1 = *z1 - 1;
        *z2 = *z2 - 1;
    }
}

fn build_maps(bricks: &Vec<Brick>) -> (HashMap<u16, Vec<u16>>, HashMap<u16, Vec<u16>>) {
    let mut bricks = bricks.clone();
    let mut z_end_map: HashMap<i16, Vec<Brick>> = HashMap::new();
    let mut below_map: HashMap<u16, Vec<u16>> = HashMap::new();
    let mut above_map: HashMap<u16, Vec<u16>> = HashMap::new();

    bricks.iter_mut().for_each(|brick| {
        let bricks_under = fall(&z_end_map, brick);
        bricks_under.iter().for_each(|b_id| {
            if let Some(bricks) = above_map.get_mut(b_id) {
                bricks.push(brick.0);
            } else {
                above_map.insert(*b_id, vec![brick.0]);
            }
        });
        below_map.insert(brick.0, bricks_under);

        if let Some(bricks) = z_end_map.get_mut(&brick.1 .1 .2) {
            bricks.push(*brick);
        } else {
            z_end_map.insert(brick.1 .1 .2, vec![*brick]);
        }
    });

    (below_map, above_map)
}

fn count(
    brick_id: &u16,
    below_map: &HashMap<u16, Vec<u16>>,
    above_map: &HashMap<u16, Vec<u16>>,
    fallen: &mut HashSet<u16>,
) {
    if let Some(above_bricks) = above_map.get(brick_id) {
        let no_longer_supported: Vec<u16> = above_bricks
            .iter()
            .filter(|above_brick| {
                let supports = below_map
                    .get(above_brick)
                    .unwrap()
                    .iter()
                    .filter(|support| !fallen.contains(support))
                    .count();

                supports == 0
            })
            .map(|id| *id)
            .collect();

        fallen.extend(no_longer_supported.iter());

        for brick in no_longer_supported.iter() {
            count(brick, below_map, above_map, fallen);
        }
    }
}

pub fn part1(input: &str) -> usize {
    let bricks = parse_input(input);

    let mut safe = 0;

    let (below_map, above_map) = build_maps(&bricks);

    bricks.iter().for_each(|(id, _)| {
        if let Some(bricks) = above_map.get(&id) {
            let count = bricks
                .iter()
                .filter(|above_brick| below_map.get(above_brick).unwrap().len() < 2)
                .count();

            if count == 0 {
                safe += 1;
            }
        } else {
            safe += 1;
        }
    });

    safe
}

pub fn part2(input: &str) -> usize {
    let bricks = parse_input(input);

    let (below_map, above_map) = build_maps(&bricks);

    let sum = bricks
        .iter()
        .map(|(id, _)| {
            let mut fallen = HashSet::from([*id]);
            count(id, &below_map, &above_map, &mut fallen);
            fallen.len() - 1
        })
        .sum();

    sum
}
