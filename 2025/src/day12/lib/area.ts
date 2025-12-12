import type { Shape } from "./shape"

export class Area {
    private size = 0
    private instructions: number[] = []

    public constructor(str: string) {
        const [size, instructions] = str.split(": ")
        const [rows, cols] = size!.split("x").map(n => parseInt(n, 10))
        this.size = rows! * cols!
        
        this.instructions = instructions!.split(" ").map(n => parseInt(n, 10))
    }

    // honestly this was supposed to be just the first step, didn't expect it to actually give me the final answer
    public canFitPresents(shapes: Shape[]): boolean {
        const totalSize = this.instructions.reduce((size, inst, index) => size + inst * shapes[index]!.filledCells, 0)
        if (totalSize > this.size) {
            return false
        }

        return true
    }
}