export class Range {
  private start: number;
  private end: number;

  public get limits(): [number, number] {
    return [this.start, this.end];
  }

  public get span(): number {
    return this.end - this.start + 1;
  }

  public constructor(line: string) {
    const [start, end] = line.split("-").map((part) => parseInt(part, 10));
    this.start = start!;
    this.end = end!;
  }

  public tryMerge(other: Range): boolean {
    const [otherStart, otherEnd] = other.limits;
    if (!this.doesOverlap(otherStart, otherEnd)) {
      return false;
    }

    this.start = Math.min(this.start, otherStart);
    this.end = Math.max(this.end, otherEnd);

    return true;
  }

  public includes(num: number): boolean {
    return this.start <= num && this.end >= num;
  }

  public compare(other: Range): number {
    const [otherStart, otherEnd] = other.limits;

    const startDiff = this.start - otherStart;
    if (startDiff !== 0) {
      return startDiff;
    }

    return this.end - otherEnd;
  }

  private doesOverlap(otherStart: number, otherEnd: number): boolean {
    return this.start <= otherEnd && this.end >= otherStart;
  }
}
