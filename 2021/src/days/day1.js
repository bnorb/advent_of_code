const countIncreased = (depths) => {
  let last = [...depths].shift();
  let counter = 0;

  depths.forEach((depth) => {
    if (depth > last) {
      counter++;
    }

    last = depth;
  });

  return counter;
};

const countWindowIncreased = (depths) => {
  const sum = (sum, e) => sum + e;

  let lastSum = depths.slice(0, 3).reduce(sum, 0);
  let counter = 0;

  for (let i = 3; i < depths.length; i++) {
    const currentSum = depths.slice(i - 2, i + 1).reduce(sum, 0);
    if (currentSum > lastSum) {
      counter++;
    }

    lastSum = currentSum;
  }

  return counter;
};

const parseInput = (input) => input.split("\n").map((c) => parseInt(c, 10));

export function part1(input) {
  const depths = parseInput(input);
  return countIncreased(depths);
}

export function part2(input) {
  const depths = parseInput(input);
  return countWindowIncreased(depths);
}
