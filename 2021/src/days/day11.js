const getNeighbors = (grid, row, col) => {
  const neighbors = [
    [row - 1, col - 1],
    [row - 1, col],
    [row - 1, col + 1],
    [row, col - 1],
    [row, col + 1],
    [row + 1, col - 1],
    [row + 1, col],
    [row + 1, col + 1],
  ];

  return neighbors.filter(
    (cell) =>
      cell[0] >= 0 &&
      cell[0] < grid.length &&
      cell[1] >= 0 &&
      cell[1] < grid[0].length
  );
};

const tick = (grid) => {
  const bfs = (start) => {
    let flashes = 0;
    const queue = [start];

    while (queue.length) {
      const [currentRow, currentCol] = queue.shift();

      flashed.add(`${currentRow}_${currentCol}`);
      grid[currentRow][currentCol] = 0;
      flashes++;

      const neighbors = getNeighbors(grid, currentRow, currentCol).filter(
        ([row, col]) => {
          return !flashed.has(`${row}_${col}`);
        }
      );

      neighbors.forEach(([row, col]) => {
        grid[row][col]++;

        if (grid[row][col] > 9) {
          queue.push([row, col]);
          flashed.add(`${row}_${col}`);
        }
      });
    }

    return flashes;
  };

  const flashed = new Set();
  let flashes = 0;

  grid.forEach((line, row) => {
    line.forEach((oct, col) => (grid[row][col] = oct + 1));
  });

  for (let row = 0; row < grid.length; row++) {
    for (let col = 0; col < grid[0].length; col++) {
      if (grid[row][col] > 9) {
        flashes += bfs([row, col]);
      }
    }
  }

  return flashes;
};

const countFlashes = (inGrid, n) => {
  const grid = [...inGrid.map((l) => [...l])];

  let i = 0;
  let flashes = 0;
  while (i < n) {
    flashes += tick(grid);
    i++;
  }

  return flashes;
};

const getSyncFlash = (inGrid) => {
  const grid = [...inGrid.map((l) => [...l])];
  const gridSize = grid.length * grid[0].length;

  let i = 1;
  while (true) {
    if (gridSize == tick(grid)) {
      return i;
    }

    i++;
  }
};

function parseInput(input) {
  return input
    .split("\n")
    .filter((line) => line.length)
    .map((l) => l.split("").map((o) => parseInt(o, 10)));
}

export function part1(input) {
  const grid = parseInput(input);
  return countFlashes(grid, 100);
}

export function part2(input) {
  const grid = parseInput(input);
  return getSyncFlash(grid);
}
