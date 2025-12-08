export class Vec3D {
  public readonly x: number;
  public readonly y: number;
  public readonly z: number;

  public static parse(line: string): Vec3D {
    const [x, y, z] = line.split(",").map((num) => parseInt(num, 10));
    return new Vec3D(x!, y!, z!);
  }

  public get length(): number {
    return Math.abs(Math.sqrt(this.x ** 2 + this.y ** 2 + this.z ** 2));
  }

  public constructor(x: number, y: number, z: number) {
    this.x = x;
    this.y = y;
    this.z = z;
  }

  public distanceTo(other: Vec3D): number {
    const diff = new Vec3D(
      other.x - this.x,
      other.y - this.y,
      other.z - this.z
    );

    return diff.length;
  }

  public toString(): string {
    return `${this.x}.${this.y}.${this.z}`;
  }
}
