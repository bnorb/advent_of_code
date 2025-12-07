use itertools::Itertools;

fn parse_input(input: &str) -> Vec<Vec<f64>> {
    input
        .lines()
        .map(|line| {
            let mut strip = true;
            line.trim_start_matches(|c| {
                if c == ':' {
                    strip = false;
                    return true;
                }

                return strip;
            })
            .trim()
            .split_whitespace()
            .map(|num| num.parse::<f64>().unwrap())
            .collect()
        })
        .collect()
}

fn calc_winning((t, d): (f64, f64)) -> u32 {
    // -x^2 + Tx - D
    let root_term = (t.powi(2) - 4.0 * d).sqrt();
    let r1 = (-t + root_term) / -2.0;
    let r2 = (-t - root_term) / -2.0;

    let min = (r1 + 1.0).floor() as u32;
    let max = (r2 - 1.0).ceil() as u32;

    return max - min + 1;
}

pub fn part1(input: &str) -> u32 {
    let numbers = parse_input(input);

    numbers
        .get(0)
        .unwrap()
        .into_iter()
        .zip(numbers.get(1).unwrap().into_iter())
        .map(|(time, distance)| (*time, *distance))
        .map(calc_winning)
        .reduce(|prod, curr| prod * curr)
        .unwrap() as u32
}

pub fn part2(input: &str) -> u32 {
    let numbers = parse_input(input);

    calc_winning(
        numbers
            .into_iter()
            .map(|line| line.into_iter().map(|num| num.to_string()).join(""))
            .map(|num| num.parse::<f64>().unwrap())
            .collect_tuple()
            .unwrap(),
    )
}
