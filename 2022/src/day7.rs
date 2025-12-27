mod tree;

use self::tree::Node;
use std::{cell::RefCell, rc::Rc};

fn parse_input(input: &str) -> Rc<RefCell<Node>> {
    tree::parse(input)
}

pub fn part1(input: &str) -> u32 {
    let root = parse_input(input);

    let mut nodes = vec![Rc::clone(&root)];
    nodes.extend(root.borrow().flatten_children());

    nodes
        .iter()
        .map(|node| node.borrow_mut().size())
        .filter(|size| *size <= 100000)
        .sum()
}

pub fn part2(input: &str) -> u32 {
    let root = parse_input(input);

    let mut nodes = vec![Rc::clone(&root)];
    nodes.extend(root.borrow().flatten_children());

    let needed = 30000000 - (70000000 - root.borrow_mut().size());

    nodes
        .iter()
        .map(|node| node.borrow_mut().size())
        .filter(|size| *size >= needed)
        .min()
        .unwrap()
}
