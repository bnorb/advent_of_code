fn parse_input(input: &str) -> Vec<Vec<i32>> {
    input
        .lines()
        .map(|line| {
            line.split_whitespace()
                .map(|num| num.parse::<i32>().unwrap())
                .collect()
        })
        .collect()
}

fn calc_next_sequence(sequence: &Vec<i32>) -> Vec<i32> {
    let mut next_sequence = Vec::new();
    sequence.iter().enumerate().skip(1).for_each(|(idx, val)| {
        let prev = sequence.get(idx - 1).unwrap();
        next_sequence.push(val - prev);
    });

    next_sequence
}

fn find_next(sequence: &Vec<i32>) -> i32 {
    let next_sequence = calc_next_sequence(sequence);

    if next_sequence.iter().all(|v| *v == 0) {
        return *sequence.last().unwrap();
    }

    return sequence.last().unwrap() + find_next(&next_sequence);
}

fn find_prev(sequence: &Vec<i32>) -> i32 {
    let next_sequence = calc_next_sequence(sequence);

    if next_sequence.iter().all(|v| *v == 0) {
        return *sequence.first().unwrap();
    }

    return sequence.first().unwrap() - find_prev(&next_sequence);
}

pub fn part1(input: &str) -> i32 {
    let sequences = parse_input(input);

    sequences
        .iter()
        .map(find_next)
        .reduce(|sum, val| val + sum)
        .unwrap()
}

pub fn part2(input: &str) -> i32 {
    let sequences = parse_input(input);

    sequences
        .iter()
        .map(find_prev)
        .reduce(|sum, val| val + sum)
        .unwrap()
}
