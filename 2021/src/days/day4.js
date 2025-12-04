class Point {
  x;
  y;
  marked;
  number;

  constructor(x, y, number) {
    this.x = x;
    this.y = y;
    this.number = number;
    this.marked = false;
  }
}

class Board {
  points = [];
  rows = [];
  cols = [];
  numberSet = new Set();

  isBingo() {
    return (
      this.rows.some((row) => row.every((p) => p.marked)) ||
      this.cols.some((col) => col.every((p) => p.marked))
    );
  }

  getScore() {
    return this.points
      .filter((p) => !p.marked)
      .reduce((sum, p) => sum + p.number, 0);
  }

  constructor(data) {
    this.points = data.split("\n").flatMap((line, rowIndex) =>
      line
        .split(" ")
        .filter((number) => number)
        .map((number, colIndex) => {
          this.numberSet.add(parseInt(number, 10));
          return new Point(rowIndex, colIndex, parseInt(number, 10));
        })
    );

    this.rows = new Array(5)
      .fill(0)
      .map((_, index) => this.points.filter((p) => p.x == index));

    this.cols = new Array(5)
      .fill(0)
      .map((_, index) => this.points.filter((p) => p.y == index));
  }
}

const getWinningBoard = (numbers, boardData) => {
  const boards = boardData.map((d) => new Board(d));

  let bingoBoard;
  let currentNumber;
  let i = 0;

  while (i < numbers.length && !bingoBoard) {
    currentNumber = numbers[i];
    boards
      .filter((b) => b.numberSet.has(currentNumber))
      .forEach((b) => {
        b.points
          .filter((p) => p.number == currentNumber)
          .forEach((p) => {
            p.marked = true;
          });

        if (b.isBingo()) {
          bingoBoard = b;
        }
      });
    i++;
  }

  return [currentNumber, bingoBoard];
};

const getLastBoard = (numbers, boardData) => {
  let boards = boardData.map((d) => new Board(d));

  let bingoBoard;
  let currentNumber;
  let i = 0;

  while (numbers.length && boards.length > 0) {
    currentNumber = numbers[i];
    boards
      .filter((b) => b.numberSet.has(currentNumber))
      .forEach((b) => {
        b.points
          .filter((p) => p.number == currentNumber)
          .forEach((p) => {
            p.marked = true;
          });
      });

    if (boards.length == 1) {
      if (boards[0].isBingo()) {
        bingoBoard = boards[0];
        break;
      }
    } else {
      boards = boards.filter((b) => !b.isBingo());
    }

    i++;
  }

  return [currentNumber, bingoBoard];
};

function parseInput(input) {
  const boardData = input.split("\n\n");
  const numbers = boardData
    .shift()
    .split(",")
    .map((number) => parseInt(number, 10));

  return [boardData, numbers];
}

export function part1(input) {
  const [boardData, numbers] = parseInput(input);
  const [winningNumber, winningBoard] = getWinningBoard(numbers, boardData);
  return winningBoard.getScore() * winningNumber;
}

export function part2(input) {
  const [boardData, numbers] = parseInput(input);
  const [lastNumber, lastBoard] = getLastBoard(numbers, boardData);
  return lastBoard.getScore() * lastNumber;
}
