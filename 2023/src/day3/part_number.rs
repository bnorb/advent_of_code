#[derive(Debug)]
pub struct PartNumber {
    value: u32,
    row: isize,
    start: isize,
    end: isize,
}

impl PartNumber {
    pub fn new(value: u32, row: usize, start: usize, end: usize) -> Self {
        PartNumber {
            value,
            row: row as isize,
            start: start as isize,
            end: end as isize,
        }
    }

    fn get_neighbors(&self, row_size: usize, col_size: usize) -> Vec<(usize, usize)> {
        let mut neighbors: Vec<(isize, isize)> = Vec::new();
        neighbors.extend(
            [
                (self.row, self.start - 1),
                (self.row - 1, self.start - 1),
                (self.row + 1, self.start - 1),
            ]
            .iter(),
        );

        neighbors.extend(
            [
                (self.row, self.end),
                (self.row - 1, self.end),
                (self.row + 1, self.end),
            ]
            .iter(),
        );

        for num in self.start..self.end {
            neighbors.extend([(self.row - 1, num), (self.row + 1, num)].iter())
        }

        neighbors
            .into_iter()
            .filter(|(row, col)| *row > 0 && *col > 0)
            .map(|(row, col)| (row as usize, col as usize))
            .filter(|(row, col)| *row < row_size && *col < col_size)
            .collect()
    }

    pub fn is_valid(&self, map: &Vec<Vec<char>>) -> bool {
        self.get_neighbors(map.len(), map.get(0).unwrap().len())
            .into_iter()
            .map(|(row, col)| map.get(row).unwrap().get(col).unwrap())
            .any(|c| !c.is_numeric() && *c != '.')
    }

    pub fn get_gears(&self, map: &Vec<Vec<char>>) -> Vec<(usize, usize)> {
        self.get_neighbors(map.len(), map.get(0).unwrap().len())
            .into_iter()
            .filter(|(row, col)| *map.get(*row).unwrap().get(*col).unwrap() == '*')
            .collect()
    }

    pub fn value(&self) -> u32 {
        self.value
    }
}
