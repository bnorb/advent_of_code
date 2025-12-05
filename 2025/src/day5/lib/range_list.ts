import type { Range } from "./range";

export class RangeList {
  private ranges: Range[] = [];

  public addRange(newRange: Range): void {
    let index = 0;

    let i = 0;
    for (const range of this.ranges) {
      if (range.tryMerge(newRange)) {
        this.cascadeMerge();
        return;
      }

      // cannot be 0, that would've been merged
      if (range.compare(newRange) < 0) {
        index = i + 1;
      }

      i++;
    }

    this.ranges.splice(index, 0, newRange);
  }

  public countRangeSpans(): number {
    return this.ranges.reduce((sum, range) => sum + range.span, 0);
  }

  public includes(num: number): boolean {
    return this.ranges.some((range) => range.includes(num));
  }

  private cascadeMerge() {
    this.ranges.sort((a, b) => a.compare(b));
    let indexesToRemove = new Set<number>();

    for (let r1 = 0; r1 < this.ranges.length - 1; r1++) {
      if (indexesToRemove.has(r1)) {
        continue;
      }

      for (let r2 = r1 + 1; r2 < this.ranges.length; r2++) {
        if (this.ranges[r1]!.tryMerge(this.ranges[r2]!)) {
          indexesToRemove.add(r2);
        }
      }
    }

    if (indexesToRemove.size > 0) {
      this.ranges = this.ranges.reduce(
        (newList, range, index) =>
          indexesToRemove.has(index) ? newList : [...newList, range],
        [] as Range[]
      );
      this.cascadeMerge();
    }
  }
}
