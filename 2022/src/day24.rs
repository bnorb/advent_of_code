mod map;

use self::map::Map;

pub fn part1(input: &str) -> usize {
    let mut map = Map::parse(input);

    map.traverse((0, 1), (map.height() - 1, map.width() - 2));

    map.steps_taken()
}

pub fn part2(input: &str) -> usize {
    let mut map = Map::parse(input);
    let start = (0, 1);
    let end = (map.height() - 1, map.width() - 2);

    map.traverse(start, end);
    map.traverse(end, start);
    map.traverse(start, end);

    map.steps_taken()
}
