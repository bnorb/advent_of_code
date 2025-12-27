mod packet;

use self::packet::Packet;

pub fn part1(input: &str) -> usize {
    let pairs: Vec<(Packet, Packet)> = input
        .split("\n\n")
        .map(|pair| {
            let mut iter = pair.split("\n").map(|packet| Packet::parse(packet));
            (iter.next().unwrap(), iter.next().unwrap())
        })
        .collect();

    pairs
        .iter()
        .enumerate()
        .fold(0, |sum, (i, (a, b))| sum + if a <= b { i + 1 } else { 0 })
}

pub fn part2(input: &str) -> usize {
    let mut packets: Vec<Packet> = input
        .lines()
        .filter(|line| line.len() > 0)
        .map(|packet| Packet::parse(packet))
        .collect();

    packets.push(Packet::parse("[[2]]"));
    packets.push(Packet::parse("[[6]]"));
    packets.sort();

    let start = Packet::parse("[[2]]");
    let end = Packet::parse("[[6]]");

    let start = packets
        .iter()
        .enumerate()
        .find_map(|(i, packet)| if *packet == start { Some(i + 1) } else { None })
        .unwrap();

    let end = packets
        .iter()
        .enumerate()
        .find_map(|(i, packet)| if *packet == end { Some(i + 1) } else { None })
        .unwrap();

    start * end
}
