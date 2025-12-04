type Step = -1 | 0 | 1;
type Position = {
  r: number;
  c: number;
};

export class Grid {
  private static readonly DIRECTIONS: [Step, Step][] = [
    [-1, -1],
    [-1, 0],
    [-1, 1],
    [0, -1],
    [0, 1],
    [1, -1],
    [1, 0],
    [1, 1],
  ];

  private readonly rows: number;
  private readonly columns: number;
  private readonly cells: boolean[][]; // true - paper, false - empty
  private accessibleRolls?: Position[];

  public constructor(input: string) {
    this.cells = [];
    input.split("\n").forEach((line) => {
      if (!line.length) {
        return;
      }

      const row = line.split("").map((char) => char === "@");
      this.cells.push(row);
    });

    this.rows = this.cells.length;
    this.columns = this.cells[0]!.length;
  }

  public countAccessible(): number {
    if (this.accessibleRolls) {
      return this.accessibleRolls.length;
    }

    this.findAccessible();

    return this.accessibleRolls!.length;
  }

  public countRemovals(): number {
    this.findAccessible();
    return this.doRemovals();
  }

  private doRemovals(removed = 0): number {
    removed += this.accessibleRolls!.length;

    const candidates = new Map<string, Position>();
    this.accessibleRolls!.forEach(({ r, c }) => {
      this.cells[r]![c] = false;
    });

    this.accessibleRolls!.forEach(({ r, c }) => {
      this.getNeighbors(r, c)
        .filter(({ r, c }) => this.cells[r]![c]!)
        .forEach((pos) => {
          const hash = `${pos.r}_${pos.c}`;
          if (candidates.has(hash)) {
            return;
          }
          candidates.set(hash, pos);
        });
    });

    // console.log({ accesible: this.accessibleRolls, candidates });

    if (candidates.size === 0) {
      return removed;
    }

    this.findAccessible([...candidates.values()]);

    if (!this.accessibleRolls!.length) {
      return removed;
    }

    return this.doRemovals(removed);
  }

  private findAccessible(candidates?: Position[]) {
    if (!this.accessibleRolls) {
      this.accessibleRolls = [];
    }

    this.accessibleRolls.length = 0;

    const checkCell = (
      occupied: boolean,
      rowIndex: number,
      colIndex: number
    ) => {
      if (!occupied) {
        return;
      }

      const occupiedNeighbors = this.getNeighbors(rowIndex, colIndex).reduce(
        (occupied, { r, c }) => occupied + (this.cells[r]![c] ? 1 : 0),
        0
      );

      if (occupiedNeighbors < 4) {
        this.accessibleRolls!.push({ r: rowIndex, c: colIndex });
      }
    };

    if (candidates && candidates.length) {
      candidates.forEach(({ r, c }) => checkCell(this.cells[r]![c]!, r, c));
      return;
    }

    this.cells.forEach((row, rowIndex) =>
      row.forEach((cell, colIndex) => checkCell(cell, rowIndex, colIndex))
    );
  }

  private getNeighbors(rowIndex: number, colIndex: number): Position[] {
    return Grid.DIRECTIONS.map(([rowStep, colStep]) => ({
      r: rowIndex + rowStep,
      c: colIndex + colStep,
    })).filter(this.validPosition.bind(this));
  }

  private validPosition({ r, c }: Position): boolean {
    return r >= 0 && r < this.rows && c >= 0 && c < this.columns;
  }
}
