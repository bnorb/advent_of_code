use std::collections::HashSet;

fn parse_input(input: &str) -> Vec<Vec<char>> {
    input.lines().map(|line| line.chars().collect()).collect()
}

pub fn part1(input: &str) -> usize {
    let map = parse_input(input);
    find_distances(&map, 2)
}

pub fn part2(input: &str) -> usize {
    let map = parse_input(input);
    find_distances(&map, 1000000)
}

fn find_distances(map: &Vec<Vec<char>>, expansion_factor: usize) -> usize {
    let empty_rows: Vec<usize> = map
        .iter()
        .enumerate()
        .filter(|(_, row)| row.iter().all(|v| *v == '.'))
        .map(|(r_id, _)| r_id)
        .collect();

    let mut empty_cols: HashSet<usize> = map
        .first()
        .unwrap()
        .iter()
        .enumerate()
        .map(|(c_id, _)| c_id)
        .collect();

    map.iter().for_each(|row| {
        row.iter()
            .enumerate()
            .filter(|(_, v)| **v == '#')
            .for_each(|(c_id, _)| {
                empty_cols.remove(&c_id);
            })
    });

    let mut galaxies: Vec<(usize, usize)> = Vec::new();
    map.iter().enumerate().for_each(|(row_id, row)| {
        row.iter()
            .enumerate()
            .filter(|(_, val)| **val == '#')
            .for_each(|(col_id, _)| {
                galaxies.push((row_id, col_id));
            })
    });

    let mut sum_dist = 0;

    for (idx, galaxy_a) in galaxies.iter().enumerate() {
        for galaxy_b in galaxies.iter().skip(idx + 1) {
            let (r_min, r_max) = (galaxy_b.0.min(galaxy_a.0), galaxy_b.0.max(galaxy_a.0));
            let (c_min, c_max) = (galaxy_b.1.min(galaxy_a.1), galaxy_b.1.max(galaxy_a.1));

            let d_r = r_max - r_min
                + (expansion_factor - 1)
                    * empty_rows
                        .iter()
                        .filter(|r_id| **r_id > r_min && **r_id < r_max)
                        .count();
            let d_c = c_max - c_min
                + (expansion_factor - 1)
                    * empty_cols
                        .iter()
                        .filter(|c_id| **c_id > c_min && **c_id < c_max)
                        .count();

            sum_dist += d_r + d_c;
        }
    }

    sum_dist
}
