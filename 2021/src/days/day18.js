const crypto = require("crypto");

class Node {
  id;
  left = null;
  right = null;
  parent = null;

  constructor(id) {
    this.id = id;
  }

  isFinal() {
    return typeof left == "number" && typeof right == "number";
  }

  leftEnd() {
    return typeof left == "number";
  }

  rightEnd() {
    return typeof right == "number";
  }
}

const newId = () => {
  return crypto
    .createHash("sha256")
    .update(`${Math.random()}_${Date.now()}`)
    .digest("hex");
};

const toTree = (number) => {
  const stack = [];
  let firstNode;
  number.split("").forEach((character) => {
    if (character == "[") {
      stack.push(new Node(newId()));
    } else if (character == "]") {
      const current = stack.pop();
      if (stack.length) {
        const last = stack.pop();
        current.parent = last;
        if (last.left == null) {
          last.left = current;
        } else {
          last.right = current;
        }
        stack.push(last);
      } else {
        firstNode = current;
      }
    } else if (character.match(/\d/)) {
      const current = stack.pop();
      if (current.left == null) {
        current.left = parseInt(character, 10);
      } else {
        current.right = parseInt(character, 10);
      }
      stack.push(current);
    }
  });

  return firstNode;
};

const getLeftNeighbor = (startNode) => {
  const stack = [[startNode, 0]];
  while (stack.length) {
    const [current, dir] = stack.pop();

    if (dir == 0) {
      if (current.parent != null) {
        const parentsLeft = current.parent.left;
        if (typeof parentsLeft == "number") {
          return [current.parent, "left"];
        } else if (parentsLeft.id != current.id) {
          stack.push([parentsLeft, 1]);
        } else {
          stack.push([current.parent, 0]);
        }
      }
    } else {
      if (typeof current.right == "number") {
        return [current, "right"];
      } else {
        stack.push([current.right, 1]);
      }
    }
  }

  return null;
};

const getRightNeighbor = (startNode) => {
  const stack = [[startNode, 0]];
  while (stack.length) {
    const [current, dir] = stack.pop();

    if (dir == 0) {
      if (current.parent != null) {
        const parentsRight = current.parent.right;
        if (typeof parentsRight == "number") {
          return [current.parent, "right"];
        } else if (parentsRight.id != current.id) {
          stack.push([parentsRight, 1]);
        } else {
          stack.push([current.parent, 0]);
        }
      }
    } else {
      if (typeof current.left == "number") {
        return [current, "left"];
      } else {
        stack.push([current.left, 1]);
      }
    }
  }

  return null;
};

const explode = (firstNode) => {
  const stack = [[firstNode, 0]];
  while (stack.length) {
    const [node, level] = stack.pop();

    if (
      typeof node.left == "number" &&
      typeof node.right == "number" &&
      level > 3
    ) {
      const leftNeighbor = getLeftNeighbor(node);
      const rightNeighbor = getRightNeighbor(node);

      if (leftNeighbor != null) {
        leftNeighbor[0][leftNeighbor[1]] += node.left;
      }

      if (rightNeighbor != null) {
        rightNeighbor[0][rightNeighbor[1]] += node.right;
      }

      if (node.parent.left.id == node.id) {
        node.parent.left = 0;
      } else {
        node.parent.right = 0;
      }
      return true;
    }

    if (typeof node.right != "number") {
      stack.push([node.right, level + 1]);
    }

    if (typeof node.left != "number") {
      stack.push([node.left, level + 1]);
    }
  }

  return false;
};

const split = (node) => {
  if (typeof node.left == "number") {
    if (node.left > 9) {
      const newNode = new Node(newId());
      newNode.left = Math.floor(node.left / 2);
      newNode.right = Math.ceil(node.left / 2);
      newNode.parent = node;
      node.left = newNode;

      return true;
    }
  } else if (split(node.left)) {
    return true;
  }

  if (typeof node.right == "number") {
    if (node.right > 9) {
      const newNode = new Node(newId());
      newNode.left = Math.floor(node.right / 2);
      newNode.right = Math.ceil(node.right / 2);
      newNode.parent = node;
      node.right = newNode;

      return true;
    }
  } else if (split(node.right)) {
    return true;
  }

  return false;
};

const reduceNumber = (firstNode) => {
  let exploded = true;
  let didSplit = true;
  while (exploded || didSplit) {
    exploded = explode(firstNode);

    if (exploded) continue;

    didSplit = split(firstNode);
  }
};

const toString = (node) => {
  if (typeof node == "number") {
    return node;
  }

  return `[${toString(node.left)},${toString(node.right)}]`;
};

const getMagnitude = (node) => {
  if (typeof node == "number") {
    return node;
  }

  return 3 * getMagnitude(node.left) + 2 * getMagnitude(node.right);
};

const calcSum = (inNumbers) => {
  const numbers = [...inNumbers];

  return numbers.reduce((sum, number) => {
    const newParent = new Node(newId());
    sum.parent = newParent;
    newParent.left = sum;
    newParent.right = toTree(number);
    newParent.right.parent = newParent;

    reduceNumber(newParent);
    return newParent;
  }, toTree(numbers.shift()));
};

const getMaxSum = (inNumbers) => {
  const numbers = [...inNumbers];
  let max = 0;

  for (let i = 0; i < numbers.length; i++) {
    for (let j = i; j < numbers.length; j++) {
      let list = [
        `[${numbers[i]},${numbers[j]}]`,
        `[${numbers[j]},${numbers[i]}]`,
      ];

      list.forEach((n) => {
        let node = toTree(n);
        reduceNumber(node);
        let magnitude = getMagnitude(node);
        if (magnitude > max) {
          max = magnitude;
        }
      });
    }
  }

  return max;
};

function parseInput(input) {
  return input.split("\n").filter((line) => line.length);
}

export function part1(input) {
  const numbers = parseInput(input);
  return getMagnitude(calcSum(numbers));
}

export function part2(input) {
  const numbers = parseInput(input);
  return getMaxSum(numbers);
}
