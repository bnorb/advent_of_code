use std::collections::HashMap;

use itertools::Itertools;

use self::workflow::{Part, Property, Res, Rule, Workflow};

mod workflow;

fn parse_input(input: &str) -> (HashMap<String, Workflow>, Vec<Part>) {
    let (workflows, parts) = input.split("\n\n").collect_tuple().unwrap();

    let workflows = HashMap::from_iter(workflows.lines().map(|workflow| {
        let w = Workflow::parse(workflow);
        (w.copy_id(), w)
    }));

    let parts = parts.lines().map(|part| Part::parse(part)).collect();

    (workflows, parts)
}

fn find_all_approved(
    workflows: &HashMap<String, Workflow>,
    curr: &Workflow,
    ranges: HashMap<Property, (usize, usize)>,
) -> usize {
    let mut accepted = 0;
    let mut non_matching = HashMap::clone(&ranges);

    for (rule, result) in curr.get_switch() {
        let mut matching = HashMap::clone(&non_matching);

        match rule {
            Rule::DEFAULT => {}
            Rule::LT(prop, num) => {
                let (lower_nm, _) = non_matching.get_mut(prop).unwrap();
                let (_, upper_m) = matching.get_mut(prop).unwrap();

                *upper_m = (*num - 1).min(*upper_m);
                *lower_nm = (*num).max(*lower_nm);
            }
            Rule::GT(prop, num) => {
                let (_, upper_nm) = non_matching.get_mut(prop).unwrap();
                let (lower_m, _) = matching.get_mut(prop).unwrap();

                *lower_m = (*num + 1).max(*lower_m);
                *upper_nm = (*num).min(*upper_nm);
            }
        }

        match result {
            Res::Reject => {}
            Res::Approve => {
                // assumes upper >= lower
                accepted += matching
                    .into_iter()
                    .map(|(_, (lower, upper))| upper - lower + 1)
                    .reduce(|prod, d| prod * d)
                    .unwrap();
            }
            Res::Forward(next_id) => {
                accepted += find_all_approved(workflows, workflows.get(next_id).unwrap(), matching);
            }
        }
    }

    accepted
}

pub fn part1(input: &str) -> usize {
    let (workflows, parts) = parse_input(input);

    let init_workflow = workflows.get("in").unwrap();
    let mut sum = 0;

    parts.iter().for_each(|part| {
        let mut curr_workflow = init_workflow;
        loop {
            match curr_workflow.process(part) {
                Res::Approve => {
                    sum += part.sum();
                    break;
                }
                Res::Reject => {
                    break;
                }
                Res::Forward(id) => {
                    curr_workflow = workflows.get(id).unwrap();
                }
            }
        }
    });

    sum
}

pub fn part2(input: &str) -> usize {
    let (workflows, _) = parse_input(input);

    let init_workflow = workflows.get("in").unwrap();
    let ranges = HashMap::from([
        (Property::X, (1, 4000)),
        (Property::M, (1, 4000)),
        (Property::A, (1, 4000)),
        (Property::S, (1, 4000)),
    ]);

    find_all_approved(&workflows, init_workflow, ranges)
}
