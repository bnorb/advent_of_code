use itertools::Itertools;

fn parse_input(input: &str) -> Vec<(Vec<String>, Vec<String>)> {
    input
        .split("\n\n")
        .map(|pattern| {
            let rows: Vec<String> = pattern.lines().map(|l| l.to_owned()).collect();
            let mut cols: Vec<String> = Vec::new();

            for i in 0..rows[0].len() {
                let mut col = Vec::new();
                for j in 0..rows.len() {
                    col.push(rows[j].chars().skip(i).next().unwrap())
                }

                cols.push(col.into_iter().join(""))
            }

            (rows, cols)
        })
        .collect()
}

fn find_smudgy_mirror((rows, cols): &(Vec<String>, Vec<String>)) -> (usize, usize) {
    let mut rows: Vec<String> = rows.iter().map(|s| s.clone()).collect();
    let mut cols: Vec<String> = cols.iter().map(|s| s.clone()).collect();

    let (og_rc, og_cc) = (find_mirror(&rows, None), find_mirror(&cols, None));

    for r in 0..rows.len() {
        for c in 0..cols.len() {
            let char = rows[r].chars().skip(c).next().unwrap().to_string();
            let replacement = if char == "." { "#" } else { "." };
            rows[r].replace_range(c..c + 1, replacement);
            cols[c].replace_range(r..r + 1, replacement);

            let (r_c, c_c) = (
                find_mirror(&rows, Some(og_rc)),
                find_mirror(&cols, Some(og_cc)),
            );

            if r_c > 0 || c_c > 0 {
                return (r_c, c_c);
            }

            rows[r].replace_range(c..c + 1, &char);
            cols[c].replace_range(r..r + 1, &char);
        }
    }

    panic!("can't happen")
}

fn find_mirror(vectors: &Vec<String>, skipped: Option<usize>) -> usize {
    let mut potentials = Vec::new();

    for e in 1..vectors.len() {
        let s = e - 1;
        if skipped.map_or(true, |v| e != v) && vectors[s] == vectors[e] {
            potentials.push((s, e));
        }
    }

    'outer: for (s, e) in potentials {
        let (mut i, mut j) = (s as isize, e);
        while i >= 0 && j < vectors.len() {
            if vectors[i as usize] != vectors[j] {
                continue 'outer;
            }
            i -= 1;
            j += 1;
        }

        return e;
    }

    0
}

pub fn part1(input: &str) -> usize {
    let patterns = parse_input(input);

    patterns
        .iter()
        .map(|(rows, cols)| (find_mirror(rows, None), find_mirror(cols, None)))
        .map(|(r_c, c_c)| 100 * r_c + c_c)
        .sum()
}

pub fn part2(input: &str) -> usize {
    let patterns = parse_input(input);

    patterns
        .iter()
        .map(|pattern| find_smudgy_mirror(pattern))
        .map(|(r_c, c_c)| 100 * r_c + c_c)
        .sum()
}
