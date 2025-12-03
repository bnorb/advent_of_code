import { parseInput } from "./lib/parse";

const batteryBanks = parseInput(`${__dirname}/input.txt`);

console.log(
  batteryBanks
    .map((bank) => bank.calcMaxJoltage(2))
    .reduce((sum, partialSum) => sum + partialSum, 0)
);
