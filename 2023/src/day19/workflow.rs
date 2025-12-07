use std::collections::HashMap;

use itertools::Itertools;
use lazy_static::lazy_static;
use regex::Regex;

#[derive(Debug)]
pub enum Rule {
    GT(Property, usize),
    LT(Property, usize),
    DEFAULT,
}

#[derive(Hash, PartialEq, Eq, Debug, Clone, Copy)]
pub enum Property {
    X,
    M,
    A,
    S,
}

impl Property {
    fn parse(input: &str) -> Self {
        match input {
            "x" => Self::X,
            "m" => Self::M,
            "a" => Self::A,
            "s" => Self::S,
            _ => panic!(),
        }
    }
}

#[derive(Debug)]
pub enum Res {
    Approve,
    Reject,
    Forward(String),
}

lazy_static! {
    static ref PART_RE: Regex = Regex::new(r"^\{x=(\d+),m=(\d+),a=(\d+),s=(\d+)\}$").unwrap();
    static ref WORKFLOW_RE: Regex = Regex::new(r"^(\w+)\{(.+)\}$").unwrap();
}

pub struct Part(HashMap<Property, usize>, usize);

impl Part {
    pub fn parse(input: &str) -> Self {
        let cap = PART_RE.captures(input).unwrap();

        let nums: Vec<usize> = cap
            .iter()
            .skip(1)
            .map(|c| c.unwrap().as_str())
            .map(|c| c.parse::<usize>().unwrap())
            .collect();

        Self(
            HashMap::from([
                (Property::X, nums[0]),
                (Property::M, nums[1]),
                (Property::A, nums[2]),
                (Property::S, nums[3]),
            ]),
            nums.iter().sum(),
        )
    }

    pub fn sum(&self) -> usize {
        self.1
    }

    fn get_prop(&self, prop: &Property) -> &usize {
        &self.0[prop]
    }
}

#[derive(Debug)]
pub struct Workflow {
    id: String,
    switch: Vec<(Rule, Res)>,
}

impl Workflow {
    pub fn parse(input: &str) -> Self {
        let cap = WORKFLOW_RE.captures(input).unwrap();

        let (id, rules) = (cap[1].to_owned(), cap[2].to_owned());
        let switch = rules
            .split(",")
            .map(|rule| match rule.find(':') {
                None => (
                    Rule::DEFAULT,
                    match rule {
                        "A" => Res::Approve,
                        "R" => Res::Reject,
                        id => Res::Forward(id.to_owned()),
                    },
                ),
                Some(_) => {
                    let (rule, result) = rule.split(":").collect_tuple().unwrap();
                    let prop = Property::parse(&rule[0..1]);
                    let comparison = &rule[1..2];
                    let num = rule[2..].parse::<usize>().unwrap();

                    (
                        match comparison {
                            ">" => Rule::GT(prop, num),
                            "<" => Rule::LT(prop, num),
                            _ => panic!(),
                        },
                        match result {
                            "A" => Res::Approve,
                            "R" => Res::Reject,
                            id => Res::Forward(id.to_owned()),
                        },
                    )
                }
            })
            .collect();

        Self { id, switch }
    }

    pub fn copy_id(&self) -> String {
        self.id.clone()
    }

    pub fn process(&self, part: &Part) -> &Res {
        for (rule, result) in &self.switch {
            let passed = match rule {
                Rule::DEFAULT => true,
                Rule::GT(prop, num) => part.get_prop(prop) > num,
                Rule::LT(prop, num) => part.get_prop(prop) < num,
            };

            if passed {
                return result;
            }
        }

        panic!();
    }

    pub fn get_switch(&self) -> &Vec<(Rule, Res)> {
        &self.switch
    }
}
