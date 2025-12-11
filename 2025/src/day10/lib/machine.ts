export class Machine {
  private readonly desiredLights: boolean[];
  private readonly buttons: number[][];
  private readonly desiredJoltage: number[];

  private static lightRe = /\[([.#]+)\]/;
  private static buttonRe = /\] ([(),\d ]+) \{/;
  private static joltageRe = /\{([\d,]+)\}/;

  public constructor(line: string) {
    this.desiredLights = Machine.lightRe
      .exec(line)?.[1]!
      .split("")
      .map((c) => c === "#")!;

    this.buttons = Machine.buttonRe
      .exec(line)?.[1]!
      .split(" ")
      .map((part) =>
        part
          .substring(1, part.length - 1)
          .split(",")
          .map((num) => parseInt(num, 10))
      )!;

    this.desiredJoltage = Machine.joltageRe
      .exec(line)?.[1]!
      .split(",")
      .map((num) => parseInt(num, 10))!;
  }

  public findMinInit(): number {
    const hash = (lights: boolean[]): number =>
      lights.reduce(
        (h, state, index) => h + Number(state) * Math.pow(2, index),
        0
      );

    const pressButton = (lights: boolean[], button: number[]): boolean[] => {
      let buttonIdx = 0;

      return lights.map((state, index) => {
        if (buttonIdx < button.length && index === button[buttonIdx]) {
          buttonIdx++;
          return !state;
        }

        return state;
      });
    };

    const isTarget = (lights: boolean[]): boolean => {
      return lights.every(
        (state, index) => state === this.desiredLights[index]
      );
    };

    const start = Array(this.desiredLights.length).fill(false);
    const q: [boolean[], number][] = [[start, 0]];
    const seen = new Set([hash(start)]);

    while (q.length > 0) {
      const [lights, buttonPresses] = q.shift()!;

      for (let button of this.buttons) {
        const newLights = pressButton(lights, button);
        const h = hash(newLights);

        if (seen.has(h)) {
          continue;
        }

        seen.add(h);

        if (isTarget(newLights)) {
          return buttonPresses + 1;
        }

        q.push([newLights, buttonPresses + 1]);
      }
    }

    return -1;
  }

  // not good
  public findJoltagePresses(): number {
    const maxJoltage = Math.max(...this.desiredJoltage);
    const hash = (joltage: number[]): number =>
      joltage.reduce(
        (h, count, index) => h + count * Math.pow(maxJoltage + 1, index),
        0
      );

    const pressButton = (joltage: number[], button: number[]): number[] => {
      let buttonIdx = 0;

      return joltage.map((count, index) => {
        if (buttonIdx < button.length && index === button[buttonIdx]) {
          buttonIdx++;
          return count + 1;
        }

        return count;
      });
    };

    const isTarget = (joltage: number[]): boolean => {
      return joltage.every(
        (count, index) => count === this.desiredJoltage[index]
      );
    };

    const filterButtons = (
      joltage: number[],
      buttons: number[][]
    ): number[][] => {
      let usableButtons = [...buttons];
      joltage.forEach((count, index) => {
        if (count < this.desiredJoltage[index]!) {
          return;
        }

        usableButtons = usableButtons.filter(
          (targets) => !targets.some((t) => t === index)
        );
      });

      return usableButtons;
    };

    const start = Array(this.desiredJoltage.length).fill(0);
    const q: [number[], number, number[][]][] = [[start, 0, [...this.buttons]]];
    const seen = new Set([hash(start)]);

    let safety = 0;
    while (q.length > 0) {
      const [joltage, buttonPresses, usableButtons] = q.shift()!;
      if (safety++ > 100) {
        return -1;
      }

      for (let button of usableButtons) {
        const newJoltage = pressButton(joltage, button);
        const h = hash(newJoltage);

        if (seen.has(h)) {
          continue;
        }

        console.log(
          `${[joltage, buttonPresses]} + ${button} -> ${[
            newJoltage,
            buttonPresses + 1,
          ]}`
        );
        seen.add(h);

        if (isTarget(newJoltage)) {
          console.log(buttonPresses + 1);
          return buttonPresses + 1;
        }

        q.push([
          newJoltage,
          buttonPresses + 1,
          filterButtons(newJoltage, usableButtons),
        ]);
      }
    }

    return -1;
  }
}
