const getPosition = (directions) => {
  let depth = 0;
  let horizontal = 0;

  directions.forEach((d) => {
    let [dir, amount] = d.split(" ");
    amount = parseInt(amount, 10);

    switch (dir) {
      case "forward": {
        horizontal += amount;
        break;
      }
      case "up": {
        depth -= amount;
        break;
      }
      case "down": {
        depth += amount;
      }
    }
  });

  return [depth, horizontal];
};

const getPositionAimed = (directions) => {
  let depth = 0;
  let horizontal = 0;
  let aim = 0;

  directions.forEach((d) => {
    let [dir, amount] = d.split(" ");
    amount = parseInt(amount, 10);

    switch (dir) {
      case "forward": {
        horizontal += amount;
        depth += aim * amount;
        break;
      }
      case "up": {
        aim -= amount;
        break;
      }
      case "down": {
        aim += amount;
      }
    }
  });

  return [depth, horizontal];
};

export function part1(input) {
  const directions = input.split("\n");
  const [p1, p2] = getPosition(directions);
  return p1 * p2;
}

export function part2(input) {
  const directions = input.split("\n");
  const [p1, p2] = getPositionAimed(directions);
  return p1 * p2;
}
