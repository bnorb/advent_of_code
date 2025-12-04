class Quaternion {
  w;
  i;
  j;
  k;

  static rotationCache = new Map();

  static fromPoint(point) {
    const q = new Quaternion();
    const [i, j, k] = point;
    q.w = 0;
    q.i = i;
    q.j = j;
    q.k = k;

    return q;
  }

  static getRotationQuaternions(axis, degree) {
    const [i, j, k] = axis;
    const hash = `${i}|${j}|${k}|${degree}`;

    if (this.rotationCache.has(hash)) {
      return this.rotationCache.get(hash);
    }

    const radian = (Math.PI * degree) / 180;

    const q = new Quaternion();
    const qi = new Quaternion();

    const sin = Math.sin(radian / 2);
    const cos = Math.cos(radian / 2);
    q.w = cos;
    q.i = sin * i;
    q.j = sin * j;
    q.k = sin * k;

    qi.w = cos;
    qi.i = -sin * i;
    qi.j = -sin * j;
    qi.k = -sin * k;

    this.rotationCache.set(hash, [q, qi]);
    return [q, qi];
  }

  toArray() {
    return [this.w, this.i, this.j, this.k];
  }

  toPoint() {
    return [this.i, this.j, this.k];
  }

  round() {
    this.w = Math.round(this.w);
    this.i = Math.round(this.i);
    this.j = Math.round(this.j);
    this.k = Math.round(this.k);

    return this;
  }

  multiplyRight(q1) {
    // ii = jj = kk = -1
    // ij = k | ji = -k
    // ki = j | ik = -j
    // jk = i | kj = -i

    // (w0*w1 + w0*i1 + w0*j1 + w0*k1) +  // 11 + 1i + 1j + 1k  ->  1 +  i +  j +  k
    // (i0*w1 + i0*i1 + i0*j1 + i0*k1) +  // i1 + ii + ij + ik  ->  i + -1 +  k + -j
    // (j0*w1 + j0*i1 + j0*j1 + j0*k1) +  // j1 + ji + jj + jk  ->  j + -k + -1 +  i
    // (k0*w1 + k0*i1 + k0*j1 + k0*k1) +  // k1 + ki + kj + kk  ->  k +  j + -i + -1

    const [w0, i0, j0, k0] = this.toArray();
    const [w1, i1, j1, k1] = q1.toArray();

    const product = new Quaternion();
    product.w = w0 * w1 - i0 * i1 - j0 * j1 - k0 * k1;
    product.i = w0 * i1 + i0 * w1 + j0 * k1 - k0 * j1;
    product.j = w0 * j1 - i0 * k1 + j0 * w1 + k0 * i1;
    product.k = w0 * k1 + i0 * j1 - j0 * i1 + k0 * w1;

    return product;
  }

  rotate(axis, degree) {
    if (degree == 0) {
      return this;
    }

    const [q, qi] = Quaternion.getRotationQuaternions(axis, degree);
    return q.multiplyRight(this).multiplyRight(qi).round();
  }

  rotateX(degree) {
    return this.rotate([1, 0, 0], degree);
  }

  rotateY(degree) {
    return this.rotate([0, 1, 0], degree);
  }

  rotateZ(degree) {
    return this.rotate([0, 0, 1], degree);
  }
}

const getAbsoluteCoordinates = (function () {
  const rotationList = [
    // [firstRotationAxis, firstRotationAngle, secondRotationAxis]
    [[0, 1, 0], 0, [1, 0, 0]],
    [[0, 1, 0], 180, [1, 0, 0]],
    [[0, 0, 1], 270, [0, 1, 0]],
    [[0, 0, 1], 90, [0, 1, 0]],
    [[0, 1, 0], 90, [0, 0, 1]],
    [[0, 1, 0], 270, [0, 0, 1]],
  ];

  return (absoluteBeaconSet, sensor) => {
    const absoluteBeacons = [...absoluteBeaconSet.values()].map((b) =>
      b.split("|")
    );

    for (let fr = 0; fr < rotationList.length; fr++) {
      const [frAxis, frAngle, srAxis] = rotationList[fr];

      for (let srAngle = 0; srAngle <= 270; srAngle += 90) {
        const rotatedBeacons = sensor.map((b) =>
          Quaternion.fromPoint(b)
            .rotate(frAxis, frAngle)
            .rotate(srAxis, srAngle)
            .toPoint()
        );

        for (let i = 0; i < rotatedBeacons.length; i++) {
          for (let j = 0; j < absoluteBeacons.length; j++) {
            // let's assume absolute[j] == rotated[i]
            const [x0, y0, z0] = absoluteBeacons[j];
            const [x1, y1, z1] = rotatedBeacons[i];
            // get absolute position of sensor
            const [sx, sy, sz] = [x0 - x1, y0 - y1, z0 - z1];

            // get absolute position of all beacons
            const potentialAbsoluteBeacons = rotatedBeacons.map((b) => [
              b[0] + sx,
              b[1] + sy,
              b[2] + sz,
            ]);

            if (
              potentialAbsoluteBeacons.filter((b) =>
                absoluteBeaconSet.has(`${b[0]}|${b[1]}|${b[2]}`)
              ).length >= 12
            ) {
              return [potentialAbsoluteBeacons, [sx, sy, sz]];
            }
          }
        }
      }
    }

    return [false, false];
  };
})();

let cache = [];

const getAllAbsoluteCoordinates = (inSensors) => {
  if (cache.length) {
    return cache;
  }

  const sensors = [...inSensors];

  const absoluteBeaconSet = new Set(
    sensors.shift().map((b) => `${b[0]}|${b[1]}|${b[2]}`)
  );

  const allSensors = [[0, 0, 0]];

  while (sensors.length) {
    const currentSensor = sensors.shift();
    const [absoluteCoordinates, sensorCoordinates] = getAbsoluteCoordinates(
      absoluteBeaconSet,
      currentSensor
    );

    if (absoluteCoordinates) {
      absoluteCoordinates.forEach((b) =>
        absoluteBeaconSet.add(`${b[0]}|${b[1]}|${b[2]}`)
      );
      allSensors.push(sensorCoordinates);
    } else {
      sensors.push(currentSensor);
    }
  }

  cache = [absoluteBeaconSet, allSensors];
  return [absoluteBeaconSet, allSensors];
};

const calcMaxDistance = (absSensors) => {
  let maxDistance = 0;

  for (let i = 0; i < absSensors.length - 1; i++) {
    for (let j = i + 1; j < absSensors.length; j++) {
      const distance = absSensors[i].reduce(
        (sum, v, index) => sum + Math.abs(v - absSensors[j][index]),
        0
      );

      if (distance > maxDistance) {
        maxDistance = distance;
      }
    }
  }

  return maxDistance;
};

function parseInput(input) {
  return input
    .split("\n\n")
    .filter((block) => block.trim().length)
    .map((d) =>
      d
        .split("\n")
        .filter((line) => line.length)
        .slice(1)
        .map((l) => l.split(",").map((c) => parseInt(c, 10)))
    );
}

export function part1(input) {
  const sensors = parseInput(input);
  const [absBeacons] = getAllAbsoluteCoordinates(sensors);
  return absBeacons.size;
}

export function part2(input) {
  const sensors = parseInput(input);
  const [_, absSensors] = getAllAbsoluteCoordinates(sensors);
  return calcMaxDistance(absSensors);
}
