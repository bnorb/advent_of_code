import { readFileSync } from "fs";
import { Rotation } from "./rotation";

export const parseInput = (file: string): Rotation[] =>
  readFileSync(file, "utf-8")
    .split("\n")
    .filter((line) => !!line)
    .map((line) => new Rotation(line));
