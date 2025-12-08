import type { Vec3D } from "./vec_3d";

export class Connection {
  public readonly distance: number;
  public readonly from: Vec3D;
  public readonly to: Vec3D;

  public constructor(from: Vec3D, to: Vec3D) {
    this.from = from;
    this.to = to;
    this.distance = from.distanceTo(to);
  }

  public cmp(other: Connection): number {
    return this.distance - other.distance;
  }
}
