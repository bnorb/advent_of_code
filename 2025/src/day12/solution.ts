import { Area } from "./lib/area"
import { Shape } from "./lib/shape"

function parseInput(input: string): [Shape[], Area[]] {
  const parts = input.trimEnd().split("\n\n")
  const shapes = parts.slice(0, 6)
  const areas = parts.slice(6,7)[0]!.split("\n")

  return [
    shapes.map(sh => new Shape(sh)),
    areas.map(a => new Area(a))
  ]
}

export function part1(input: string): number {
  const [shapes, areas] = parseInput(input)
  return areas.filter(a => a.canFitPresents(shapes)).length
}

