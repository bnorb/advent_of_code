mod monkeymap;

use self::monkeymap::{Equation, MonkeyMap};

pub fn part1(input: &str) -> i64 {
    let monkeys = MonkeyMap::parse(input);
    monkeys.get_val("root").unwrap()
}

pub fn part2(input: &str) -> i64 {
    let mut monkeys = MonkeyMap::parse(input);
    monkeys.correct();
    let (unknown, val) = monkeys.calc_half();

    let eq = monkeys
        .build_humn_equation(unknown.as_str())
        .substitute_var(unknown.as_str(), &Equation::Num(val))
        .unwrap();

    eq.calc()
}
