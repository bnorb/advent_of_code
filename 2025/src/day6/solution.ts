import { NumberBlock } from "./lib/number_block";

const parseInputByRow = (input: string): [string[][], string[]] => {
  const lines = input.trim().split("\n");
  const operators = lines.pop()!.split(/\s+/);

  return [lines.map((line) => line.split(/\s+/)), operators];
};

const parseInputByColumn = (input: string): [NumberBlock[], string[]] => {
  const lines = input.trimEnd().split("\n");
  const operatorLine = lines.pop()!;
  const operators: string[] = [];

  // use the operator positions to find block boundaries
  const operatorPositions: number[] = [];
  let pos = 0;
  for (let char of operatorLine) {
    if (char !== " ") {
      operatorPositions.push(pos);
      operators.push(char);
    }

    pos++;
  }

  const blocks: NumberBlock[] = Array(operators.length)
    .fill(0)
    .map((_) => new NumberBlock());

  lines.forEach((line) => {
    for (let i = 0; i < operatorPositions.length; i++) {
      const startPos = operatorPositions[i]!;
      let endPos = operatorPositions[i + 1];
      if (endPos) {
        endPos--;
      }

      const digitRow = line.substring(startPos, endPos);
      blocks[i]!.addDigits(digitRow);
    }
  });

  return [blocks, operators];
};

export function part1(input: string): number {
  const [numbers, operators] = parseInputByRow(input);

  const results: number[] = numbers
    .pop()!
    .map((number) => parseInt(number, 10));

  while (numbers.length > 0) {
    const row = numbers.pop()!;

    for (let i in operators) {
      const operator = operators[i];
      const acc = results[i];

      results[i] = eval(`${acc} ${operator} ${row[i]}`);
    }
  }

  return results.reduce((sum, part) => sum + part, 0);
}

export function part2(input: string): number {
  const [blocks, operators] = parseInputByColumn(input);
  const results: number[] = [];

  for (let i in operators) {
    const operator = operators[i];
    const numbers = blocks[i]!.getNumbers();
    let blockResult = numbers.pop()!;

    while (numbers.length > 0) {
      const number = numbers.pop()!;
      blockResult = eval(`${blockResult} ${operator} ${number}`);
    }

    results.push(blockResult);
  }

  return results.reduce((sum, part) => sum + part, 0);
}
