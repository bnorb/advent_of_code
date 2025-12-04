const endSet = new Set(["]", "}", ">", ")"]);

const startEndMap = {
  "[": "]",
  "{": "}",
  "<": ">",
  "(": ")",
};

const scores = {
  "(": 1,
  "[": 2,
  "{": 3,
  "<": 4,
};

const calculateSyntaxErrorScore = (lines) => {
  const invalidClosingCharacters = lines.reduce(
    (map, line) => {
      const stack = [];
      const lineArr = line.split("");
      for (let i = 0; i < lineArr.length; i++) {
        if (endSet.has(lineArr[i])) {
          const lastStart = stack.pop();
          if (startEndMap[lastStart] != lineArr[i]) {
            map[lineArr[i]]++;
            break;
          }
        } else {
          stack.push(lineArr[i]);
        }
      }

      return map;
    },
    {
      "]": 0,
      "}": 0,
      ">": 0,
      ")": 0,
    }
  );

  return (
    invalidClosingCharacters[")"] * 3 +
    invalidClosingCharacters["]"] * 57 +
    invalidClosingCharacters["}"] * 1197 +
    invalidClosingCharacters[">"] * 25137
  );
};

const calculateIncompleteScore = (lines) => {
  const stacks = lines.reduce((arr, line) => {
    const stack = [];
    const lineArr = line.split("");
    let corrupt = false;
    for (let i = 0; i < lineArr.length; i++) {
      if (endSet.has(lineArr[i])) {
        const lastStart = stack.pop();
        if (startEndMap[lastStart] != lineArr[i]) {
          corrupt = true;
          break;
        }
      } else {
        stack.push(lineArr[i]);
      }
    }

    if (!corrupt) {
      arr.push(stack);
    }
    return arr;
  }, []);

  const sums = stacks.map((stack) => {
    let sum = 0;
    for (let i = stack.length - 1; i >= 0; i--) {
      sum *= 5;
      sum += scores[stack[i]];
    }
    return sum;
  });

  sums.sort((a, b) => b - a);
  return sums[Math.floor(sums.length / 2)];
};

function parseInput(input) {
  return input.split("\n").filter((line) => line.length);
}

export function part1(input) {
  const lines = parseInput(input);
  return calculateSyntaxErrorScore(lines);
}

export function part2(input) {
  const lines = parseInput(input);
  return calculateIncompleteScore(lines);
}
