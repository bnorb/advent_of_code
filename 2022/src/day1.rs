fn parse_input(input: &str) -> Vec<u32> {
    input
        .split("\n\n")
        .map(|elf| {
            elf.lines()
                .map(|l| -> u32 { l.trim().parse().unwrap() })
                .sum()
        })
        .collect()
}

pub fn part1(input: &str) -> u32 {
    let calories = parse_input(input);

    calories
        .into_iter()
        .reduce(|max, e| if max < e { e } else { max })
        .unwrap()
}

pub fn part2(input: &str) -> u32 {
    let calories = parse_input(input);

    let top_three = calories
        .into_iter()
        .fold((0_u32, 0_u32, 0_u32), |mut maxes, e| {
            if e > maxes.0 {
                maxes.2 = maxes.1;
                maxes.1 = maxes.0;
                maxes.0 = e;
            } else if e > maxes.1 {
                maxes.2 = maxes.1;
                maxes.1 = e;
            } else if e > maxes.2 {
                maxes.2 = e;
            }

            maxes
        });

    top_three.0 + top_three.1 + top_three.2
}
