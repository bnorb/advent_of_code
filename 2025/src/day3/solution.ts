import { BatteryBank } from "./lib/bank";

const parseInput = (input: string): BatteryBank[] =>
  input
    .split("\n")
    .filter((line) => !!line)
    .map((line) => new BatteryBank(line.trim()));

export function part1(input: string): number {
  const batteryBanks = parseInput(input);

  return batteryBanks
    .map((bank) => bank.calcMaxJoltage(2))
    .reduce((sum, partialSum) => sum + partialSum, 0);
}

export function part2(input: string): number {
  const batteryBanks = parseInput(input);

  return batteryBanks
    .map((bank) => bank.calcMaxJoltage(12))
    .reduce((sum, partialSum) => sum + partialSum, 0);
}
