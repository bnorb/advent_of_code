use std::{cmp::Ordering, fmt::Display};

use itertools::Itertools;

#[derive(PartialEq, PartialOrd, Eq, Ord, Clone, Copy, Hash, Debug)]
struct Card(u8);

impl Card {
    pub fn new(val: char, use_joker: bool) -> Self {
        Card(match val {
            'T' => 10,
            'J' if use_joker => 1,
            'J' => 11,
            'Q' => 12,
            'K' => 13,
            'A' => 14,
            num => num.to_string().parse().unwrap(),
        })
    }
}

#[derive(PartialEq, PartialOrd, Eq, Ord, Clone, Copy, Debug)]
struct HandType(u8);

impl HandType {
    fn calc_type_simple(cards: &[Card; 5]) -> Self {
        let unique_groups = cards.iter().counts();
        if unique_groups.len() == 1 {
            return HandType(6); // 5 of a kind (lol)
        }

        if unique_groups.iter().any(|(_, count)| *count == 4) {
            return HandType(5); // poker (camel?)
        }

        if unique_groups.iter().any(|(_, count)| *count == 3) {
            if unique_groups.len() == 2 {
                return HandType(4); // fullhouse
            }

            return HandType(3); // drill
        }

        let pairs = unique_groups
            .into_iter()
            .filter(|(_, count)| *count == 2)
            .count();
        return HandType(pairs as u8); // 2 pairs, 1 pair, highcard
    }

    fn calc_type_joker(cards: &[Card; 5]) -> Self {
        if !cards.iter().any(|card| card.0 == 1) {
            return Self::calc_type_simple(cards);
        }

        let unique_groups = cards.iter().counts();
        let number_of_jokers = *unique_groups.get(&Card(1)).unwrap();

        if number_of_jokers >= 4 {
            return HandType(6);
        }

        if unique_groups.len() == 2 {
            return HandType(6);
        }

        if number_of_jokers == 3 {
            return HandType(5);
        }

        if number_of_jokers == 2 {
            if unique_groups.len() == 3 {
                return HandType(5);
            }

            return HandType(3);
        }

        if unique_groups.len() == 3 {
            if unique_groups.iter().any(|(_, count)| *count == 3) {
                return HandType(5);
            }

            return HandType(4);
        }

        if unique_groups.len() == 4 {
            return HandType(3);
        }

        return HandType(1);
    }

    pub fn new(cards: &[Card; 5], use_joker: bool) -> Self {
        match use_joker {
            false => Self::calc_type_simple(cards),
            true => Self::calc_type_joker(cards),
        }
    }
}

#[derive(PartialEq, Eq, Debug)]
pub struct Hand {
    cards: [Card; 5],
    display: String,
    hand_type: HandType,
}

impl Display for Hand {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.display)
    }
}

impl Hand {
    pub fn new(input: &str, use_joker: bool) -> Self {
        let mut cards: [Card; 5] = [Card(0); 5];
        input
            .chars()
            .map(|char| Card::new(char, use_joker))
            .enumerate()
            .for_each(|(idx, card)| {
                cards[idx] = card;
            });

        let hand_type = HandType::new(&cards, use_joker);
        Hand {
            cards,
            hand_type,
            display: String::from(input),
        }
    }
}

impl PartialOrd for Hand {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        match self.hand_type.partial_cmp(&other.hand_type) {
            Some(Ordering::Equal) => self.cards.partial_cmp(&other.cards),
            ord => ord,
        }
    }
}

impl Ord for Hand {
    fn cmp(&self, other: &Self) -> Ordering {
        match self.partial_cmp(&other) {
            None => Ordering::Equal,
            Some(ord) => ord,
        }
    }
}
