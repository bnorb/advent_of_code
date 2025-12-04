const getNeighbors = (row, col, rowCount, colCount) => {
  const neighbors = [
    [row - 1, col],
    [row + 1, col],
    [row, col - 1],
    [row, col + 1],
  ];

  return neighbors.filter(
    ([row, col]) => row >= 0 && col >= 0 && row < rowCount && col < colCount
  );
};

const getLowPoints = (grid) => {
  const lowPoints = [];
  const rowCount = grid.length;
  const colCount = grid[0].length;

  for (let row = 0; row < rowCount; row++) {
    for (let col = 0; col < colCount; col++) {
      const point = grid[row][col];
      const neighbors = getNeighbors(row, col, rowCount, colCount);

      if (neighbors.every(([row, col]) => grid[row][col] > point)) {
        lowPoints.push([row, col]);
      }
    }
  }

  return lowPoints;
};

const getLargestBasins = (grid, n) => {
  const rowCount = grid.length;
  const colCount = grid[0].length;
  const lowPoints = getLowPoints(grid);

  const bfs = (startingPoint) => {
    const queue = [startingPoint];
    const visited = new Set([`${startingPoint[0]}_${startingPoint[1]}`]);
    let size = 0;
    while (queue.length) {
      const [currentRow, currentCol] = queue.shift();
      size++;

      const neighbors = getNeighbors(
        currentRow,
        currentCol,
        rowCount,
        colCount
      ).filter(
        ([row, col]) =>
          !visited.has(`${row}_${col}`) &&
          grid[row][col] != 9 &&
          grid[row][col] > grid[currentRow][currentCol]
      );

      neighbors.forEach(([row, col]) => visited.add(`${row}_${col}`));
      queue.push(...neighbors);
    }

    return size;
  };

  const sizes = lowPoints.map((p) => bfs(p));
  sizes.sort((a, b) => b - a);
  return sizes.slice(0, n);
};

function parseInput(input) {
  return input
    .split("\n")
    .filter((line) => line.length)
    .map((r) => r.split("").map((p) => parseInt(p, 10)));
}

export function part1(input) {
  const grid = parseInput(input);
  return getLowPoints(grid).reduce(
    (sum, [row, col]) => sum + 1 + grid[row][col],
    0
  );
}

export function part2(input) {
  const grid = parseInput(input);
  return getLargestBasins(grid, 3).reduce((prod, s) => prod * s, 1);
}
