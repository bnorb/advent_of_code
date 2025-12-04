class MinHeap {
  constructor() {
    this.heap = [null];
  }

  getMin() {
    return this.heap[1];
  }

  insert(node) {
    this.heap.push(node);

    if (this.heap.length > 1) {
      let current = this.heap.length - 1;

      while (
        current > 1 &&
        this.heap[Math.floor(current / 2)][1] > this.heap[current][1]
      ) {
        [this.heap[Math.floor(current / 2)], this.heap[current]] = [
          this.heap[current],
          this.heap[Math.floor(current / 2)],
        ];
        current = Math.floor(current / 2);
      }
    }
  }

  remove() {
    let smallest = this.heap[1];

    if (this.heap.length > 2) {
      this.heap[1] = this.heap[this.heap.length - 1];
      this.heap.splice(this.heap.length - 1);

      if (this.heap.length === 3) {
        if (this.heap[1][1] > this.heap[2][1]) {
          [this.heap[1], this.heap[2]] = [this.heap[2], this.heap[1]];
        }
        return smallest;
      }

      let current = 1;
      let leftChildIndex = current * 2;
      let rightChildIndex = current * 2 + 1;

      while (
        this.heap[leftChildIndex] &&
        this.heap[rightChildIndex] &&
        (this.heap[current][1] > this.heap[leftChildIndex][1] ||
          this.heap[current][1] > this.heap[rightChildIndex][1])
      ) {
        if (this.heap[leftChildIndex][1] < this.heap[rightChildIndex][1]) {
          [this.heap[current], this.heap[leftChildIndex]] = [
            this.heap[leftChildIndex],
            this.heap[current],
          ];
          current = leftChildIndex;
        } else {
          [this.heap[current], this.heap[rightChildIndex]] = [
            this.heap[rightChildIndex],
            this.heap[current],
          ];
          current = rightChildIndex;
        }

        leftChildIndex = current * 2;
        rightChildIndex = current * 2 + 1;
      }
    } else if (this.heap.length === 2) {
      this.heap.splice(1, 1);
    } else {
      return null;
    }

    return smallest;
  }
}

const getLowRiskPath = (grid) => {
  const getNeighbors = (x, y, width, height) => {
    const n = [
      [x - 1, y],
      [x + 1, y],
      [x, y - 1],
      [x, y + 1],
    ];

    return n.filter(
      (point) =>
        point[0] < height && point[0] >= 0 && point[1] < width && point[1] >= 0
    );
  };

  const dijkstra = (distances, width, height, grid) => {
    const unvisited = new Set();
    const heap = new MinHeap();
    heap.insert(["0_0", 0]);

    for (let i = 0; i < height; i++) {
      for (let j = 0; j < width; j++) {
        unvisited.add(`${i}_${j}`);
      }
    }

    let i = 1;
    while (unvisited.size > 0) {
      let [vertex, distance] = heap.getMin();
      unvisited.delete(vertex);
      heap.remove();

      if (vertex != null) {
        vertex = vertex.split("_").map((i) => parseInt(i, 10));
        getNeighbors(...vertex, width, height).forEach((n) => {
          const localDistance = distance + grid[n[0]][n[1]];
          const nHash = `${n[0]}_${n[1]}`;
          if (
            localDistance < (distances.get(nHash) || Number.POSITIVE_INFINITY)
          ) {
            distances.set(nHash, localDistance);
            heap.insert([nHash, localDistance]);
          }
        });
      }
      i++;
    }
  };

  const distances = new Map([["0_0", 0]]);
  dijkstra(distances, grid[0].length, grid.length, grid);

  return distances.get(`${grid.length - 1}_${grid[0].length - 1}`);
};

const enlargeGrid = (grid) => {
  let newGrid = [...grid.map((l) => [...l])];
  for (let j = 0; j < grid.length; j++) {
    let line = newGrid[j];
    for (let i = 1; i < 5; i++) {
      line = [...line, ...grid[j].map((c) => (c + i < 10 ? c + i : c + i - 9))];
    }
    newGrid[j] = line;

    for (let i = 1; i < 5; i++) {
      newGrid[i * grid.length + j] = line.map((c) =>
        c + i < 10 ? c + i : c + i - 9
      );
    }
  }

  return newGrid;
};

function parseInput(input) {
  return input
    .split("\n")
    .filter((line) => line.length)
    .map((l) => l.split("").map((c) => parseInt(c, 10)));
}

export function part1(input) {
  const grid = parseInput(input);
  return getLowRiskPath(grid);
}

export function part2(input) {
  const grid = parseInput(input);
  return getLowRiskPath(enlargeGrid(grid));
}
