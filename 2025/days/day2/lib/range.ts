/**
 * I'm assuming that the ranges are "small", i.e. no more than 1 digit difference between min and max
 */
export class Range {
  private min: number;
  private max: number;
  private digits: number = -1;
  private subRanges?: [Range, Range];
  private invalidIDs: Set<number> = new Set();

  public constructor(min: number, max: number, digits: number);
  public constructor(str: string);
  public constructor(strOrMin: string | number, max?: number, digits?: number) {
    if (typeof strOrMin === "string") {
      const [min, max] = strOrMin.split("-");
      this.min = parseInt(min!, 10);
      this.max = parseInt(max!, 10);

      const minDigits = min!.length;
      const maxDigits = max!.length;
      const digitDiff = maxDigits - minDigits;

      if (digitDiff > 1) {
        throw new Error("wrong digit diff assumption");
      }

      if (digitDiff === 0) {
        this.digits = minDigits;
        return;
      }

      // needs subRanges
      const digitThreshold = Math.pow(10, minDigits);
      this.subRanges = [
        new Range(this.min, digitThreshold - 1, minDigits),
        new Range(digitThreshold, this.max, maxDigits),
      ];

      return;
    }

    this.min = strOrMin;
    this.max = max!;
    this.digits = digits!;
  }

  public getInvalidSum(all = false): number {
    this.reset();

    if (all) {
      this.findAllInvalidIDs();
    } else {
      this.findInvalidIDs();
    }

    return this.getSum();
  }

  private getSum(): number {
    if (this.subRanges) {
      return this.subRanges[0].getSum() + this.subRanges[1].getSum();
    }

    return [...this.invalidIDs].reduce((s, p) => s + p, 0);
  }

  private reset() {
    if (this.subRanges) {
      this.subRanges[0].reset();
      this.subRanges[1].reset();
      return;
    }

    this.invalidIDs.clear();
  }

  private findAllInvalidIDs(): void {
    if (this.subRanges) {
      this.subRanges[0].findAllInvalidIDs();
      this.subRanges[1].findAllInvalidIDs();
      return;
    }

    const halfDigits = Math.ceil(this.digits / 2);
    for (let d = halfDigits; d >= 1; d--) {
      this.findInvalidIDs(d);
    }
  }

  private findInvalidIDs(repeatingDigits?: number): void {
    if (this.subRanges) {
      this.subRanges[0].findInvalidIDs(repeatingDigits);
      this.subRanges[1].findInvalidIDs(repeatingDigits);
      return;
    }

    if (!repeatingDigits) {
      repeatingDigits = Math.ceil(this.digits / 2);
    }

    if (this.digits === 1 || this.digits % repeatingDigits !== 0) {
      return;
    }

    let invalidSum = 0;

    const calcCutoff = (repeatedPart: number): number => {
      return Array(repetitions - 1)
        .fill(repeatedPart)
        .map((val, index) => val * Math.pow(10, repeatingDigits * index))
        .reduce((sum, part) => sum + part, 0);
    };

    const repetitions = this.digits / repeatingDigits;
    const digitDivider = Math.pow(10, this.digits - repeatingDigits);
    const minFirstDigits = Math.floor(this.min / digitDivider);
    const maxFirstDigits = Math.floor(this.max / digitDivider);
    const minRestDigits = this.min % digitDivider;
    const maxRestDigits = this.max % digitDivider;
    const minCutoff = calcCutoff(minFirstDigits);
    const maxCutoff = calcCutoff(maxFirstDigits);

    if (minFirstDigits === maxFirstDigits) {
      // there can be only 1 or 0
      if (minRestDigits <= minCutoff && maxRestDigits >= maxCutoff) {
        this.invalidIDs.add(minFirstDigits * digitDivider + minCutoff);
      }

      return;
    }

    if (minRestDigits <= minCutoff) {
      invalidSum += minFirstDigits * digitDivider + minCutoff;
      this.invalidIDs.add(minFirstDigits * digitDivider + minCutoff);
    }

    if (maxRestDigits >= maxCutoff) {
      invalidSum += maxFirstDigits * digitDivider + maxCutoff;
      this.invalidIDs.add(maxFirstDigits * digitDivider + maxCutoff);
    }

    for (let fHalf = minFirstDigits + 1; fHalf < maxFirstDigits; fHalf++) {
      invalidSum += fHalf * digitDivider + calcCutoff(fHalf);
      this.invalidIDs.add(fHalf * digitDivider + calcCutoff(fHalf));
    }
  }
}
