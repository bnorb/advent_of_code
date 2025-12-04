const getGammaEpsilon = (diagnosticData) => {
  const half = diagnosticData.length / 2;
  const counts = new Array(diagnosticData[0].length).fill(0);

  diagnosticData.forEach((d) => {
    d.split("").forEach((digit, index) => {
      if (digit == "1") counts[index]++;
    });
  });

  const mostCommon = counts.map((c) => (c >= half ? "1" : "0")).join("");
  const leastCommon = counts.map((c) => (c >= half ? "0" : "1")).join("");

  const mostCommonDec = parseInt(mostCommon, 2);
  const leastCommonDec = parseInt(leastCommon, 2);

  return [mostCommonDec, leastCommonDec];
};

const getO2CO2 = (diagnosticData) => {
  let mostCommonHalf = diagnosticData.length / 2;
  let leastCommonHalf = mostCommonHalf;

  let mostCommon = [...diagnosticData];
  let leastCommon = [...diagnosticData];
  let bit = 0;

  while (mostCommon.length > 1 || leastCommon.length > 1) {
    if (mostCommon.length > 1) {
      const column = mostCommon.map((d) => d.charAt(bit));
      const most =
        column.reduce((ones, digit) => (digit == "1" ? ones + 1 : ones), 0) >=
        mostCommonHalf
          ? "1"
          : "0";

      mostCommon = mostCommon.filter((d) => d.charAt(bit) == most);
      mostCommonHalf = mostCommon.length / 2;
    }

    if (leastCommon.length > 1) {
      const col = leastCommon.map((d) => d.charAt(bit));
      const least =
        col.reduce((ones, digit) => (digit == "1" ? ones + 1 : ones), 0) >=
        leastCommonHalf
          ? "0"
          : "1";

      leastCommon = leastCommon.filter((d) => d.charAt(bit) == least);
      leastCommonHalf = leastCommon.length / 2;
    }

    bit++;
  }

  const mostCommonDec = parseInt(mostCommon[0], 2);
  const leastCommonDec = parseInt(leastCommon[0], 2);

  return [mostCommonDec, leastCommonDec];
};

export function part1(input) {
  const diagnosticData = input.split("\n");
  const [gamma, epsilon] = getGammaEpsilon(diagnosticData);
  return gamma * epsilon;
}

export function part2(input) {
  const diagnosticData = input.split("\n");
  const [o2, co2] = getO2CO2(diagnosticData);
  return o2 * co2;
}
