use std::collections::HashMap;

use itertools::Itertools;

fn parse_input(input: &str) -> Vec<(Vec<char>, Vec<usize>, usize)> {
    input
        .lines()
        .map(|line| {
            let (known, sums): (&str, &str) = line.split_whitespace().collect_tuple().unwrap();
            let mut total = 0;
            let ordered_parts: Vec<usize> = sums
                .split(",")
                .map(|num| num.parse::<usize>().unwrap())
                .inspect(|num| total += num)
                .collect();

            let known: Vec<char> = known.chars().collect();
            let unordered_parts = known.len() as usize - total;

            (known, ordered_parts, unordered_parts)
        })
        .collect()
}

pub fn part1(input: &str) -> usize {
    let lines = parse_input(input);

    lines
        .iter()
        .map(|(known, ordered, unordered)| {
            let mut cache = HashMap::new();
            count(known, ordered, &mut cache, (0, 0, *unordered, false))
        })
        .fold(0, |sum, count| sum + count)
}

pub fn part2(input: &str) -> usize {
    let lines = parse_input(input);

    lines
        .iter()
        .map(|(known, ordered, unordered)| unfold(known, ordered, *unordered))
        .map(|(known, ordered, unordered)| {
            let mut cache = HashMap::new();
            count(&known, &ordered, &mut cache, (0, 0, unordered, false))
        })
        .fold(0, |sum, count| sum + count)
}

fn can_fit(next_ordered_part_size: usize, known: &Vec<char>, pos: usize) -> bool {
    next_ordered_part_size > 0
        && known.len() >= pos + next_ordered_part_size
        && known[pos..pos + next_ordered_part_size]
            .iter()
            .all(|c| *c != '.')
}

type State = (usize, usize, usize, bool);

fn count(
    known: &Vec<char>,
    ordered_parts: &Vec<usize>,
    cache: &mut HashMap<State, usize>,
    (pos, next_ordered_part, remaining_unordered_parts, last_was_ordered): State,
) -> usize {
    if pos >= known.len() {
        if next_ordered_part >= ordered_parts.len() && remaining_unordered_parts == 0 {
            return 1;
        }

        return 0;
    }

    let next_ordered_part_size = ordered_parts
        .get(next_ordered_part)
        .map(|size| *size)
        .unwrap_or_else(|| 0);

    let pos_char = *known.get(pos).unwrap();

    let mut sum = 0;

    if (pos_char == '.' || pos_char == '?') && remaining_unordered_parts > 0 {
        let new_state = (
            pos + 1,
            next_ordered_part,
            remaining_unordered_parts - 1,
            false,
        );

        if let Some(c) = cache.get(&new_state) {
            sum += c;
        } else {
            let c = count(known, ordered_parts, cache, new_state);

            cache.insert(new_state, c);
            sum += c;
        }
    }

    if (pos_char == '#' || pos_char == '?')
        && !last_was_ordered
        && can_fit(next_ordered_part_size, known, pos)
    {
        let new_state = (
            pos + next_ordered_part_size,
            next_ordered_part + 1,
            remaining_unordered_parts,
            true,
        );

        if let Some(c) = cache.get(&new_state) {
            sum += c;
        } else {
            let c = count(known, ordered_parts, cache, new_state);

            cache.insert(new_state, c);
            sum += c;
        }
    }

    sum
}

fn unfold(
    known: &Vec<char>,
    ordered_parts: &Vec<usize>,
    unordered_parts: usize,
) -> (Vec<char>, Vec<usize>, usize) {
    let known = vec![known; 5]
        .into_iter()
        .map(|v| String::from_iter(v))
        .join("?")
        .chars()
        .collect();

    let ordered_parts = vec![ordered_parts; 5]
        .into_iter()
        .flatten()
        .map(|v| *v)
        .collect();

    (known, ordered_parts, 5 * unordered_parts + 4)
}
