const countObviousValues = (data) => {
  const lengthSet = new Set([2, 4, 3, 7]);

  return data.reduce((count, line) => {
    let [_, digits] = line.split(" | ");
    digits = digits.split(" ");

    return count + digits.filter((d) => lengthSet.has(d.length)).length;
  }, 0);
};

const getOutputSum = (data) => {
  return data.reduce((sum, line) => {
    let [wires, output] = line.split(" | ");

    wires = wires.split(" ").map((w) => {
      const a = w.split("");
      a.sort();
      return a.join("");
    });
    output = output.split(" ").map((w) => {
      const a = w.split("");
      a.sort();
      return a.join("");
    });

    const lengthMap = wires.reduce((map, word) => {
      const lengthSet = map.get(word.length) || new Set();
      lengthSet.add(word);
      map.set(word.length, lengthSet);
      return map;
    }, new Map());

    const mapping = new Map([
      [1, Array.from(lengthMap.get(2))[0]],
      [4, Array.from(lengthMap.get(4))[0]],
      [7, Array.from(lengthMap.get(3))[0]],
      [8, Array.from(lengthMap.get(7))[0]],
    ]);

    const oneLetters = mapping.get(1).split("");
    // get 3
    mapping.set(
      3,
      Array.from(lengthMap.get(5)).filter((wiring) => {
        const letters = new Set(wiring.split(""));
        return letters.has(oneLetters[0]) && letters.has(oneLetters[1]);
      })[0]
    );
    lengthMap.get(5).delete(mapping.get(3));

    // get 9
    const threeLetters = mapping.get(3).split("");
    mapping.set(
      9,
      Array.from(lengthMap.get(6)).filter((wiring) => {
        const letters = new Set(wiring.split(""));
        return threeLetters.every((l) => letters.has(l));
      })[0]
    );

    lengthMap.get(6).delete(mapping.get(9));

    // get segment B
    const nineLetters = mapping.get(9).split("");
    const threeSet = new Set(threeLetters);
    const segmentB = nineLetters.filter((l) => !threeSet.has(l))[0];

    // get 5
    mapping.set(
      5,
      Array.from(lengthMap.get(5)).filter((wiring) => {
        const letters = new Set(wiring.split(""));
        return letters.has(segmentB);
      })[0]
    );
    lengthMap.get(5).delete(mapping.get(5));

    // get 2
    mapping.set(2, Array.from(lengthMap.get(5))[0]);

    // get segment C
    const twoSet = new Set(mapping.get(2));
    const segmentC = oneLetters.filter((l) => twoSet.has(l))[0];

    // get 6
    mapping.set(
      6,
      Array.from(lengthMap.get(6)).filter((wiring) => {
        const letters = new Set(wiring.split(""));
        return !letters.has(segmentC);
      })[0]
    );
    lengthMap.get(6).delete(mapping.get(6));

    // get 0
    mapping.set(0, Array.from(lengthMap.get(6))[0]);

    const flipped = new Map([...mapping].map((e) => [e[1], e[0]]));

    const number = parseInt(
      output.map((wiring) => flipped.get(wiring)).join(""),
      10
    );

    return sum + number;
  }, 0);
};

function parseInput(input) {
  return input.split("\n").filter((line) => line.length);
}

export function part1(input) {
  const data = parseInput(input);
  return countObviousValues(data);
}

export function part2(input) {
  const data = parseInput(input);
  return getOutputSum(data);
}
