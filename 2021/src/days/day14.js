const calcMostLeastCommonDiff = (startingPoint, instructions, n) => {
  const pairCounts = new Map();
  const elementCounts = new Map();

  elementCounts.set(startingPoint[0], 1);

  for (let i = 1; i < startingPoint.length; i++) {
    const pair = `${startingPoint[i - 1]}${startingPoint[i]}`;
    pairCounts.set(pair, (pairCounts.get(pair) || 0) + 1);
    elementCounts.set(
      startingPoint[i],
      (elementCounts.get(startingPoint[i]) || 0) + 1
    );
  }

  for (let i = 0; i < n; i++) {
    const newPairCounts = new Map();
    const newElementCounts = new Map();

    instructions.forEach((inst) => {
      const [pair, newElement] = inst;
      if (!pairCounts.has(pair)) {
        return;
      }

      const currentPairCount = pairCounts.get(pair);
      newPairCounts.set(
        pair,
        (newPairCounts.get(pair) || 0) - currentPairCount
      );

      [
        `${pair.charAt(0)}${newElement}`,
        `${newElement}${pair.charAt(1)}`,
      ].forEach((p) => {
        newPairCounts.set(p, (newPairCounts.get(p) || 0) + currentPairCount);
      });

      newElementCounts.set(
        newElement,
        (newElementCounts.get(newElement) || 0) + currentPairCount
      );
    });

    for (let [pair, count] of newPairCounts) {
      pairCounts.set(pair, (pairCounts.get(pair) || 0) + count);
    }

    for (let [element, count] of newElementCounts) {
      elementCounts.set(element, (elementCounts.get(element) || 0) + count);
    }
  }

  const minMax = [...elementCounts.values()].reduce(
    (minMax, ec) => {
      if (ec > minMax.max) minMax.max = ec;
      if (ec < minMax.min) minMax.min = ec;
      return minMax;
    },
    { min: Number.MAX_SAFE_INTEGER, max: 0 }
  );

  return minMax.max - minMax.min;
};

function parseInput(input) {
  const data = input.split("\n\n");

  const startingPoint = data.shift().split("");
  const instructions = data[0].split("\n").map((i) => i.split(" -> "));
  return [startingPoint, instructions];
}

export function part1(input) {
  const [startingPoint, instructions] = parseInput(input);
  return calcMostLeastCommonDiff(startingPoint, instructions, 10);
}

export function part2(input) {
  const [startingPoint, instructions] = parseInput(input);
  return calcMostLeastCommonDiff(startingPoint, instructions, 40);
}
