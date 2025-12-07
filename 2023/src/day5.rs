use itertools::Itertools;

use self::map::Map;

mod map;

/*
0: seed-to-soil
1: soil-to-fertilizer
2: fertilizer-to-water
3: water-to-light
4: light-to-temperature
5: temperature-to-humidity
6: humidity-to-location
*/

fn parse_input(input: &str) -> (Vec<i64>, Vec<Map>) {
    let mut parts = input.split("\n\n");
    let seeds = parts.next().unwrap();
    let seeds = seeds
        .strip_prefix("seeds: ")
        .unwrap()
        .split(" ")
        .map(|seed| seed.parse::<i64>().unwrap())
        .collect::<Vec<i64>>();

    let maps = parts
        .map(|map| -> Vec<(i64, i64, i64)> {
            map.lines()
                .skip(1)
                .map(|line| {
                    line.split(" ")
                        .map(|val| val.parse::<i64>().unwrap())
                        .collect_tuple()
                        .unwrap()
                })
                .collect()
        })
        .map(|ranges| Map::new(ranges))
        .collect();

    (seeds, maps)
}

pub fn part1(input: &str) -> i64 {
    let (seeds, maps) = parse_input(input);

    seeds.iter().fold(i64::MAX, |min_location, seed| {
        let location = maps
            .iter()
            .fold(*seed, |current, map| map.translate(current));

        location.min(min_location)
    })
}

// create extra ranges for everything
// only check min of each range

pub fn part2(input: &str) -> i64 {
    let (seeds, maps) = parse_input(input);

    let mut current = seeds
        .iter()
        .batching(|it| match it.next() {
            None => None,
            Some(start) => match it.next() {
                None => None,
                Some(len) => Some((*start, start + len)),
            },
        })
        .collect::<Vec<(i64, i64)>>();

    maps.iter().for_each(|map| {
        current = map.get_possible_ranges(&current);
    });

    current
        .into_iter()
        .fold(i64::MAX, |min, (start, _)| min.min(start))
}
