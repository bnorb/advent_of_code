export class Rotation {
  public readonly direction: "L" | "R";
  public readonly amount: number;

  public constructor(line: string) {
    const direction = line.substring(0, 1);
    if (direction !== "L" && direction !== "R") {
      throw new Error("invalid direction letter");
    }

    this.direction = direction;
    this.amount = parseInt(line.substring(1), 10);
  }
}
