use std::{
    collections::{HashMap, HashSet},
    fs::File,
    io::Write,
    process::Command,
};

use itertools::Itertools;

pub fn create_graph(input: &str) {
    let mut file = File::create("./day25.dot").expect("failed to create dot file");
    file.write("graph {\n".as_bytes()).unwrap();

    input.lines().for_each(|line| {
        let from = line.split(":").next().unwrap();
        let to: String = line
            .split(":")
            .skip(1)
            .next()
            .unwrap()
            .trim()
            .split_whitespace()
            .join(", ");

        file.write(format!("  {} -- {{{}}}\n", from, to).as_bytes())
            .unwrap();
    });
    file.write("}".as_bytes()).unwrap();

    Command::new("dot")
        .arg("-Tsvg")
        .arg("./day25.dot")
        .arg("-o")
        .arg("./day25.svg")
        .arg("-Kneato")
        .spawn()
        .expect("failed to create vg from dot file");
}

pub fn part1(input: &str) -> usize {
    create_graph(input);

    let mut map: HashMap<&str, HashSet<&str>> = HashMap::new();

    input.lines().for_each(|line| {
        let from = line.split(":").next().unwrap();
        let to: HashSet<&str> = line
            .split(":")
            .skip(1)
            .next()
            .unwrap()
            .trim()
            .split_whitespace()
            .collect();

        if let Some(curr) = map.get_mut(from) {
            curr.extend(&to);
        } else {
            map.insert(from, to.clone());
        }

        for node in to {
            if let Some(curr) = map.get_mut(node) {
                curr.insert(from);
            } else {
                map.insert(node, HashSet::from([from]));
            }
        }
    });

    // from graphviz
    // jkn-cfn
    // gst-rph
    // ljm-sfd

    map.get_mut("jkn").unwrap().remove("cfn");
    map.get_mut("cfn").unwrap().remove("jkn");
    map.get_mut("gst").unwrap().remove("rph");
    map.get_mut("rph").unwrap().remove("gst");
    map.get_mut("ljm").unwrap().remove("sfd");
    map.get_mut("sfd").unwrap().remove("ljm");

    let mut visited = HashSet::from(["jkn"]);
    cnt("jkn", &map, &mut visited);
    let side_a = visited.len();

    let mut visited = HashSet::from(["cfn"]);
    cnt("cfn", &map, &mut visited);
    let side_b = visited.len();

    side_a * side_b
}

fn cnt<'a>(curr: &str, map: &HashMap<&str, HashSet<&'a str>>, visited: &mut HashSet<&'a str>) {
    for next in map.get(curr).unwrap() {
        if !visited.contains(next) {
            visited.insert(next);
            cnt(next, map, visited);
        }
    }
}

pub fn part2(_input: &str) -> u8 {
    //stub
    0
}
