type AdjMap = Record<string, string[]>;

function parseInput(input: string): AdjMap {
  return input
    .trimEnd()
    .split("\n")
    .map((line) => {
      const [from, to] = line.split(":");
      return [from!, to!.trim().split(" ")] satisfies [string, string[]];
    })
    .reduce((map, [from, to]) => ({ ...map, [from]: to }), {});
}

export function part1(input: string): number {
  const map = parseInput(input);
  return dfs("you", "out", map);
}

// after checking the data, it turns out that 0 paths lead from dac to fft
// this means that the only way to hit both is to go svr -> fft -> dac -> out
// so we can just multiply those path counts
export function part2(input: string): number {
  const map = parseInput(input);
  return (
    dfs("svr", "fft", map) * dfs("fft", "dac", map) * dfs("dac", "out", map)
  );
}

function dfs(
  curr: string,
  end: string,
  map: AdjMap,
  memo: Record<string, number> = {}
): number {
  if (curr === end) {
    return 1;
  }

  if (memo[curr] !== undefined) {
    return memo[curr];
  }

  const neighbors = map[curr];
  if (!neighbors?.length) {
    return 0;
  }

  let count = 0;
  for (let next of neighbors) {
    count += dfs(next, end, map, memo);
  }

  memo[curr] = count;

  return count;
}
