use std::{
    cell::RefCell,
    collections::HashMap,
    rc::{Rc, Weak},
};

use lazy_static::lazy_static;
use regex::Regex;

lazy_static! {
    static ref RE: Regex = Regex::new(r"^([a-z\%\&]+)\s+->\s+(.+)$").unwrap();
}

#[derive(Clone, Debug)]
pub enum Signal {
    Low,
    High,
}

impl Signal {
    fn flip(&mut self) {
        *self = match *self {
            Signal::Low => Signal::High,
            Signal::High => Signal::Low,
        }
    }
}

#[derive(Debug)]
enum Type {
    FlipFlop(Signal),
    Conjuction(HashMap<String, (Signal, Option<usize>, Option<usize>)>),
    Broadcaster,
    Out,
}

#[derive(Debug)]
pub struct Module {
    name: String,
    outputs: Vec<(String, Weak<RefCell<Module>>)>,
    module_type: Type,
    counter: usize,
    lows: Vec<usize>,
}

impl Module {
    pub fn parse(input: &str) -> Self {
        let cap = RE.captures(input).unwrap();
        let mut name = &cap[1];
        let outputs = cap[2]
            .split(", ")
            .map(|out| (out.to_owned(), Weak::new()))
            .collect();

        let module_type = match name {
            "broadcaster" => Type::Broadcaster,
            s => {
                name = &name[1..];
                match s.chars().next().unwrap() {
                    '%' => Type::FlipFlop(Signal::Low),
                    '&' => Type::Conjuction(HashMap::new()),
                    _ => panic!(),
                }
            }
        };

        Self {
            name: name.to_owned(),
            outputs,
            module_type,
            counter: 0,
            lows: Vec::new(),
        }
    }

    pub fn out(name: String) -> Self {
        Self {
            module_type: Type::Out,
            name,
            outputs: Vec::new(),
            counter: 0,
            lows: Vec::new(),
        }
    }

    pub fn copy_name(&self) -> String {
        self.name.clone()
    }

    pub fn list_outputs(&self) -> Vec<String> {
        Box::new(self.outputs.iter().map(|(name, _)| name.clone())).collect()
    }

    pub fn link_output(&mut self, out: Rc<RefCell<Module>>) {
        let out_name = &out.borrow().name;

        let (_, link) = self
            .outputs
            .iter_mut()
            .find(|(name, _)| *out_name == *name)
            .unwrap();

        *link = Rc::downgrade(&out);
    }

    pub fn init_inputs(&mut self, inputs: Vec<String>) {
        if let Type::Conjuction(ref mut map) = self.module_type {
            inputs.into_iter().for_each(|input| {
                map.insert(input, (Signal::Low, None, None));
            });
        }
    }

    pub fn copy_memory(&self) -> Option<HashMap<String, (Signal, Option<usize>, Option<usize>)>> {
        match &self.module_type {
            Type::Conjuction(mem) => Some(mem.clone()),
            _ => None,
        }
    }

    pub fn increment(&mut self) {
        self.counter += 1;
    }

    pub fn get_lows(&self) -> Vec<usize> {
        self.lows.clone()
    }

    pub fn process(
        &mut self,
        input: &str,
        signal: Signal,
    ) -> Option<(Signal, Vec<Rc<RefCell<Module>>>)> {
        let outputs = self
            .outputs
            .iter()
            .map(|(_, out)| Weak::upgrade(&out).unwrap())
            .collect();

        match &mut self.module_type {
            Type::Broadcaster => Some((signal, outputs)),
            Type::FlipFlop(ref mut last_signal) => match signal {
                Signal::High => None,
                Signal::Low => {
                    last_signal.flip();
                    Some((last_signal.clone(), outputs))
                }
            },
            Type::Conjuction(memory) => {
                let (mem_sig, mem_first, mem_period) = memory.get_mut(input).unwrap();
                *mem_sig = signal.clone();

                if let Signal::High = signal {
                    if let Some(first) = mem_first {
                        if let None = mem_period {
                            *mem_period = Some(self.counter - *first);
                        }
                    } else {
                        *mem_first = Some(self.counter);
                    }
                }

                let out_signal = if memory.iter().all(|(_, (sig, _, _))| match sig {
                    Signal::High => true,
                    Signal::Low => false,
                }) {
                    self.lows.push(self.counter);
                    Signal::Low
                } else {
                    Signal::High
                };

                Some((out_signal, outputs))
            }
            Type::Out => None,
        }
    }
}
