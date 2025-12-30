class MinHeap {
  constructor() {
    this.heap = [];
  }

  _swap(indexA, indexB) {
    const a = this.heap[indexA];
    this.heap[indexA] = this.heap[indexB];
    this.heap[indexB] = a;
  }

  size() {
    return this.heap.length;
  }

  insert(node) {
    this.heap.push(node);

    if (this.heap.length === 1) {
      return; // nothing to do
    }

    let currIndex = this.heap.length - 1;
    let parentIndex = Math.floor((currIndex - 1) / 2);

    while (currIndex > 0 && this.heap[parentIndex].v > this.heap[currIndex].v) {
      this._swap(currIndex, parentIndex);
      currIndex = parentIndex;
      parentIndex = Math.floor((currIndex - 1) / 2);
    }
  }

  pop() {
    if (this.heap.length < 1) {
      return undefined;
    }

    const min = this.heap[0];
    const last = this.heap.pop();

    if (this.heap.length === 0) {
      return min;
    }

    let currIndex = 0;
    this.heap[currIndex] = last;
    while (true) {
      let leftIndex = 2 * currIndex + 1;
      let rigthIndex = 2 * currIndex + 2;

      let smallest = currIndex;
      if (
        leftIndex < this.heap.length &&
        this.heap[leftIndex].v < this.heap[smallest].v
      ) {
        smallest = leftIndex;
      }

      if (
        rigthIndex < this.heap.length &&
        this.heap[rigthIndex].v < this.heap[smallest].v
      ) {
        smallest = rigthIndex;
      }

      if (smallest === currIndex) {
        break;
      }

      this._swap(currIndex, smallest);
      currIndex = smallest;
    }

    return min;
  }
}

const getLowRiskPath = (grid) => {
  const WIDTH = grid[0].length;
  const HEIGHT = grid.length;

  const getNeighbors = ([x, y]) => {
    const n = [
      [x - 1, y],
      [x + 1, y],
      [x, y - 1],
      [x, y + 1],
    ];

    return n.filter(
      (point) =>
        point[0] < HEIGHT && point[0] >= 0 && point[1] < WIDTH && point[1] >= 0
    );
  };

  const hash = ([r, c]) => r * (WIDTH + 1) + c;
  const heuristic = ([r, c]) => WIDTH - (c + 1) + HEIGHT - (r + 1);

  const aStar = () => {
    const cameFrom = new Map();
    const buildPath = () => {
      const path = [];
      let curr = [HEIGHT - 1, WIDTH - 1];
      let h = hash(curr);
      while (cameFrom.has(h)) {
        path.push([...curr]);
        curr = cameFrom.get(h);
        h = hash(curr);
      }

      return path.reverse();
    };

    const open = new MinHeap();
    const visited = new Set();
    const fMap = new Map();
    const gMap = new Map();
    open.insert({ d: [0, 0], v: 0 });
    gMap.set(hash([0, 0]), 0);
    fMap.set(hash([0, 0]), heuristic([0, 0]));

    while (open.size() > 0) {
      const node = open.pop();
      const curr = node.d;
      if (curr[0] === HEIGHT - 1 && curr[1] === WIDTH - 1) {
        return buildPath();
      }

      const currHash = hash(curr);
      visited.add(currHash);

      for (const n of getNeighbors(curr)) {
        const nHash = hash(n);

        if (visited.has(nHash)) {
          continue;
        }

        const g = gMap.get(currHash) + grid[n[0]][n[1]];
        if (g >= gMap.get(nHash) ?? Number.MAX_SAFE_INTEGER) {
          continue;
        }

        const h = heuristic(n);
        gMap.set(nHash, g);
        fMap.set(nHash, g + h);
        cameFrom.set(nHash, curr);

        open.insert({ d: n, v: g + h });
      }
    }
  };

  const path = aStar();
  return path.reduce((s, [r, c]) => s + grid[r][c], 0);
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
