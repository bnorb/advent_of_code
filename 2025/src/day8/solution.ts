import { Circuit } from "./lib/circuit";
import { Connection } from "./lib/connection";
import { Vec3D } from "./lib/vec_3d";

function parseInput(input: string): Vec3D[] {
  return input
    .trimEnd()
    .split("\n")
    .map((line) => Vec3D.parse(line));
}

export function part1(input: string): number {
  const positions = parseInput(input);
  const connections = getConnections(positions);
  connections.sort((a, b) => a.cmp(b));

  const junktionMap: Record<string, Circuit> = {};
  const circuits = new Map<number, Circuit>();

  const limit = 1000;
  for (let i = 0; i < connections.length && i < limit; i++) {
    connectJunktions(connections[i]!, junktionMap, circuits);
  }

  return [...circuits.values()]
    .sort((a, b) => b.cmp(a))
    .slice(0, 3)
    .map((c) => c.count)
    .reduce((prod, part) => prod * part, 1);
}

export function part2(input: string): number {
  const positions = parseInput(input);
  const connections = getConnections(positions);
  connections.sort((a, b) => a.cmp(b));

  const junktionMap: Record<string, Circuit> = {};
  const circuits = new Map<number, Circuit>();

  const untouchedPositions = new Set(positions.map((p) => p.toString()));

  for (let i = 0; i < connections.length; i++) {
    const from = connections[i]!.from;
    const to = connections[i]!.to;
    untouchedPositions.delete(from.toString());
    untouchedPositions.delete(to.toString());

    const merged = connectJunktions(connections[i]!, junktionMap, circuits);

    if (merged && circuits.size === 1 && untouchedPositions.size === 0) {
      return from.x * to.x;
    }
  }

  return -1;
}

function connectJunktions(
  connection: Connection,
  junktionMap: Record<string, Circuit>,
  circuits: Map<number, Circuit>
): boolean {
  const from = connection.from.toString();
  const to = connection.to.toString();

  const circuit1 = junktionMap[from];
  const circuit2 = junktionMap[to];

  if (!circuit1 && !circuit2) {
    const circuit = new Circuit([from, to]);
    junktionMap[from] = circuit;
    junktionMap[to] = circuit;
    circuits.set(circuit.id, circuit);
    return false;
  }

  if (!circuit1) {
    junktionMap[from] = circuit2!;
    circuit2!.add(from);
    return false;
  }

  if (!circuit2) {
    junktionMap[to] = circuit1!;
    circuit1!.add(to);
    return false;
  }

  if (circuit1 === circuit2) {
    return false;
  }

  circuit2.junktions.forEach((j) => (junktionMap[j] = circuit1));
  circuit1.merge(circuit2);
  circuits.delete(circuit2.id);

  return true;
}

function getConnections(positions: Vec3D[]): Connection[] {
  const connections = [];
  for (let i = 0; i < positions.length - 1; i++) {
    for (let j = i + 1; j < positions.length; j++) {
      connections.push(new Connection(positions[i]!, positions[j]!));
    }
  }

  return connections;
}
