use std::ops;

use itertools::Itertools;

#[derive(Debug, Clone, Copy, PartialEq)]
struct Coord {
    x: f64,
    y: f64,
    z: f64,
}

impl Coord {
    fn sum(&self) -> f64 {
        self.x + self.y + self.z
    }

    fn tuple(&self) -> (f64, f64, f64) {
        (self.x, self.y, self.z)
    }
}

impl ops::Add<Coord> for Coord {
    type Output = Coord;

    fn add(self, rhs: Coord) -> Coord {
        Coord {
            x: self.x + rhs.x,
            y: self.y + rhs.y,
            z: self.z + rhs.z,
        }
    }
}

impl ops::Sub<Coord> for Coord {
    type Output = Coord;

    fn sub(self, rhs: Coord) -> Coord {
        Coord {
            x: self.x - rhs.x,
            y: self.y - rhs.y,
            z: self.z - rhs.z,
        }
    }
}

impl ops::Mul<f64> for Coord {
    type Output = Coord;

    fn mul(self, rhs: f64) -> Coord {
        Coord {
            x: self.x * rhs,
            y: self.y * rhs,
            z: self.z * rhs,
        }
    }
}

impl ops::Div<f64> for Coord {
    type Output = Coord;

    fn div(self, rhs: f64) -> Coord {
        Coord {
            x: self.x / rhs,
            y: self.y / rhs,
            z: self.z / rhs,
        }
    }
}

#[derive(Debug, Clone)]
struct Hailstone {
    pos: Coord,
    vel: Coord,
}
impl Hailstone {
    fn new(pos: Vec<f64>, vel: Vec<f64>) -> Self {
        Hailstone {
            pos: Coord {
                x: pos[0],
                y: pos[1],
                z: pos[2],
            },
            vel: Coord {
                x: vel[0],
                y: vel[1],
                z: vel[2],
            },
        }
    }

    fn make_relative_to(&mut self, other: &Hailstone) {
        self.pos = self.pos - other.pos;
        self.vel = self.vel - other.vel;
    }

    fn calc_at_t(&self, t: f64) -> Coord {
        self.pos + (self.vel * t)
    }
}

fn get_intersection_2d(h0: &Hailstone, h1: &Hailstone) -> Option<(f64, f64)> {
    let determinant = h0.vel.x * h1.vel.y - h0.vel.y * h1.vel.x;

    if determinant == 0.0 {
        return None;
    }

    let time = ((h1.pos.x - h0.pos.x) * h1.vel.y - (h1.pos.y - h0.pos.y) * h1.vel.x) / determinant;
    let time2 = ((h0.pos.x - h1.pos.x) * h0.vel.y - (h0.pos.y - h1.pos.y) * h0.vel.x) / determinant;

    if time < 0.0 {
        return None;
    }
    if time * time2 > 0.0 {
        return None;
    }
    let x = h0.pos.x + h0.vel.x * time;
    let y = h0.pos.y + h0.vel.y * time;

    Some((x, y))
}

fn parse_input(input: &str) -> Vec<Hailstone> {
    input
        .lines()
        .map(|line| line.split_once(" @ ").unwrap())
        .map(|(pos, vel)| {
            [pos, vel]
                .into_iter()
                .map(|vector| {
                    vector
                        .split(',')
                        .map(|p| p.trim().parse().unwrap())
                        .collect()
                })
                .collect_tuple()
                .unwrap()
        })
        .map(|(pos, vel)| Hailstone::new(pos, vel))
        .collect()
}

pub fn part1(input: &str) -> isize {
    let area: (f64, f64) = (200000000000000.0, 400000000000000.0);
    let hailstones = parse_input(input);

    let (lower, upper) = area;
    let mut collisions = 0;
    for combinations in hailstones.iter().combinations(2) {
        if let Some(intersection) = get_intersection_2d(combinations[0], combinations[1]) {
            let (x, y) = intersection;

            if (x > lower && x < upper) && (y > lower && y < upper) {
                collisions += 1;
            }
        }
    }

    return collisions;
}

pub fn part2(input: &str) -> u64 {
    let hailstones = parse_input(input);

    // find 3 hailstones with one same velocity component (it really makes the algebra easier)
    // I found one with x y and z, I suspect this is by design, let's go with x
    let (h0, h1, h2) = hailstones
        .iter()
        .combinations(3)
        .map(|combo| (combo[0], combo[1], combo[2]))
        .filter(|(h0, h1, h2)| (h0.vel.x == h1.vel.x && h0.vel.x == h2.vel.x))
        .next()
        .unwrap();

    // make h0 the origin
    let mut h1_rel = h1.clone();
    let mut h2_rel = h2.clone();
    h1_rel.make_relative_to(h0);
    h2_rel.make_relative_to(h0);

    // collisions are on the same line going through origin and (p1+t1*v1) and (p2+t2*v2), call them cv1 and cv2
    // since they are on the same line, cv1 = m*cv2, where m is some scalar
    // we can normalize both by dividing by one coord to get rid of m. if we divide by the coord where ther relative velocity is 0, this is pretty easy
    // after some algebra on paper...
    let (x1, y1, z1) = h1_rel.pos.tuple();
    let (x2, y2, z2) = h2_rel.pos.tuple();
    let (_vx1, vy1, vz1) = h1_rel.vel.tuple();
    let (_vx2, vy2, vz2) = h2_rel.vel.tuple();

    let t2 =
        (y2 * vz1 - y1 * vz1 * x2 / x1 + z1 * vy1 * x2 / x1 - z2 * vy1) / (vy1 * vz2 - vy2 * vz1);

    let t1 = (t2 * vy2 * x1 + y2 * x1 - y1 * x2) / (vy1 * x2);

    let collision_1 = h1.calc_at_t(t1);
    let collision_2 = h2.calc_at_t(t2);

    let rock_velocity = (collision_2 - collision_1) / (t2 - t1);
    let initial_position = collision_1 - (rock_velocity * t1);

    initial_position.sum().floor() as u64
}
