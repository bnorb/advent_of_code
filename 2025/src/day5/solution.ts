import { Range } from "./lib/range";
import { RangeList } from "./lib/range_list";

const parseInput = (input: string): [Range[], number[]] => {
  const [ranges, nums] = input.split("\n\n");

  return [
    ranges!
      .split("\n")
      .filter((line) => line.length)
      .map((line) => new Range(line)),
    nums!
      .split("\n")
      .filter((line) => line.length)
      .map((line) => parseInt(line, 10)),
  ];
};

export function part1(input: string): number {
  const [ranges, nums] = parseInput(input);
  const rangeList = new RangeList();

  ranges.forEach((range) => {
    rangeList.addRange(range);
  });

  return nums.filter((num) => rangeList.includes(num)).length;
}

export function part2(input: string): number {
  const [ranges] = parseInput(input);
  const rangeList = new RangeList();

  ranges.forEach((range) => {
    rangeList.addRange(range);
  });

  return rangeList.countRangeSpans();
}
