pub type Balls = (u8, u8, u8);

pub struct Game {
    id: u8,
    revelations: Vec<Balls>,
}

impl Game {
    pub fn new(id: u8, revelations: Vec<Balls>) -> Self {
        return Game { id, revelations };
    }

    pub fn is_possible(&self, max_balls: Balls) -> bool {
        self.revelations
            .iter()
            .all(|balls| balls.0 <= max_balls.0 && balls.1 <= max_balls.1 && balls.2 <= max_balls.2)
    }

    pub fn id(&self) -> u8 {
        return self.id;
    }

    pub fn min_possible(&self) -> Balls {
        self.revelations
            .iter()
            .fold((0, 0, 0), |(mr, mg, mb), (r, g, b)| {
                (mr.max(*r), mg.max(*g), mb.max(*b))
            })
    }
}
