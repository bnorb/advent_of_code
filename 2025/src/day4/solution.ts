import { Grid } from "./lib/grid";

export function part1(input: string): number {
  const grid = new Grid(input);
  return grid.countAccessible();
}

export function part2(input: string): number {
  const grid = new Grid(input);
  return grid.countRemovals();
}
