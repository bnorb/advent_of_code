import { Corner, CornerOrientation, CornerType } from "./lib/corner";

type Line = [number, number, number];

function parseInput(input: string): Corner[] {
  return input
    .trimEnd()
    .split("\n")
    .map((line) => Corner.parse(line));
}

export function part1(input: string): number {
  const tiles = parseInput(input);

  let maxArea = 0;
  for (let i = 0; i < tiles.length; i++) {
    for (let j = i + 1; j < tiles.length; j++) {
      const area = calcArea(tiles[i]!, tiles[j]!);
      if (area > maxArea) {
        maxArea = area;
      }
    }
  }

  return maxArea;
}

// assumptions: every red tile is on a corner
// tiles are listed clockwise
// basically eliminating all incorrect configurations gives the answer
// - based on corner type (inner/outer) and orientation
// - and wether a line crosses the rectangle or not
export function part2(input: string): number {
  const tiles = parseInput(input);

  setCornerData(tiles);
  const [horizontalLines, verticalLines] = findLines(tiles);

  const isRectViable = (c1: Corner, c2: Corner): boolean => {
    if (!isCornerViable(c1, c2) || !isCornerViable(c2, c1)) {
      return false;
    }

    let minX = Math.min(c1.x, c2.x);
    let maxX = Math.max(c1.x, c2.x);
    let minY = Math.min(c1.y, c2.y);
    let maxY = Math.max(c1.y, c2.y);

    for (let line of horizontalLines) {
      if (line[0] <= minY || line[0] >= maxY) {
        continue;
      }

      if (line[1] < maxX && line[2] > minX) {
        return false;
      }
    }

    for (let line of verticalLines) {
      if (line[0] <= minX || line[0] >= maxX) {
        continue;
      }

      if (line[1] < maxY && line[2] > minY) {
        return false;
      }
    }

    return true;
  };

  let maxArea = 0;
  for (let i = 0; i < tiles.length; i++) {
    for (let j = i + 1; j < tiles.length; j++) {
      if (!isRectViable(tiles[i]!, tiles[j]!)) {
        continue;
      }

      const area = calcArea(tiles[i]!, tiles[j]!);
      if (area > maxArea) {
        maxArea = area;
      }
    }
  }

  return maxArea;
}

function setCornerData(tiles: Corner[]) {
  tiles.forEach((tile, i) => {
    const prevTile = tiles[i - 1] ?? tiles[tiles.length - 1]!;
    const nextTile = tiles[i + 1] ?? tiles[0]!;
    tile.calcData(prevTile, nextTile);
  });
}

function calcArea(c1: Corner, c2: Corner): number {
  const [x, y] = c1.vectorTo(c2);
  return (Math.abs(x) + 1) * (Math.abs(y) + 1);
}

function isCornerViable(corner: Corner, otherCorner: Corner): boolean {
  const [dx, dy] = corner.vectorTo(otherCorner);

  const isCornerMatching = (): boolean => {
    switch (corner.orientation) {
      case CornerOrientation.UpperLeft:
        return dx >= 0 && dy >= 0;
      case CornerOrientation.UpperRight:
        return dx <= 0 && dy >= 0;
      case CornerOrientation.LowerRight:
        return dx <= 0 && dy <= 0;
      case CornerOrientation.LowerLeft:
        return dx >= 0 && dy <= 0;
    }

    throw new Error("unreachable");
  };

  const isMathcing = isCornerMatching();
  return corner.type === CornerType.Outer ? isMathcing : !isMathcing;
}

function findLines(tiles: Corner[]): [Line[], Line[]] {
  const horizontalLines: Line[] = [];
  const verticalLines: Line[] = [];

  tiles.forEach((tile, i) => {
    const nextTile = tiles[i + 1] ?? tiles[0]!;
    if (tile.y === nextTile.y) {
      horizontalLines.push([
        tile.y,
        Math.min(tile.x, nextTile.x),
        Math.max(tile.x, nextTile.x),
      ]);
    } else {
      verticalLines.push([
        tile.x,
        Math.min(tile.y, nextTile.y),
        Math.max(tile.y, nextTile.y),
      ]);
    }
  });

  return [horizontalLines, verticalLines];
}
