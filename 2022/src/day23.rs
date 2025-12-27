mod simulation;

use self::simulation::Simulation;

pub fn part1(input: &str) -> usize {
    let mut sim = Simulation::parse(input);
    for _ in 0..10 {
        sim.sim_round();
    }

    let (r_min, r_max, c_min, c_max) = sim.bounds();

    (r_max - r_min + 1) as usize * (c_max - c_min + 1) as usize - sim.elf_count()
}

pub fn part2(input: &str) -> usize {
    let mut sim = Simulation::parse(input);
    let mut i = 1;
    while sim.sim_round() {
        i += 1;
    }

    i
}
