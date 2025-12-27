function parseInput(input) {
  const smallCaves = new Set();
  const adjacencyMap = new Map();

  const addTransition = (from, to) => {
    if (from === "end" || to === "start") {
      return;
    }

    if (!adjacencyMap.has(from)) {
      adjacencyMap.set(from, []);
    }

    adjacencyMap.get(from).push(to);

    if (from !== "start" && from === from.toLowerCase()) {
      smallCaves.add(from);
    }
  };

  input
    .trimEnd()
    .split("\n")
    .forEach((line) => {
      const [cave1, cave2] = line.split("-");
      addTransition(cave1, cave2);
      addTransition(cave2, cave1);
    });

  return [adjacencyMap, smallCaves];
}

export function part1(input) {
  const [adjacencyMap, smallCaves] = parseInput(input);

  let counter = 0;
  const visited = new Set(["start"]);

  const dfs = (curr) => {
    if (curr === "end") {
      counter++;
      return;
    }

    if (!adjacencyMap.has(curr)) {
      return;
    }

    for (const next of adjacencyMap.get(curr).filter((n) => !visited.has(n))) {
      if (smallCaves.has(next)) {
        visited.add(next);
      }

      dfs(next);

      visited.delete(next);
    }
  };

  dfs("start");
  return counter;
}

export function part2(input) {
  const [adjacencyMap, smallCaves] = parseInput(input);

  let counter = 0;
  let canRepeat = true;
  const visited = new Set(["start"]);

  const dfs = (curr) => {
    if (curr === "end") {
      counter++;
      return;
    }

    if (!adjacencyMap.has(curr)) {
      return;
    }

    const neighbors = adjacencyMap
      .get(curr)
      .filter((n) => !visited.has(n) || canRepeat);

    for (const next of neighbors) {
      let didRepeat = false;
      if (smallCaves.has(next)) {
        if (visited.has(next)) {
          canRepeat = false;
          didRepeat = true;
        }
        visited.add(next);
      }

      dfs(next);

      if (didRepeat) {
        canRepeat = true;
      } else {
        visited.delete(next);
      }
    }
  };

  dfs("start");
  return counter;
}

const countPaths = (adjacencyMap, smallCaves) => {
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
