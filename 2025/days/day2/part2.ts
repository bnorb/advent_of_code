import { parseInput } from "./lib/parse";

const ranges = parseInput(`${__dirname}/input.txt`);

console.log(
  ranges
    .map((range) => range.getInvalidSum(true))
    .reduce((sum, partialSum) => sum + partialSum, 0)
);
