package range

import "core:strconv"
import "core:testing"

DASH :: '-'

EMPTY_RANGE :: Range{-1, 0}

Range :: struct {
	min: int,
	max: int,
}


parse :: proc(r: []byte) -> Range {
	rng: Range
	start: int = -1

	for b, i in r {
		if start == -1 do start = i

		switch b {
		case DASH:
			rng.min, _ = strconv.parse_int(string(r[start:i]))
			start = -1
		}
	}

	rng.max, _ = strconv.parse_int(string(r[start:]))

	return rng
}
Comparision :: enum u8 {
	LowerInclusive,
	UpperInclusive,
}

Comparision_Set :: bit_set[Comparision]

within :: #force_inline proc "contextless" (
	v: int,
	range: Range,
	cmp: Comparision_Set = {.LowerInclusive, .UpperInclusive},
) -> bool {
	if .LowerInclusive in cmp && .UpperInclusive in cmp {
		return v >= range.min && v <= range.max
	} else if .LowerInclusive not_in cmp && .UpperInclusive in cmp {
		return v > range.min && v <= range.max
	} else if .LowerInclusive in cmp && .UpperInclusive not_in cmp {
		return v >= range.min && v < range.max
	} else {
		return v > range.min && v < range.max
	}
}

union_join :: #force_inline proc "contextless" (r1, r2: Range) -> Range {
	return Range{min = min(r1.min, r2.min), max = max(r1.max, r2.max)}
}

overlap :: #force_inline proc "contextless" (r1, r2: Range) -> bool {
	return max(r1.min, r2.min) <= min(r1.max, r2.max)
}

intersect :: #force_inline proc "contextless" (r1, r2: Range) -> bool {
	return !(r1.min > r2.max && r1.max < r2.min)
}

intersection :: #force_inline proc "contextless" (r1, r2: Range) -> Range {
	if !intersect(r1, r2) do return Range{0, -1}

	return Range{min = max(r1.min, r2.min), max = min(r1.max, r2.max)}
}

diff :: #force_inline proc "contextless" (
	r1, r2: Range,
	cmp: Comparision_Set = {.LowerInclusive, .UpperInclusive},
) -> Range {
	if !intersect(r1, r2) do return r1
	else if r2.min <= r1.min && r2.max >= r1.max do return Range{0, -1}
	min_offset := .LowerInclusive in cmp ? 0 : 1
	max_offset := .UpperInclusive in cmp ? 0 : -1

	return Range {
		min = r2.max < r1.max + min_offset ? max(r1.min, r2.max + min_offset) : r1.min,
		max = r2.min > r1.min + max_offset ? min(r1.max, r2.min + max_offset) : r1.max,
	}
}

count :: #force_inline proc "contextless" (r: Range) -> int {
	if r.min == r.max do return 1
	if r.max < r.min do return 0
	return r.max - (r.min - 1)
}

@(private)
Test_Range :: struct {
	r1:  Range,
	r2:  Range,
	exp: Range,
	cmp: Comparision_Set,
}

@(test)
test_diff :: proc(t: ^testing.T) {
	// odinfmt: disable
	tests := [?]Test_Range {
		{r1 = {0, 10}, r2 = {5, 12}, exp = {0, 5}, cmp={.LowerInclusive, .UpperInclusive}},
		{r1 = {5, 10}, r2 = {3, 7}, exp = {7, 10}, cmp={.LowerInclusive, .UpperInclusive}},
		{r1 = {5, 7}, r2 = {3, 12}, exp = {0, -1}, cmp={.LowerInclusive, .UpperInclusive}},
		{r1 = {5, 7}, r2 = {5, 6}, exp = {6, 7}, cmp={.LowerInclusive, .UpperInclusive}},
		{r1 = {5, 7}, r2 = {5, 7}, exp = {0, -1}, cmp={.LowerInclusive, .UpperInclusive}},
		{r1 = {0, 10}, r2 = {5, 5}, exp = {0, 5}, cmp={.LowerInclusive, .UpperInclusive}},
		{r1 = {0, 10}, r2 = {5, 9}, exp = {0, 4}},
		{r1 = {6, 10}, r2 = {5, 9}, exp = {10, 10}},
		{r1 = {0, 10}, r2 = {5, 5}, exp = {0, 4}},
		{r1 = {0, 10}, r2 = {8, 9}, exp = {0, 7}},
		{r1 = {5, 5}, r2 = {0, 10}, exp = {0, -1}},
		{r1 = {0, 10}, r2 = {5, 12}, exp = {0, 4}},
		{r1 = {5, 10}, r2 = {3, 7}, exp = {8, 10}},
		{r1 = {5, 7}, r2 = {3, 12}, exp = {0, -1}},
		{r1 = {5, 7}, r2 = {5, 6}, exp = {7, 7}},
	}
	// odinfmt: enable

	for test in tests {
		testing.expect_value(t, diff(test.r1, test.r2, test.cmp), test.exp)
	}
}
