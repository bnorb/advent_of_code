import { readFileSync } from "fs";
import { Range } from "./range";

export const parseInput = (file: string): Range[] =>
  readFileSync(file, "utf-8")
    .split(",")
    .map((rangeStr) => new Range(rangeStr.trim()));
