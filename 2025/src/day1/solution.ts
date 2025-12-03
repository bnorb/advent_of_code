import { Dial } from "./lib/dial";
import { Rotation } from "./lib/rotation";

const parseInput = (input: string): Rotation[] =>
  input
    .split("\n")
    .filter((line) => !!line)
    .map((line) => new Rotation(line));

export function part1(input: string): number {
  const rotations = parseInput(input);
  const dial = new Dial();

  rotations.forEach((rotation) => dial.turn(rotation));

  return dial.zeroPositions;
}

export function part2(input: string): number {
  const rotations = parseInput(input);
  const dial = new Dial();

  rotations.forEach((rotation) => dial.turn(rotation));

  return dial.zeroTransitions;
}
