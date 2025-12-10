export enum CornerType {
  Inner,
  Outer,
}

export enum CornerOrientation {
  UpperLeft,
  UpperRight,
  LowerRight,
  LowerLeft,
}

export type Sign = -1 | 1;

export class Corner {
  public readonly x: number;
  public readonly y: number;
  private _type?: CornerType;
  private _orientation?: CornerOrientation;

  public static parse(line: string): Corner {
    const [x, y] = line.split(",").map((num) => parseInt(num, 10));
    return new Corner(x!, y!);
  }

  public constructor(x: number, y: number) {
    this.x = x;
    this.y = y;
  }

  public get type() {
    return this._type;
  }

  public get orientation() {
    return this._orientation;
  }

  public vectorTo(other: Corner): [number, number] {
    return [other.x - this.x, other.y - this.y];
  }

  public calcData(previous: Corner, next: Corner) {
    if (this.y === previous.y) {
      // horizontal, next is vertical sign is same on outer corner
      const incoming = Math.sign(this.x - previous.x) as Sign;
      const outgoing = Math.sign(next.y - this.y) as Sign;

      if (incoming === outgoing) {
        this._type = CornerType.Outer;
        this._orientation =
          incoming === 1
            ? CornerOrientation.UpperRight
            : CornerOrientation.LowerLeft;
      } else {
        this._type = CornerType.Inner;
        this._orientation =
          incoming === 1
            ? CornerOrientation.LowerRight
            : CornerOrientation.UpperLeft;
      }
    } else {
      // vertical, next is horizontal sign is different on outer corner
      const incoming = Math.sign(this.y - previous.y) as Sign;
      const outgoing = Math.sign(next.x - this.x) as Sign;

      if (incoming === outgoing) {
        this._type = CornerType.Inner;
        this._orientation =
          incoming === 1
            ? CornerOrientation.LowerLeft
            : CornerOrientation.UpperRight;
      } else {
        this._type = CornerType.Outer;
        this._orientation =
          incoming === 1
            ? CornerOrientation.LowerRight
            : CornerOrientation.UpperLeft;
      }
    }
  }
}
