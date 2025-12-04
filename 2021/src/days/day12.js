const buildAdjacencyMap = (adjacencies) => {
  const smallCaves = new Set();

  const adjacencyMap = adjacencies.reduce((map, line) => {
    const [nodeA, nodeB] = line.split("-");
    const listA = map.get(nodeA) || [];
    const listB = map.get(nodeB) || [];
    listA.push(nodeB);
    listB.push(nodeA);
    map.set(nodeA, listA);
    map.set(nodeB, listB);

    if (nodeA != "end" && nodeA == nodeA.toLowerCase()) {
      smallCaves.add(nodeA);
    }
    if (nodeB != "end" && nodeB == nodeB.toLowerCase()) {
      smallCaves.add(nodeB);
    }
    return map;
  }, new Map());

  return [adjacencyMap, smallCaves];
};

const countSmallCaveVisits = (adjacencies) => {
  const [adjacencyMap, smallCaves] = buildAdjacencyMap(adjacencies);

  let counter = 0;
  const stack = [["start", new Set(["start"])]];

  while (stack.length) {
    const current = stack.pop();

    if (current[0] == "end") {
      counter++;
      continue;
    }

    stack.push(
      ...adjacencyMap
        .get(current[0])
        .filter((node) => !current[1].has(node))
        .map((node) => {
          let set = new Set([...current[1]]);
          if (smallCaves.has(node)) {
            set.add(node);
          }
          return [node, set];
        })
    );
  }

  return counter;
};

const countPaths = (adjacencies) => {
  const [adjacencyMap, smallCaves] = buildAdjacencyMap(adjacencies);

  let counter = 0;

  const stack = [["start", new Set(["start"]), true]];

  while (stack.length) {
    const current = stack.pop();

    if (current[0] == "end") {
      counter++;
      continue;
    }

    stack.push(
      ...adjacencyMap
        .get(current[0])
        .filter((node) => {
          if (current[1].has(node)) {
            return current[2] && node != "start";
          }

          return true;
        })
        .map((node) => {
          let set = new Set([...current[1]]);
          const canRepeat = current[2] && !set.has(node);

          if (smallCaves.has(node)) {
            set.add(node);
          }
          return [node, set, canRepeat];
        })
    );
  }

  return counter;
};

function parseInput(input) {
  return input.split("\n").filter((input) => input.length);
}

export function part1(input) {
  const adjacencies = parseInput(input);
  return countSmallCaveVisits(adjacencies);
}

export function part2(input) {
  const adjacencies = parseInput(input);
  return countPaths(adjacencies);
}
