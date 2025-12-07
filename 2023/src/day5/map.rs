use itertools::Itertools;

#[derive(Debug)]
struct RangeMapping {
    source: (i64, i64),
    destination: (i64, i64),
}

impl RangeMapping {
    fn source_in_range(&self, source: i64) -> bool {
        return self.source.0 <= source && self.source.1 > source;
    }

    fn get_destination(&self, source: i64) -> Option<i64> {
        if !self.source_in_range(source) {
            return None;
        }

        return Some(source + self.offset());
    }

    fn does_overlap(&self, source_range: (i64, i64)) -> bool {
        return self.source.1 >= source_range.0 && self.source.0 < source_range.1;
    }

    fn offset(&self) -> i64 {
        self.destination.0 - self.source.0
    }
}

#[derive(Debug)]
pub struct Map {
    range_mappings: Vec<RangeMapping>,
}

impl Map {
    pub fn new(values: Vec<(i64, i64, i64)>) -> Self {
        return Map {
            range_mappings: values
                .into_iter()
                .sorted_by(|(_, a_src_start, ..), (_, b_src_start, ..)| {
                    a_src_start.cmp(b_src_start)
                })
                .map(|(dst_start, src_start, len)| RangeMapping {
                    source: (src_start, src_start + len),
                    destination: (dst_start, dst_start + len),
                })
                .collect(),
        };
    }

    pub fn translate(&self, src: i64) -> i64 {
        for range_mapping in &self.range_mappings {
            if let Some(dst) = range_mapping.get_destination(src) {
                return dst;
            }
        }

        return src;
    }

    pub fn get_possible_ranges(&self, src_ranges: &Vec<(i64, i64)>) -> Vec<(i64, i64)> {
        let mut dst_ranges = Vec::new();

        for src_range in src_ranges {
            let overlapping_iter = self
                .range_mappings
                .iter()
                .filter(|range_mapping| range_mapping.does_overlap(*src_range));

            let mut last_cutoff = src_range.0;
            for range_mapping in overlapping_iter {
                // sorted!
                if last_cutoff < range_mapping.source.0 {
                    dst_ranges.push((last_cutoff, range_mapping.source.0))
                }

                let start = range_mapping.source.0.max(src_range.0);
                let end = range_mapping.source.1.min(src_range.1);

                dst_ranges.push((start + range_mapping.offset(), end + range_mapping.offset()));
                last_cutoff = end;
            }

            if last_cutoff < src_range.1 {
                dst_ranges.push((last_cutoff, src_range.1))
            }
        }

        dst_ranges
    }
}
