import { Machine } from "./lib/machine";

function parseInput(input: string): Machine[] {
  return input
    .trimEnd()
    .split("\n")
    .map((line) => new Machine(line));
}

export function part1(input: string): number {
  return parseInput(input).reduce(
    (sum, machine) => sum + machine.findMinInit(),
    0
  );
}

export function part2(input: string): number {
  return parseInput(input).reduce(
    (sum, machine) => sum + machine.findJoltagePresses(),
    0
  );
}
