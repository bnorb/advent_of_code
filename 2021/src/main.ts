import { readFileSync } from "fs";
import path from "path";

const args = process.argv.slice(2);

if (args.length != 2) {
  throw new Error("Missing arguments");
}

const day = parseInt(args[0]!, 10);
const part = parseInt(args[1]!, 10);

if (day < 1 || day > 25) {
  throw new Error("Invalid day");
}

if (part !== 1 && part !== 2) {
  throw new Error("Invalid part");
}

const input = readFileSync(
  path.join(__dirname, `../input/day${day}.txt`),
  "utf-8"
);
const { part1, part2 } = await import(`./days/day${day}.js`);

let result: any;
if (part === 1) {
  result = part1(input);
} else {
  result = part2(input);
}

if (result !== undefined) {
  console.log(result);
}
