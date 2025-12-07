type Pos = [number, number];

export function part1(input: string): number {
  return findHitSplitters(input).size;
}

export function part2(input: string): number {
  const splitters = findHitSplitters(input);
  const lines = input.trimEnd().split("\n");
  const height = lines.length;
  const width = lines[0]!.length;
  const graph = buildGraph(splitters, width, height);

  return calculatePaths(graph);
}

function calculatePaths(graph: Map<number, number[]>): number {
  const cache = new Map<number, number>();
  const first = graph
    .keys()
    .reduce((min, curr) => Math.min(min, curr), Number.MAX_SAFE_INTEGER);

  const count = (curr: number): number => {
    if (cache.has(curr)) {
      return cache.get(curr)!;
    }

    const next = graph.get(curr)!;
    let sum = 0;

    switch (next.length) {
      case 0:
        sum = 2;
        break;
      case 1:
        sum += count(next[0]!) + 1;
        break;
      case 2:
        sum += count(next[0]!) + count(next[1]!);
    }

    cache.set(curr, sum);

    return sum;
  };

  return count(first);
}

function buildGraph(
  splitterSet: Set<number>,
  width: number,
  height: number
): Map<number, number[]> {
  const unhash = unhasher(width);
  const hash = hasher(width);

  return [...splitterSet].reduce((map, currHash) => {
    const pos = unhash(currHash);
    if (!map.has(currHash)) {
      map.set(currHash, []);
    }

    const leftCol = pos[1] - 1;
    const rightCol = pos[1] + 1;

    const list = map.get(currHash);

    let foundLeft = false;
    let foundRight = false;
    for (let row = pos[0] + 2; row < height; row += 2) {
      const left = hash([row, leftCol]);
      const right = hash([row, rightCol]);

      if (!foundLeft && splitterSet.has(left)) {
        list.push(left);
        foundLeft = true;
      }

      if (!foundRight && splitterSet.has(right)) {
        list.push(right);
        foundRight = true;
      }

      if (foundLeft && foundRight) {
        break;
      }
    }

    return map;
  }, new Map());
}

function unhasher(width: number): (hash: number) => Pos {
  return (hash: number): Pos => [
    Math.floor(hash / (width + 1)),
    hash % (width + 1),
  ];
}

function hasher(width: number): (pos: Pos) => number {
  return (pos: Pos): number => (width + 1) * pos[0] + pos[1];
}

function findHitSplitters(input: string): Set<number> {
  const splitters = new Set<number>();
  const lines = input.trimEnd().split("\n");
  const startPos = lines[0]!.split("").findIndex((char) => char === "S");
  const hash = hasher(lines[0]!.length);

  let tachyons: boolean[] = [true];
  let depth = 1;

  for (let row = 2; row < lines.length; row += 2) {
    const splitterLine = lines[row]!;

    tachyons.unshift(false); // expand tachyons
    tachyons.push(false);

    const nextTachyons = Array(tachyons.length).fill(false);

    for (let ti = 0, i = startPos - depth; i < startPos + depth; i++, ti++) {
      const s1 = splitterLine.charAt(i) === "^";
      const s0 = splitterLine.charAt(i + 1) === "^";

      const t1 = tachyons[ti];
      const t0 = tachyons[ti + 1];

      if (s1 && t1) {
        splitters.add(hash([row, i]));
      }

      // karnaugh table hell yeah
      const nt1 = (s0 && t0) || (!s1 && t1);
      const nt0 = (!s0 && t0) || (s1 && t1);

      nextTachyons[ti] = nextTachyons[ti] || nt1;
      nextTachyons[ti + 1] = nextTachyons[ti + 1] || nt0;
    }

    tachyons = nextTachyons;
    depth++;
  }

  return splitters;
}
