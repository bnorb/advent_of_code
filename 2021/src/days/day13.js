const doFolds = (coordinates, folds) => {
  const cMap = { x: 0, y: 1 };
  let currentCoordinates = coordinates;
  const pointSet = new Set();

  folds.forEach((fold) => {
    pointSet.clear();
    currentCoordinates = currentCoordinates
      .map((coordinate) => {
        const foldLine = fold[1];
        let currentLine = coordinate[cMap[fold[0]]];

        if (currentLine > foldLine) {
          currentLine = 2 * foldLine - currentLine;
        }

        const newCoordinates =
          fold[0] == "x"
            ? [currentLine, coordinate[1]]
            : [coordinate[0], currentLine];

        if (pointSet.has(`${newCoordinates[0]}_${newCoordinates[1]}`)) {
          return null;
        }

        pointSet.add(`${newCoordinates[0]}_${newCoordinates[1]}`);

        return newCoordinates;
      })
      .filter((c) => c);
  });

  const minMax = currentCoordinates.reduce(
    (mm, c) => {
      if (c[0] < mm.min.x) {
        mm.min.x = c[0];
      }
      if (c[0] > mm.max.x) {
        mm.max.x = c[0];
      }
      if (c[1] < mm.min.y) {
        mm.min.y = c[1];
      }
      if (c[1] > mm.max.y) {
        mm.max.y = c[1];
      }
      return mm;
    },
    {
      min: { x: Number.MAX_SAFE_INTEGER, y: Number.MAX_SAFE_INTEGER },
      max: { x: 0, y: 0 },
    }
  );

  const lines = [];
  for (let i = minMax.min.y; i <= minMax.max.y; i++) {
    let line = "";
    for (let j = minMax.min.x; j <= minMax.max.x; j++) {
      line += pointSet.has(`${j}_${i}`) ? "#" : ".";
    }
    lines.push(line);
  }

  return lines;
};

function parseInput(input) {
  let [coordinates, folds] = input
    .split("\n\n")
    .map((block) => block.split("\n").filter((line) => line.length));

  coordinates = coordinates.map((line) =>
    line.split(",").map((c) => parseInt(c, 10))
  );

  folds = folds.map((line) =>
    line
      .split(" ")[2]
      .split("=")
      .map((v, i) => (i == 1 ? parseInt(v, 10) : v))
  );

  return [coordinates, folds];
}

export function part1(input) {
  const [coordinates, folds] = parseInput(input);
  return doFolds(coordinates, [folds[0]]).reduce(
    (count, line) => count + line.split("").filter((c) => c == "#").length,
    0
  );
}

export function part2(input) {
  const [coordinates, folds] = parseInput(input);
  doFolds(coordinates, folds).forEach((line) => {
    console.log(line);
  });
}
