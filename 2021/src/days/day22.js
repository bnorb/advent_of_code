const initialize = (instructions) => {
  const onCubes = new Set();

  instructions.forEach((inst) => {
    const [action, coordinates] = inst.split(" ");
    let valid = true;
    const [[x1, x2], [y1, y2], [z1, z2]] = coordinates
      .split(",")
      .map((r) =>
        r
          .split("=")[1]
          .split("..")
          .map((c) => parseInt(c, 10))
      )
      .map(([c1, c2]) => {
        if (c1 > 50 || c2 < -50) {
          valid = false;
        }

        return [c1 < -50 ? -50 : c1, c2 > 50 ? 50 : c2];
      });

    if (!valid) return;

    for (let x = x1; x <= x2; x++) {
      for (let y = y1; y <= y2; y++) {
        for (let z = z1; z <= z2; z++) {
          const hash = `${x}|${y}|${z}`;
          if (action == "on") {
            onCubes.add(hash);
          } else {
            onCubes.delete(hash);
          }
        }
      }
    }
  });

  return onCubes;
};

class Cuboid {
  start;
  end;
  size;

  constructor(start, end) {
    this.start = start;
    this.end = end;
    this.size = this.end.reduce((prod, c, i) => (c - this.start[i]) * prod, 1);
  }
}

const reboot = (instructions) => {
  let cuboids = [];

  instructions.forEach((inst) => {
    const [action, coordinates] = inst.split(" ");
    const [[x1, x2], [y1, y2], [z1, z2]] = coordinates.split(",").map((r) =>
      r
        .split("=")[1]
        .split("..")
        .map((c) => parseInt(c, 10))
    );

    const currentCuboid = new Cuboid([x1, y1, z1], [x2 + 1, y2 + 1, z2 + 1]);

    const intersectingCuboids = cuboids
      .map((c, i) => [getCuboidIntersection(currentCuboid, c), i])
      .filter(([c]) => c);

    const overflowing = [];

    intersectingCuboids.forEach(([intersection, index]) => {
      if (intersection.size == cuboids[index].size) {
        cuboids[index] = null;
      } else {
        overflowing.push([intersection, index]);
      }
    });

    if (overflowing.length == 1 && overflowing[0].size == currentCuboid.size) {
      return;
    }

    const newCuboids = [];
    overflowing.forEach(([intersection, index]) => {
      newCuboids.push(...subtractAndDivide(cuboids[index], intersection));
      cuboids[index] = null;
    });

    cuboids = cuboids.filter((v) => v);
    cuboids.push(...newCuboids);

    if (action == "on") {
      cuboids.push(currentCuboid);
    }
  });

  return cuboids.reduce((sum, c) => sum + c.size, 0);
};

const getCuboidIntersection = (a, b) => {
  const start = [];
  const end = [];

  for (let i = 0; i < 3; i++) {
    if (a.end[i] <= b.start[i] || b.end[i] <= a.start[i]) {
      return false;
    }

    start.push(Math.max(a.start[i], b.start[i]));
    end.push(Math.min(a.end[i], b.end[i]));
  }

  return new Cuboid(start, end);
};

const getSameFaces = (wholeCuboid, partCuboid) => {
  const [[wx1, wy1, wz1], [wx2, wy2, wz2]] = [
    wholeCuboid.start,
    wholeCuboid.end,
  ];

  const [[px1, py1, pz1], [px2, py2, pz2]] = [partCuboid.start, partCuboid.end];

  return {
    "01": wx1 == px1,
    "02": wx2 == px2,
    11: wy1 == py1,
    12: wy2 == py2,
    21: wz1 == pz1,
    22: wz2 == pz2,
  };
};

const subtractAndDivide = (wholeCuboid, partCuboid) => {
  const faces = getSameFaces(wholeCuboid, partCuboid);
  const disonnectedFaces = Object.entries(faces).filter(([_, v]) => !v);

  const [firstAxis, firstNumber] = disonnectedFaces[0][0]
    .split("")
    .map((e) => parseInt(e, 10));

  const start1 = [...wholeCuboid.start];
  const end1 = [...wholeCuboid.end];
  const start2 = [...wholeCuboid.start];
  const end2 = [...wholeCuboid.end];

  let separate, newWhole;

  if (firstNumber == 2) {
    start1[firstAxis] = partCuboid.end[firstAxis];
    end2[firstAxis] = partCuboid.end[firstAxis];
    separate = new Cuboid(start1, end1);
    newWhole = new Cuboid(start2, end2);
  } else {
    start1[firstAxis] = partCuboid.start[firstAxis];
    end2[firstAxis] = partCuboid.start[firstAxis];
    newWhole = new Cuboid(start1, end1);
    separate = new Cuboid(start2, end2);
  }

  const cuboids = [separate];

  if (disonnectedFaces.length > 1) {
    cuboids.push(...subtractAndDivide(newWhole, partCuboid));
  }

  return cuboids;
};

function parseInput(input) {
  return input.split("\n").filter((line) => line.length);
}

export function part1(input) {
  const instructions = parseInput(input);
  return initialize(instructions).size;
}

export function part2(input) {
  const instructions = parseInput(input);
  return reboot(instructions);
}
