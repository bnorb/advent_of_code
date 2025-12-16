const M = 100000000000

export enum ConstraintType {
    LTE = "LTE",
    EQ = "EQ",
    GTE = "GTE"
}

export enum VariableType {
    Slack = "Sl",
    Surplus = "Sp",
    Artificial = "A",
    Regular = "X"
}

export type Constraint = {
    coefficients: number[];
    type: ConstraintType;
    rhs: number;
}

export type Variable = {
    type: VariableType,
    index: number,
    coefficient: number
}

type Tableau = {
    cj: Variable[];
    matrix: number[][];
    b: number[];
    basis: Variable[];
    zj: number[];
    cjZj: number[];
}

export type Solution = {
    basis: Variable[],
    rhs: number[],
}

export class SimplexSolver {
    private readonly variableCount: number
    private readonly constraintCount: number
    private tableau!: Tableau;

    public constructor(private readonly objective: number[], private readonly constraints: Constraint[], min: boolean) {
        this.constraintCount = this.constraints.length
        this.variableCount = this.objective.length

        if (min) {
            this.objective = this.objective.map(o => -o)
        }
    }

    public solve(): Solution {
        this.initTableau()
        this.calcZ()

        do {
            this.pivot()
            this.calcZ()
        } while (!this.isDone())

        const epsilon = 0.0000001
        if (!this.tableau.basis.every((v, index) => v.type !== VariableType.Artificial || Math.abs(this.tableau.b[index]!) < epsilon)) {
            throw new Error("Invalid solution")
        }

        return {
            basis: this.tableau.basis,
            rhs: this.tableau.b
        }
    }

    private initTableau() {
        const cj: Variable[] = this.objective.map((coefficient, index) => ({ type: VariableType.Regular, index, coefficient }))
        const basis: Variable[] = []
        const b: number[] = []

        this.constraints.forEach((constraint, index) => {
            b.push(constraint.rhs)

            switch (constraint.type) {
                case ConstraintType.LTE: {
                    const s = { type: VariableType.Slack, index, coefficient: 0 }
                    cj.push(s)
                    basis.push(s)
                    break
                }
                case ConstraintType.GTE: {
                    const s = { type: VariableType.Surplus, index, coefficient: 0 }
                    const a = { type: VariableType.Artificial, index, coefficient: -M }
                    cj.push(s, a)
                    basis.push(a)
                    break
                }
                case ConstraintType.EQ: {
                    const a = { type: VariableType.Artificial, index, coefficient: -M }
                    cj.push(a)
                    basis.push(a)
                    break
                }
            }
        })

        const matrix = this.constraints.map(c => [...c.coefficients])
        for (let rowIndex in matrix) {
            matrix[rowIndex]!.push(...cj.slice(this.variableCount).map((v) =>
                basis[rowIndex]!.index !== v.index
                    ? 0
                    : v.type === VariableType.Surplus
                        ? -1
                        : 1
            ))
        }

        this.tableau = {
            cj,
            b,
            basis,
            matrix,
            zj: [],
            cjZj: []
        }
    }

    private calcZ() {
        this.tableau.zj.length = 0
        this.tableau.cjZj.length = 0

        for (let col = 0; col < this.tableau.matrix[0]!.length; col++) {
            let z = 0
            for (let row = 0; row < this.tableau.matrix.length; row++) {
                z += this.tableau.basis[row]!.coefficient! * this.tableau.matrix[row]![col]!
            }

            this.tableau.zj.push(z)
            this.tableau.cjZj.push(this.tableau.cj[col]!.coefficient - z)
        }
    }

    private isDone(): boolean {
        return this.tableau.cjZj.every(v => v <= 0)
    }

    private findPivotColumn(): number {
        return (this.tableau.cjZj.reduce(([max, maxIndex], curr, index) => curr > max ? [curr, index] : [max, maxIndex], [0, -1]) satisfies [number, number])[1]
    }

    private findPivotRow(pivotColumn: number): number {
        let min = Number.MAX_SAFE_INTEGER
        let minIndex = -1

        for (let row = 0; row < this.tableau.matrix.length; row++) {
            const numerator = this.tableau.b[row]!
            const denominator = this.tableau.matrix[row]![pivotColumn]!

            if (denominator <= 0) {
                continue
            }

            const q = Math.abs(numerator / denominator)
            if (q < min) {
                minIndex = row
                min = q
            }
        }

        return minIndex
    }

    private pivot() {
        const pivotColumn = this.findPivotColumn()
        const pivotRow = this.findPivotRow(pivotColumn)

        const makePivotOne = () => {
            const pivotValue = this.tableau.matrix[pivotRow]![pivotColumn]!
            if (pivotValue === 1) {
                return
            }

            for (let col = 0; col < this.tableau.matrix[0]!.length; col++) {
                if (col === pivotColumn) { // avoid float issues
                    this.tableau.matrix[pivotRow]![col]! = 1
                    continue
                }

                if (this.tableau.matrix[pivotRow]![col]! === 0) { // avoid -0
                    continue
                }

                this.tableau.matrix[pivotRow]![col]! /= pivotValue
            }

            if (this.tableau.b[pivotRow] !== 0) {
                this.tableau.b[pivotRow]! /= pivotValue
            }
        }

        const makePivotColumnZeros = () => {
            const addRowToOther = (targetRow: number, multiplier: number) => {
                const addedRow = this.tableau.matrix[pivotRow]!.map(v => v === 0 ? 0 : v * multiplier)

                for (let col = 0; col < this.tableau.matrix[0]!.length; col++) {
                    this.tableau.matrix[targetRow]![col]! += addedRow[col]!
                }

                if (this.tableau.b[pivotRow] !== 0) {
                    this.tableau.b[targetRow]! += this.tableau.b[pivotRow]! * multiplier
                }
            }


            for (let row = 0; row < this.tableau.matrix.length; row++) {
                if (row === pivotRow || this.tableau.matrix[row]![pivotColumn] === 0) {
                    continue
                }

                const multiplier = -1 * this.tableau.matrix[row]![pivotColumn]! // pivot value is 1 at this point
                addRowToOther(row, multiplier)
            }
        }

        const changeBasis = () => {
            const currentBasis = this.tableau.basis[pivotRow]!
            const nextBasis = this.tableau.cj[pivotColumn]!

            this.tableau.basis[pivotRow] = nextBasis

            if (currentBasis.type !== VariableType.Artificial) {
                return // we only remove artificial variables
            }

            const columnToRemove = this.tableau.cj.findIndex(v => v === currentBasis) // it's the same ref
            for (let row = 0; row < this.tableau.matrix.length; row++) {
                this.tableau.matrix[row]!.splice(columnToRemove, 1)
            }
            this.tableau.cj.splice(columnToRemove, 1)
        }

        makePivotOne()
        makePivotColumnZeros()
        changeBasis()
    }

    private log() {
        console.log("cj")
        console.table(this.tableau.cj)
        console.log("matrix")
        console.table(this.tableau.matrix)
        console.log("b")
        console.table(this.tableau.b)
        console.log("basis")
        console.table(this.tableau.basis)
        console.log("zj")
        console.table(this.tableau.zj)
        console.log("cjzj")
        console.table(this.tableau.cjZj)
    }
}
