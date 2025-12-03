export class BatteryBank {
  private batteries: number[];

  public constructor(line: string) {
    this.batteries = line.split("").map((battery) => parseInt(battery, 10));
  }

  public calcMaxJoltage(
    digitsLeft: number,
    startingPos = 0,
    digits: number[] = []
  ): number {
    if (digitsLeft < 1) {
      return digits
        .toReversed()
        .reduce((num, digit, index) => num + digit * Math.pow(10, index), 0);
    }

    const [maxDigit, maxDigitIndex] = this.batteries
      .slice(startingPos, this.batteries.length - digitsLeft + 1)
      .reduce(
        ([max, maxIndex], current, index) =>
          current > max ? [current, index] : [max, maxIndex],
        [0, -1]
      );

    digits.push(maxDigit);
    return this.calcMaxJoltage(
      digitsLeft - 1,
      startingPos + maxDigitIndex + 1,
      digits
    );
  }
}
