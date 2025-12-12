export class Shape {
    public readonly cells: boolean[][] = [];
    public readonly filledCells = 0;

    public constructor(str: string) {
        const [_, ...rows] = str.split("\n")
        const r = []

        for (let row of rows) {
            const cells = row.split("")
            for (let cell of cells) {
                if (cell === "#") {
                    this.filledCells++;
                }
                
                r.push(cell === "#");
            }
            this.cells.push(r);
        }
    }

}