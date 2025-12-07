use std::collections::LinkedList;

use itertools::Itertools;

fn parse_input(input: &str) -> Vec<Vec<char>> {
    input
        .trim_end()
        .split(",")
        .map(|part| part.chars().collect())
        .collect()
}

fn hash(part: &[char]) -> usize {
    part.iter()
        .map(|c| *c as usize)
        .fold(0, |h, c| ((h + c) * 17) % 256)
}

pub fn part1(input: &str) -> usize {
    let parts = parse_input(input);

    parts.iter().map(|part| hash(part)).sum()
}

pub fn part2(input: &str) -> usize {
    let parts = parse_input(input);

    let mut boxes = [0; 256].map(|_| LinkedList::new());
    for part in parts {
        match &part[..] {
            [label @ .., '=', focal_length] => {
                let curr_box: &mut LinkedList<(String, u8)> = &mut boxes[hash(label)];
                let label = String::from(label.iter().join(""));
                let focal_length = focal_length.to_digit(10).unwrap() as u8;

                if let Some(curr_lens) = curr_box.iter_mut().find(|(l, _)| *l == label) {
                    (*curr_lens).1 = focal_length;
                } else {
                    curr_box.push_back((label, focal_length))
                }
            }
            [label @ .., '-'] => {
                let curr_box: &mut LinkedList<(String, u8)> = &mut boxes[hash(label)];
                let label = String::from(label.iter().join(""));
                if let Some((index, _)) =
                    curr_box.iter().enumerate().find(|(_, (l, _))| *l == label)
                {
                    let mut tail = curr_box.split_off(index);
                    tail.pop_front();
                    curr_box.append(&mut tail);
                }
            }
            _ => panic!("can't happen"),
        }
    }

    boxes
        .into_iter()
        .enumerate()
        .map(|(idx, b)| {
            b.into_iter()
                .enumerate()
                .map(|(slot, (_, focal_length))| (idx + 1) * (slot + 1) * (focal_length as usize))
                .collect::<Vec<usize>>()
        })
        .flatten()
        .sum()
}
