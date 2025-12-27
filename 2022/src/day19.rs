mod simulation;

use self::simulation::{Robot, Simulation};

fn parse_input(input: &str) -> Vec<[Robot; 4]> {
    input
        .lines()
        .map(|line| Robot::parse_blueprint(line))
        .collect()
}

pub fn part1(input: &str) -> usize {
    let blueprints = parse_input(input);

    blueprints
        .iter()
        .enumerate()
        .map(|(i, bp)| {
            let mut simulation = Simulation::new(*bp, 24);
            let max = simulation.run();

            (i + 1) * max as usize
        })
        .fold(0, |sum, max| sum + max)
}

pub fn part2(input: &str) -> u16 {
    let blueprints = parse_input(input);

    blueprints
        .iter()
        .take(3)
        .map(|bp| {
            let mut simulation = Simulation::new(*bp, 32);
            simulation.run()
        })
        .reduce(|prod, max| prod * max)
        .unwrap()
}
