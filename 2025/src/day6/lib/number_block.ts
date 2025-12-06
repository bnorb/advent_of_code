export class NumberBlock {
  private numbers: Record<number, string> = {};

  public addDigits(row: string) {
    const digits = row.split("");
    digits.forEach((digit, index) => {
      if (digit === " ") {
        return;
      }

      this.numbers[index] = (this.numbers[index] ?? "").concat(digit);
    });
  }

  public getNumbers(): number[] {
    return Object.values(this.numbers).map((num) => parseInt(num, 10));
  }
}
