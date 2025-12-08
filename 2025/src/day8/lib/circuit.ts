export class Circuit {
  private static nextID = 1;

  public readonly id: number;
  private readonly _junktions: string[];

  public constructor(junktions: string[]) {
    this.id = Circuit.nextID;
    Circuit.nextID++;
    this._junktions = [...junktions];
  }

  public get junktions(): string[] {
    return [...this._junktions];
  }

  public get count(): number {
    return this._junktions.length;
  }

  public add(junktion: string) {
    this._junktions.push(junktion);
  }

  public merge(other: Circuit) {
    this._junktions.push(...other._junktions);
  }

  public cmp(other: Circuit): number {
    return this.count - other.count;
  }
}
