import type { Rotation } from "./rotation";

export class Dial {
  private position = 50;
  private zPositions = 0;
  private zTransitions = 0;

  public get zeroPositions() {
    return this.zPositions;
  }

  public get zeroTransitions() {
    return this.zTransitions;
  }

  public turn(rotation: Rotation) {
    const ogPosition = this.position;
    const fullRevolutions = Math.floor(rotation.amount / 100);
    const lastAmount = rotation.amount % 100;

    this.zTransitions += fullRevolutions;

    if (rotation.direction === "R") {
      if (lastAmount > 100 - this.position) {
        this.zTransitions++;
      }

      this.position = (this.position + lastAmount) % 100;
    } else {
      this.position = (this.position - lastAmount) % 100;

      if (this.position < 0) {
        if (ogPosition !== 0) {
          this.zTransitions++;
        }
        this.position = 100 + this.position;
      }
    }

    if (this.position === 0) {
      this.zPositions++;
      this.zTransitions++;
    }
  }
}
