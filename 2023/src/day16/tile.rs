#[derive(Clone, Copy, PartialEq, Eq, Hash)]
pub enum Cardinal {
    N,
    W,
    S,
    E,
}

impl Cardinal {
    pub fn opposite(self) -> Self {
        match self {
            Self::N => Self::S,
            Self::W => Self::E,
            Self::S => Self::N,
            Self::E => Self::W,
        }
    }

    pub fn move_coord(self, row: isize, col: isize) -> (isize, isize) {
        match self {
            Self::N => (row - 1, col),
            Self::W => (row, col - 1),
            Self::S => (row + 1, col),
            Self::E => (row, col + 1),
        }
    }
}

pub enum Tile {
    Empty,              // '.'
    ForwardMirror,      // '/'
    BackMirror,         // '\'
    HorizontalSplitter, // '-'
    VerticalSplitter,   // '|'
}

impl Tile {
    pub fn new(val: char) -> Option<Self> {
        match val {
            '.' => Some(Tile::Empty),
            '/' => Some(Tile::ForwardMirror),
            '\\' => Some(Tile::BackMirror),
            '-' => Some(Tile::HorizontalSplitter),
            '|' => Some(Tile::VerticalSplitter),
            _ => None,
        }
    }

    pub fn next(&self, from: Cardinal) -> (Cardinal, Option<Cardinal>) {
        match (self, from) {
            (Self::Empty, _) => (from.opposite(), None),
            (Self::ForwardMirror, Cardinal::N) => (Cardinal::W, None),
            (Self::ForwardMirror, Cardinal::W) => (Cardinal::N, None),
            (Self::ForwardMirror, Cardinal::S) => (Cardinal::E, None),
            (Self::ForwardMirror, Cardinal::E) => (Cardinal::S, None),
            (Self::BackMirror, Cardinal::N) => (Cardinal::E, None),
            (Self::BackMirror, Cardinal::W) => (Cardinal::S, None),
            (Self::BackMirror, Cardinal::S) => (Cardinal::W, None),
            (Self::BackMirror, Cardinal::E) => (Cardinal::N, None),
            (Self::HorizontalSplitter, Cardinal::N | Cardinal::S) => {
                (Cardinal::W, Some(Cardinal::E))
            }
            (Self::HorizontalSplitter, Cardinal::E | Cardinal::W) => (from.opposite(), None),
            (Self::VerticalSplitter, Cardinal::N | Cardinal::S) => (from.opposite(), None),
            (Self::VerticalSplitter, Cardinal::W | Cardinal::E) => (Cardinal::N, Some(Cardinal::S)),
        }
    }
}
