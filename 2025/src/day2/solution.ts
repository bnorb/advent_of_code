import { Range } from "./lib/range";

const parseInput = (input: string): Range[] =>
  input.split(",").map((rangeStr) => new Range(rangeStr.trim()));

export function part1(input: string): number {
  const ranges = parseInput(input);

  return ranges
    .map((range) => range.getInvalidSum())
    .reduce((sum, partialSum) => sum + partialSum, 0);
}

export function part2(input: string): number {
  const ranges = parseInput(input);

  return ranges
    .map((range) => range.getInvalidSum(true))
    .reduce((sum, partialSum) => sum + partialSum, 0);
}
