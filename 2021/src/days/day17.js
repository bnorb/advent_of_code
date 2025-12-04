const inArea = (p, x1, x2, y1, y2) => {
  return p[0] >= x1 && p[0] <= x2 && p[1] >= y1 && p[1] <= y2;
};

const trajectory = (p0, v0, x1, x2, y1, y2) => {
  let p = [...p0];
  let v = [...v0];
  let positions = [[...p0]];
  let hit = false;
  while (p[0] < x2 && p[1] > y1) {
    p[0] += v[0];
    p[1] += v[1];

    positions.push([...p]);
    if (inArea(p, x1, x2, y1, y2)) {
      hit = true;
      break;
    }

    if (v[0] != 0) {
      v[0] > 0 ? v[0]-- : v[0]++;
    }
    v[1]--;
  }

  return [hit, positions];
};

const trickshot = (xRange, yRange) => {
  const [x1, x2] = xRange.split("..");
  const [y1, y2] = yRange.split("..");

  let Vy = 1;
  let Vx;
  const p = [0, 0];
  let max = 0;
  while (true) {
    Vx = 1;
    let hit = false;
    while (Vx <= 200) {
      let positions;
      [hit, positions] = trajectory(p, [Vx, Vy], x1, x2, y1, y2);

      if (hit) {
        const localMax = positions.reduce(
          (max, p) => (p[1] > max ? p[1] : max),
          0
        );
        if (localMax > max) {
          max = localMax;
        }
      }
      Vx++;
    }

    if (Vy > 200) {
      break;
    }

    Vy++;
  }

  return max;
};

const calcSafeShotCount = (xRange, yRange) => {
  const [x1, x2] = xRange.split("..");
  const [y1, y2] = yRange.split("..");
  let Vy = -800;
  let Vx;
  const p = [0, 0];
  let count = 0;

  while (Vy < 800) {
    Vx = 1;
    while (Vx <= 500) {
      const [hit, _] = trajectory(p, [Vx, Vy], x1, x2, y1, y2);

      if (hit) {
        count++;
      }
      Vx++;
    }

    Vy++;
  }

  return count;
};

function parseInput(input) {
  return input
    .substring(13)
    .split(",")
    .map((part) => part.trim().substring(2));
}

export function part1(input) {
  const [xRange, yRange] = parseInput(input);
  return trickshot(xRange, yRange);
}

export function part2(input) {
  const [xRange, yRange] = parseInput(input);
  return calcSafeShotCount(xRange, yRange);
}
