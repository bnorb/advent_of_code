mod crt;

use self::crt::{Instruction, Crt};

fn parse_input(input: &str) -> Vec<Instruction> {
    input
        .lines()
        .map(|line| match line {
            "noop" => Instruction::Noop,
            addx => Instruction::AddX(addx[5..].parse().unwrap()),
        })
        .collect()
}

pub fn part1(input: &str) -> i32 {
    let instructions = parse_input(input);

    let mut clock = 1;
    let mut x = 1;
    let mut next_point = 20;
    let mut sum = 0;

    for inst in instructions {
        if clock == next_point || clock == next_point - 1 {
            sum += x * next_point;
            if next_point == 220 {
                break;
            }

            next_point += 40;
        }

        match inst {
            Instruction::Noop => clock += 1,
            Instruction::AddX(dx) => {
                x += dx;
                clock += 2;
            }
        }
    }

    sum
}

pub fn part2(input: &str) -> Crt {
    let instructions = parse_input(input);

    let mut crt = Crt::new();

    instructions.iter().for_each(|inst| {
        crt.tick();
        if let Instruction::AddX(dx) = inst {
            crt.tick();
            crt.add_x(*dx);
        }
    });

    crt
}
