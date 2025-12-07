use std::{
    cell::RefCell,
    collections::{HashMap, LinkedList},
    rc::Rc,
};

use self::module::{Module, Signal};

mod module;

fn parse_input(input: &str) -> (HashMap<String, Rc<RefCell<Module>>>, Vec<String>) {
    let mut modules = HashMap::from_iter(
        input
            .lines()
            .map(|line| Module::parse(line))
            .map(|module| (module.copy_name(), Rc::new(RefCell::new(module)))),
    );

    let mut inputs: HashMap<String, Vec<String>> = HashMap::new();

    modules.iter().for_each(|(name, module)| {
        let module = module.borrow();

        module
            .list_outputs()
            .iter()
            .for_each(|out| match inputs.get_mut(out) {
                None => {
                    inputs.insert(out.clone(), Vec::from([name.clone()]));
                }
                Some(list) => list.push(name.clone()),
            });
    });

    let mut out = None;
    let mut last_con = None;

    modules.iter().for_each(|(name, module_rc)| {
        let mut module = module_rc.borrow_mut();
        if let Some(input_list) = inputs.remove(name) {
            module.init_inputs(input_list);
        }

        module.list_outputs().iter().for_each(|out_name| {
            if let Some(out) = modules.get(out_name) {
                module.link_output(Rc::clone(out));
            } else {
                let o = Rc::new(RefCell::new(Module::out(out_name.clone())));
                module.link_output(Rc::clone(&o));
                out = Some(o);
                last_con = Some(Rc::clone(&module_rc));
            }
        });
    });

    let out = out.unwrap();
    let out_name = out.borrow().copy_name();
    modules.insert(out_name, out);

    let mut cycling_ones = Vec::new();

    // structure is rx <- last <- n inverters <- (for each) 1 cycling one
    let last_memo = last_con.unwrap().borrow().copy_memory().unwrap();
    for (inverter, _) in last_memo {
        let module = modules.get(&inverter).unwrap().borrow();
        let memo = module.copy_memory().unwrap();
        assert!(memo.len() == 1);

        cycling_ones.push(memo.into_iter().next().unwrap().0);
    }

    (modules, cycling_ones)
}

fn push_button(modules: &HashMap<String, Rc<RefCell<Module>>>) -> (usize, usize) {
    let mut queue = LinkedList::from([(
        String::from("button"),
        Signal::Low,
        Rc::clone(modules.get("broadcaster").unwrap()),
    )]);

    let mut low_cnt = 0;
    let mut high_cnt = 0;

    while !queue.is_empty() {
        let (input, signal, module) = queue.pop_front().unwrap();
        let mut module = module.borrow_mut();

        match signal {
            Signal::Low => low_cnt += 1,
            Signal::High => high_cnt += 1,
        }

        if let Some((signal, outputs)) = module.process(input.as_str(), signal) {
            outputs
                .into_iter()
                .for_each(|out| queue.push_back((module.copy_name(), signal.clone(), out)));
        }
    }

    (low_cnt, high_cnt)
}

fn gcd(a_start: usize, b_start: usize) -> usize {
    let mut a = a_start;
    let mut b = b_start;

    // recursive algo runs out of stack on default rust config
    loop {
        if a == b {
            return a;
        }

        if a > b {
            a = a - b;
            continue;
        }

        b = b - a;
    }
}
fn lcm(a: usize, b: usize) -> usize {
    a * b / gcd(a, b)
}

pub fn part1(input: &str) -> usize {
    let (modules, _) = parse_input(input);

    let mut low_cnt = 0;
    let mut high_cnt = 0;

    for _ in 0..1000 {
        let (low, high) = push_button(&modules);
        low_cnt += low;
        high_cnt += high;
    }

    low_cnt * high_cnt
}

pub fn part2(input: &str) -> usize {
    let (modules, cycling_ones) = parse_input(input);

    let cycling_modules: Vec<Rc<RefCell<Module>>> = cycling_ones
        .iter()
        .map(|name| Rc::clone(modules.get(name).unwrap()))
        .collect();

    loop {
        cycling_modules
            .iter()
            .for_each(|cm| cm.borrow_mut().increment());

        push_button(&modules);
        if cycling_modules
            .iter()
            .all(|cm| cm.borrow().get_lows().len() >= 1)
        {
            break;
        }
    }

    cycling_modules
        .into_iter()
        .map(|module| module.borrow().get_lows()[0])
        .reduce(|full_period, period| lcm(full_period, period))
        .unwrap()
}
