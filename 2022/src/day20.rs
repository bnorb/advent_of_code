mod circle;

use self::circle::CircularList;

pub fn part1(input: &str) -> i64 {
    let nums = input.lines().map(|line| line.parse().unwrap()).collect();

    let circle = CircularList::from(&nums);
    circle.move_all();

    let coords: Vec<i64> = [1000, 2000, 3000]
        .into_iter()
        .map(|coord| circle.find_coord(coord))
        .collect();
    coords.into_iter().fold(0, |sum, val| sum + val)
}

pub fn part2(input: &str) -> i64 {
    let nums = input
        .lines()
        .map(|line| line.parse::<i64>().unwrap() * 811589153)
        .collect();

    let circle = CircularList::from(&nums);

    for _ in 0..10 {
        circle.move_all();
    }

    let coords: Vec<i64> = [1000, 2000, 3000]
        .into_iter()
        .map(|coord| circle.find_coord(coord))
        .collect();
    coords.into_iter().fold(0, |sum, val| sum + val)
}
