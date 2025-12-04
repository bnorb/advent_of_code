const orderAmphipods = (
  startingPositions,
  roomDepth,
  hallwayLength,
  amphipodEnergies,
  amphipodRooms
) => {
  const doors = new Set([...amphipodRooms.values()]);

  const isOccupiedByTypeFrom = (from, type, x, occupiedPositions) => {
    let occByType = 0;

    for (let i = from + 1; i <= roomDepth; i++) {
      if (occupiedPositions.get(`${x}|${i}`) == type) {
        occByType++;
      }
    }

    return occByType == roomDepth - from;
  };

  const getMovesFrom = (type, x, occupiedPositions, onlyToRoom = false) => {
    const moves = [];

    const getMoves = (i) => {
      if (!doors.has(i)) {
        if (!onlyToRoom) {
          moves.push([i, 0]);
        }
      } else if (amphipodRooms.get(type) == i) {
        if (!occupiedPositions.has(`${i}|${roomDepth}`)) {
          moves.push([i, roomDepth]);
        } else {
          for (let j = roomDepth - 1; j > 0; j--) {
            if (!occupiedPositions.has(`${i}|${j}`)) {
              if (isOccupiedByTypeFrom(j, type, i, occupiedPositions)) {
                moves.push([i, j]);
                break;
              }
            }
          }
        }
      }
    };

    for (let i = x - 1; i >= 0; i--) {
      if (occupiedPositions.has(`${i}|0`)) {
        break;
      }

      getMoves(i);
    }

    for (let i = x + 1; i < hallwayLength; i++) {
      if (occupiedPositions.has(`${i}|0`)) {
        break;
      }

      getMoves(i);
    }

    return moves;
  };

  const getPossibleNextMoves = (type, [x, y], occupiedPositions) => {
    if (x == amphipodRooms.get(type)) {
      if (y == roomDepth) {
        return [];
      }

      if (isOccupiedByTypeFrom(y, type, x, occupiedPositions)) {
        return [];
      }
    }

    if (y > 1) {
      for (let i = y - 1; i > 0; i--) {
        if (occupiedPositions.has(`${x}|${i}`)) {
          return [];
        }
      }
    }

    const possibleMoves = [];
    const energy = amphipodEnergies.get(type);

    possibleMoves.push(
      ...getMovesFrom(type, x, occupiedPositions, y == 0).map(
        ([newX, newY]) => [
          [newX, newY],
          (y + Math.abs(x - newX) + newY) * energy,
        ]
      )
    );

    return possibleMoves;
  };

  const getHash = (positions) => {
    let hash = ``;

    [...positions.keys()].forEach((id) => {
      const [x, y] = positions.get(id);
      hash += `|${x},${y}`;
    });

    return hash;
  };

  const isSorted = (occupiedPositions) => {
    for (let [type, x] of amphipodRooms) {
      if (!isOccupiedByTypeFrom(0, type, x, occupiedPositions)) {
        return false;
      }
    }

    return true;
  };

  const findCorrectRooms = (startingPositions) => {
    const queue = [[startingPositions, 0]];
    const visited = new Map([[getHash(startingPositions), 0]]);

    let min = Number.POSITIVE_INFINITY;

    while (queue.length) {
      const [positions, energy] = queue.shift();

      const occupiedPositions = new Map(
        [...positions].map(([id, [x, y]]) => [`${x}|${y}`, id.charAt(0)])
      );

      if (isSorted(occupiedPositions)) {
        if (min > energy) {
          min = energy;
          continue;
        }
      }

      [...positions].forEach(([id, pos]) => {
        const nextMoves = getPossibleNextMoves(
          id.charAt(0),
          pos,
          occupiedPositions
        );

        nextMoves.forEach(([pos, requiredEnergy]) => {
          const newEnergy = energy + requiredEnergy;
          const newPositions = new Map([...positions]);
          newPositions.set(id, pos);

          const hash = getHash(newPositions, newEnergy);
          const visitedEnergy = visited.get(hash) || Number.POSITIVE_INFINITY;

          if (newEnergy < visitedEnergy) {
            queue.push([newPositions, newEnergy]);
            visited.set(hash, newEnergy);
          }
        });
      });
    }

    return min;
  };

  return findCorrectRooms(startingPositions);
};

const parseLines = (lines) => {
  const hallwayLength = lines[1].split("").filter((c) => c == ".").length;
  const roomDepth = lines.length - 3;

  const positions = new Map();
  let char = 65;
  let energy = 1;

  const amphipodEnergies = new Map();
  const amphipodRooms = new Map();

  lines[2].split("").forEach((v, i) => {
    if (v.match(/[A-Z]/)) {
      amphipodRooms.set(String.fromCharCode(char), i - 1);
      amphipodEnergies.set(String.fromCharCode(char), energy);

      char++;
      energy *= 10;
    }
  });

  const counts = {};

  for (let [_, x] of amphipodRooms) {
    for (let i = 1; i <= roomDepth; i++) {
      const amphipod = lines[i + 1].charAt(x + 1);
      const currCount = counts[amphipod] || 0;
      positions.set(`${amphipod}${currCount + 1}`, [x, i]);
      counts[amphipod] = currCount + 1;
    }
  }

  return [hallwayLength, roomDepth, positions, amphipodRooms, amphipodEnergies];
};

function parseInput(input) {
  return input.split("\n").filter((line) => line.length);
}

export function part1(input) {
  const lines = parseInput(input);
  const [hallwayLength, roomDepth, positions, amphipodRooms, amphipodEnergies] =
    parseLines(lines);

  return orderAmphipods(
    positions,
    roomDepth,
    hallwayLength,
    amphipodEnergies,
    amphipodRooms
  );
}

export function part2(input) {
  const lines = parseInput(input);
  lines.splice(3, 0, "  #D#C#B#A#", "  #D#B#A#C#");

  const [hallwayLength, roomDepth, positions, amphipodRooms, amphipodEnergies] =
    parseLines(lines);

  return orderAmphipods(
    positions,
    roomDepth,
    hallwayLength,
    amphipodEnergies,
    amphipodRooms
  );
}
