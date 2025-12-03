import { readFileSync } from "fs";
import { BatteryBank } from "./bank";

export const parseInput = (file: string): BatteryBank[] =>
  readFileSync(file, "utf-8")
    .split("\n")
    .filter((line) => !!line)
    .map((line) => new BatteryBank(line.trim()));
