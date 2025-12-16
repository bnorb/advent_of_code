import { ConstraintType, SimplexSolver, VariableType, type Constraint, type Solution, type Variable } from "./simplex";

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

  public findJoltagePresses(): number {
    const objective = Array(this.buttons.length).fill(1)
    const constraints: Constraint[] = this.desiredJoltage.map((joltage, rowIndex) => ({
      coefficients: this.buttons.map(b => b.includes(rowIndex) ? 1 : 0),
      rhs: joltage,
      type: ConstraintType.EQ
    }))

    const solver = new SimplexSolver(objective, constraints, true)
    const solution = solver.solve()

    if (this.isIntegerSolution(solution)) {
      return this.getSum(solution)
    }

    return this.findIntegerSolution(solution, objective, constraints)
  }

  private findIntegerSolution(currentSolution: Solution, objective: number[], currentConstraints: Constraint[]): number {
    const epsilon = 0.0000001

    const maxDecimalIndex = currentSolution.basis
      .map((b, i) => [b, i] as [Variable, number])
      .filter(([b]) => b.type === VariableType.Regular)
      .map(([_, i]) => [currentSolution.rhs[i]!, i])
      .filter(([v]) => Math.abs(Math.round(v!) - v!) > epsilon) // get rid of ints with float errors
      .map(([v, i]) => [v! - Math.trunc(v!), i!])
      .reduce(([max, maxIndex], [v, i]) => v! > max! ? [v!, i!] : [max!, maxIndex!], [0, -1])[1]!

    const branchVar = currentSolution.basis[maxDecimalIndex]!
    const branches = [
      { type: ConstraintType.LTE, rhs: Math.floor(currentSolution.rhs[maxDecimalIndex]!) },
      { type: ConstraintType.GTE, rhs: Math.ceil(currentSolution.rhs[maxDecimalIndex]!) }
    ]

    let results: number[] = []
    for (const { type, rhs } of branches) {
      let newConstraint: Constraint = {
        type,
        rhs,
        coefficients: Array(objective.length).fill(0)
      }
      newConstraint.coefficients[branchVar.index]! = 1
      const newConstraints = [...currentConstraints, newConstraint]

      const solver = new SimplexSolver(objective, newConstraints, true)

      let newSolution: Solution
      try {
        newSolution = solver.solve()
      } catch {
        // no solution, not continuing on this branch
        continue;
      }

      if (this.isIntegerSolution(newSolution)) {
        results.push(this.getSum(newSolution))
        continue
      }

      // need to explore further branches
      results.push(this.findIntegerSolution(newSolution, objective, newConstraints))
    }

    if (!results.length) {
      return Number.MAX_SAFE_INTEGER
    }

    return results.reduce((min, v) => Math.min(min, v))
  }

  private isIntegerSolution(solution: Solution): boolean {
    const epsilon = 0.0000001
    return solution.rhs.every(v => Math.abs(Math.round(v) - v) < epsilon)
  }

  private getSum(solution: Solution): number {
    return -1 * solution.basis.reduce((sum, v, index) => sum + v.coefficient * Math.round(solution.rhs[index]!), 0)
  }
}
