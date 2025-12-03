import { Dial } from "./lib/dial";
import { parseInput } from "./lib/parse";

const rotations = parseInput(`${__dirname}/input.txt`);
const dial = new Dial();

rotations.forEach((rotation) => dial.turn(rotation));

console.log(dial.zeroTransitions);
