const map = {
  0: "0000",
  1: "0001",
  2: "0010",
  3: "0011",
  4: "0100",
  5: "0101",
  6: "0110",
  7: "0111",
  8: "1000",
  9: "1001",
  A: "1010",
  B: "1011",
  C: "1100",
  D: "1101",
  E: "1110",
  F: "1111",
};

const decode = (code) => {
  let versionSum = 0;

  const decodeInner = (code) => {
    const version = parseInt(code.substr(0, 3), 2);
    versionSum += version;

    const type = parseInt(code.substr(3, 3), 2);
    let totalBits = 6;
    let sum;

    if (type == 4) {
      // get literal value
      let start = 6;
      let done = false;
      let number = "";

      while (!done) {
        const part = code.substr(start, 5);
        totalBits += 5;
        start += 5;
        if (part.charAt(0) == "0") {
          done = true;
        }
        number += part.substr(1, 4);
      }

      sum = parseInt(number, 2);
    } else {
      // operator
      const lengthType = parseInt(code.substr(6, 1), 2);
      totalBits += 1;

      const parts = [];
      if (lengthType == 1) {
        // number of contained sub-packets
        let numberOfPackets = parseInt(code.substr(7, 11), 2);
        totalBits += 11;
        let start = 18;
        while (numberOfPackets > 0) {
          const [usedBits, partSum] = decodeInner(code.substr(start));
          numberOfPackets--;
          start += usedBits;
          totalBits += usedBits;
          parts.push(partSum);
        }
      } else {
        // total bits of subpackets
        let totalSubBits = parseInt(code.substr(7, 15), 2);
        totalBits += 15;
        let start = 22;
        while (totalSubBits > 0) {
          const [usedBits, partSum] = decodeInner(
            code.substr(start, totalSubBits)
          );
          totalSubBits -= usedBits;
          start += usedBits;
          totalBits += usedBits;
          parts.push(partSum);
        }
      }

      switch (type) {
        case 0: {
          sum = parts.reduce((a, p) => a + p, 0);
          break;
        }
        case 1: {
          sum = parts.reduce((a, p) => a * p, 1);
          break;
        }
        case 2: {
          sum = parts.reduce(
            (a, p) => (p < a ? p : a),
            Number.POSITIVE_INFINITY
          );
          break;
        }
        case 3: {
          sum = parts.reduce((a, p) => (p > a ? p : a), 0);
          break;
        }
        case 5: {
          sum = parts[0] > parts[1] ? 1 : 0;
          break;
        }
        case 6: {
          sum = parts[0] < parts[1] ? 1 : 0;
          break;
        }
        case 7: {
          sum = parts[0] == parts[1] ? 1 : 0;
          break;
        }
      }
    }

    return [totalBits, sum];
  };

  const [_, sum] = decodeInner(code);
  return [versionSum, sum];
};

function parseInput(input) {
  return input
    .split("")
    .map((hex) => map[hex])
    .join("");
}

export function part1(input) {
  const code = parseInput(input);
  return decode(code)[0];
}

export function part2(input) {
  const code = parseInput(input);
  return decode(code)[1];
}
