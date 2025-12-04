const practice = (p1Start, p2Start) => {
  const roll = (function () {
    let last = 100;

    const next = () => (last == 100 ? 1 : last + 1);

    return (n) => {
      return new Array(n).fill(0).map((_) => {
        const val = next();
        last = val;
        return val;
      });
    };
  })();

  const sum = (s, v) => s + v;

  let allRolls = 0;
  let positions = [p1Start, p2Start];
  let scores = [0, 0];
  let current = 0;

  while (true) {
    const rolls = roll(3);
    const rollSum = rolls.reduce(sum, 0);

    allRolls += 3;

    let nextPosition = positions[current] + (rollSum % 10);
    nextPosition = nextPosition > 10 ? nextPosition % 10 : nextPosition;
    positions[current] = nextPosition;

    scores[current] += positions[current];

    if (scores[current] >= 1000) {
      return [scores, allRolls];
    }

    current = current == 0 ? 1 : 0;
  }
};

const game = (p1Start, p2Start) => {
  const rollSums = [3, 4, 5, 6, 7, 8, 9];
  const rollCounts = [1, 3, 6, 7, 6, 3, 1];

  const firstNode = [0, [0, 0], [p1Start, p2Start], 1]; // nextPlayerToRoll, scores, positions, universeCount
  const stack = [firstNode];

  const winCounter = [0, 0];

  while (stack.length) {
    const [current, scores, positions, count] = stack.pop();

    let nextPositions = [];
    let nextScores = [];
    const nextPlayer = current == 1 ? 0 : 1;

    rollSums.forEach((sum) => {
      let next = positions[current] + sum;
      next = next > 10 ? next % 10 : next;
      nextPositions.push(next);
      nextScores.push(scores[current] + next);
    });

    nextScores.forEach((score, i) => {
      if (score >= 21) {
        winCounter[current] += count * rollCounts[i];
      } else {
        const p = [...positions];
        const s = [...scores];

        p[current] = nextPositions[i];
        s[current] = score;

        stack.push([nextPlayer, s, p, count * rollCounts[i]]);
      }
    });
  }

  return winCounter;
};

function parseInput(input) {
  return input.split("\n").map((l) => parseInt(l.split(": ")[1], 10));
}

export function part1(input) {
  const [p1Start, p2Start] = parseInput(input);
  const result = practice(p1Start, p2Start);
  return (
    result[0].reduce((m, v) => (v < m ? v : m), Number.POSITIVE_INFINITY) *
    result[1]
  );
}

export function part2(input) {
  const [p1Start, p2Start] = parseInput(input);
  return game(p1Start, p2Start).reduce((max, v) => (v > max ? v : max), 0);
}
