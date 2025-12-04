class ALU {
  w = 0;
  x = 0;
  y = 0;
  z = 0;

  getSecondVal(b) {
    if (b.match(/^[wxyz]$/)) {
      return this[b];
    }

    return parseInt(b, 10);
  }

  inp(a, value) {
    this[a] = value;
  }

  add(a, b) {
    this[a] += this.getSecondVal(b);
  }

  mul(a, b) {
    this[a] *= this.getSecondVal(b);
  }

  div(a, b) {
    this[a] = Math.floor(this[a] / this.getSecondVal(b));
  }

  mod(a, b) {
    this[a] = this[a] % this.getSecondVal(b);
  }

  eql(a, b) {
    this[a] = this[a] == this.getSecondVal(b) ? 1 : 0;
  }

  clone() {
    const n = new ALU();
    n.w = this.w;
    n.x = this.x;
    n.y = this.y;
    n.z = this.z;

    return n;
  }
}

const runMonad = (alu, inputs, monad) => {
  monad.forEach((inst) => {
    const [op, ...rest] = inst;
    if (op == "inp") {
      rest.push(inputs.shift());
    }

    alu[op](...rest);
  });
};

const getBlockPossibilities = (
  high,
  low,
  instructions1,
  instructions2,
  prevAlu,
  highToLow
) => {
  const doit = (inputs, block) => {
    const alu = prevAlu.clone();

    runMonad(alu, inputs, instructions1);
    const z = alu.z;
    runMonad(alu, inputs, instructions2);

    if (alu.z == Math.floor(z / 26)) {
      possibilities.push([block, alu]);
    }
  };

  const possibilities = [];

  if (highToLow) {
    let block = high;

    while (block >= low) {
      const inputs = Array.from(String(block), Number);
      if (inputs.some((n) => n == 0)) {
        block--;
        continue;
      }

      doit(inputs, block);

      block--;
    }
  } else {
    let block = low;

    while (block <= high) {
      const inputs = Array.from(String(block), Number);
      if (inputs.some((n) => n == 0)) {
        block++;
        continue;
      }

      doit(inputs, block);

      block++;
    }
  }

  return possibilities;
};

const getNextPossibilities = (instructions, prevAlu, highToLow) => {
  const doit = (i) => {
    const alu = prevAlu.clone();
    runMonad(alu, [i], instructions);

    if (alu.z == Math.floor(prevAlu.z / 26)) {
      possibilities.push([i, alu]);
    }
  };

  const possibilities = [];

  if (highToLow) {
    for (let i = 9; i > 0; i--) {
      doit(i);
    }
  } else {
    for (let i = 1; i <= 9; i++) {
      doit(i);
    }
  }

  return possibilities;
};

const getEnd = (instructions, prevAlu, highToLow) => {
  const doit = (i) => {
    const alu = prevAlu.clone();
    runMonad(alu, [i], instructions);

    if (alu.z == 0) {
      return i;
    }
  };

  if (highToLow) {
    for (let i = 9; i > 0; i--) {
      const end = doit(i);
      if (end) {
        return end;
      }
    }
  } else {
    for (let i = 1; i <= 9; i++) {
      const end = doit(i);
      if (end) {
        return end;
      }
    }
  }

  return false;
};

const getFirstModelNumber = (monad, highToLow) => {
  const pos1 = getBlockPossibilities(
    99999,
    11111,
    monad.slice(0, 72),
    monad.slice(72, 90),
    new ALU(),
    highToLow
  );

  for (let [block1, alu1] of pos1) {
    const pos2 = getBlockPossibilities(
      999,
      111,
      monad.slice(90, 126),
      monad.slice(126, 144),
      alu1,
      highToLow
    );

    for (let [block2, alu2] of pos2) {
      const pos3 = getBlockPossibilities(
        99,
        11,
        monad.slice(144, 162),
        monad.slice(162, 180),
        alu2,
        highToLow
      );

      for (let [block3, alu3] of pos3) {
        const pos4 = getNextPossibilities(
          monad.slice(180, 198),
          alu3,
          highToLow
        );

        for (let [block4, alu4] of pos4) {
          const pos5 = getNextPossibilities(
            monad.slice(198, 216),
            alu4,
            highToLow
          );

          for (let [block5, alu5] of pos5) {
            const pos6 = getNextPossibilities(
              monad.slice(216, 234),
              alu5,
              highToLow
            );

            for (let [block6, alu6] of pos6) {
              const end = getEnd(monad.slice(234), alu6, highToLow);
              if (end) {
                return `${block1}${block2}${block3}${block4}${block5}${block6}${end}`;
              }
            }
          }
        }
      }
    }
  }
};

function parseInput(input) {
  return input
    .split("\n")
    .filter((line) => line.length)
    .map((l) => l.split(" "));
}

// this is horrible and fully hardcoded for the input

export function part1(input) {
  const instructions = parseInput(input);
  return getFirstModelNumber(instructions, true);
}

export function part2(input) {
  const instructions = parseInput(input);
  return getFirstModelNumber(instructions, false);
}
