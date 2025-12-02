package main

import "../utils"
import "core:bytes"
import sa "core:container/small_array"
import "core:fmt"
import "core:math"
import "core:slice"
import "core:strconv"
import "core:testing"
import "core:time"

LB :: utils.LB

COMMA :: ','
DASH :: '-'

Range :: struct {
	min: int,
	max: int,
}

digit_count :: proc "contextless" (v: int) -> int {
	if v >= 0 && v < 10 do return 1
	else if v >= 10 && v < 100 do return 2
	else if v >= 100 && v < 1_000 do return 3
	else if v >= 1_000 && v < 10_000 do return 4
	else if v >= 10_000 && v < 100_000 do return 5
	else if v >= 100_000 && v < 1_000_000 do return 6
	else if v >= 1_000_000 && v < 10_000_000 do return 7
	else if v >= 10_000_000 && v < 100_000_000 do return 8
	else if v >= 100_000_000 && v < 1_000_000_000 do return 9
	else if v >= 1_000_000_000 && v < 10_000_000_000 do return 10
	else if v >= 10_000_000_000 && v < 100_000_000_000 do return 11
	else if v >= 100_000_000_000 && v < 1_000_000_000_000 do return 12
	else if v >= 1_000_000_000_000 && v < 10_000_000_000_000 do return 13
	else if v >= 10_000_000_000_000 && v < 100_000_000_000_000 do return 14
	else if v >= 100_000_000_000_000 && v < 1_000_000_000_000_000 do return 15
	else if v >= 1_000_000_000_000_000 && v < 10_000_000_000_000_000 do return 16
	else if v >= 10_000_000_000_000_000 && v < 100_000_000_000_000_000 do return 17
	else if v >= 100_000_000_000_000_000 && v < 1_000_000_000_000_000_000 do return 18
	else if v >= 1_000_000_000_000_000_000 && v < max(int) do return 19

	return -1
}

parse :: proc(data: ^[]byte, out: ^sa.Small_Array($N, Range)) {
	for r in bytes.split_iterator(data, []byte{COMMA}) {
		rng := Range{}
		start: int = -1
		ok: bool

		for b, i in r {
			if start == -1 do start = i

			switch b {
			case DASH:
				rng.min, _ = strconv.parse_int(string(r[start:i]))
				start = -1
			}
		}

		rng.max, _ = strconv.parse_int(string(r[start:]))

		sa.append_elem(out, rng)
	}
}

is_odd :: #force_inline proc "contextless" (v: int) -> bool {
	return v & 0x01 == 1
}

is_even :: #force_inline proc "contextless" (v: int) -> bool {
	return !is_odd(v)
}

@(test)
test_n_digits :: proc(t: ^testing.T) {
	values := []struct {
		v: int,
		d: int,
		r: int,
	} {


		// ols:nofmt
		{11, 2, 11},
		{11, 1, 1},
		{998, 1, 9},
		{1188511880, 2, 11},
		{1188511880, 5, 11885},
	}

	for v in values {
		testing.expect_value(t, n_digits(v.v, v.d), v.r)
	}
}

n_digits :: #force_inline proc "contextless" (value, n: int) -> int {
	return math.floor_div(value, int(math.pow10(f32(digit_count(value) - n))))
}

@(test)
test_valid_repeating :: proc(t: ^testing.T) {
	values := [][3]int {
		{11, 1, 1},
		{22, 1, 1},
		{999, 1, 1},
		{1010, 2, 1},
		{1188511885, 5, 1},
		{1188511885, 1, 1},
		{1188511885, 3, -1},
	}

	for v in values {
		testing.expect(
			t,
			valid_repeating(v.y, digit_count(v.x)) == (v.z == 1),
			fmt.tprintf("expected %v to return true"),
		)
	}
}

valid_repeating :: #force_inline proc "contextless" (digits, max_digits: int) -> bool {
	if digits < max_digits {
		return max_digits % digits == 0
	}

	return false
}

next_invalid_id_part1 :: proc "contextless" (range: Range, n: int = -1) -> (int, bool) {
	n := n < 0 ? range.min : n
	dmn := digit_count(n)
	dmx := digit_count(range.max)
	if dmn == dmx && is_odd(dmn) && is_odd(dmx) {
		// cannot have invalid ids
		return -1, false
	}

	p := int(math.pow10(f32(dmn / 2)))
	cmn: int = dmn
	c := n

	for c <= range.max {
		_cmn := digit_count(c)
		if !is_odd(_cmn) {
			if _cmn > cmn {
				cmn = _cmn
				p = int(math.pow10(f32(cmn / 2)))
			}

			m_top := math.floor_div(c, p)
			m_bottom := c - (m_top * p)

			if m_top == m_bottom {
				n_inv := m_top * p + m_top

				if n_inv >= n && n_inv <= range.max {
					return n_inv, true
				}
			}
		}

		c += 1
	}

	return -1, false
}

@(test)
test_fill_np :: proc(t: ^testing.T) {
	values := []struct {
		pattern: int,
		digits:  int,
		result:  int,
	} {


		// ols:nofmt
		{1, 1, 1},
		{1, 2, 11},
		{11, 2, 11},
		{9, 3, 999},
		{10, 4, 1010},
		{7, 5, 77777},
		{446, 6, 446446},
		{41, 6, 414141},
		{11885, 10, 1188511885},
	}

	for v in values {
		testing.expect_value(t, fill_np(v.pattern, v.digits), v.result)
	}
}

fill_np :: #force_inline proc "contextless" (pattern, d_len: int) -> int {
	acc := 0
	pl := digit_count(pattern)
	rd := d_len

	for rd > 0 {
		rd = rd - pl
		acc += pattern * int(math.pow10(f32(rd)))
	}

	return acc
}

next_invalid_id_part2 :: proc(range: Range) -> ([dynamic]int, bool) {
	n := range.min
	out := make([dynamic]int, 0, 10)

	if n <= range.max {
		dmn := digit_count(n)
		dmx := digit_count(range.max)

		for dc in dmn ..= dmx {
			for i in 1 ..< dc {
				if valid_repeating(i, dc) {
					for v in n ..= range.max {
						pattern := n_digits(v, i)
						c: int = v
						for c <= range.max {
							c = fill_np(pattern, dc)

							if c > range.max do break
							if c >= n && c <= range.max {
								if !slice.contains(out[:], c) {
									append(&out, c)
								}
							}

							pattern += 1
							if digit_count(pattern) > i do break
						}
					}
				}
			}
		}
	}

	return out, len(out) > 0
}

@(test)
p1_test :: proc(t: ^testing.T) {
	data := #load("./example_data", []byte)
	cntr := sa.Small_Array(11, Range){}
	parse(&data, &cntr)
	sum: int = part1(sa.slice(&cntr))

	testing.expect_value(t, sum, 1227775554)
}

part1 :: proc(ranges: []Range) -> int {
	sum: int = 0

	for r in ranges {
		inv_id: int = -2
		for {
			inv_id = next_invalid_id_part1(r, inv_id + 1) or_break
			sum += inv_id
			if inv_id > r.max {
				break
			}
		}
	}

	return sum
}

@(test)
p2_test :: proc(t: ^testing.T) {
	data := #load("./example_data", []byte)
	cntr := sa.Small_Array(11, Range){}
	parse(&data, &cntr)
	sum: int = part2(sa.slice(&cntr))

	testing.expect_value(t, sum, 4174379265)
}

part2 :: proc(ranges: []Range) -> int {
	sum: int = 0

	for r in ranges {
		idx, ok := next_invalid_id_part2(r)
		if ok {
			for id in idx {
				sum += id
			}
		}
		// delete(idx)
	}

	return sum
}

main :: proc() {
	t := time.Stopwatch{}
	time.stopwatch_start(&t)
	data := #load("./data", []byte)

	cntr := sa.Small_Array(128, Range){}
	parse(&data, &cntr)
	ranges := sa.slice(&cntr)
	time.stopwatch_stop(&t)

	d := time.stopwatch_duration(t)
	fmt.printfln("Parse time taken: %\n", d)

	time.stopwatch_reset(&t)

	time.stopwatch_start(&t)
	r := part1(ranges)
	time.stopwatch_stop(&t)

	d = time.stopwatch_duration(t)
	fmt.printfln("Part 1 time taken: %\n value: %v", d, "----")

	time.stopwatch_reset(&t)

	time.stopwatch_start(&t)
	r = part2(ranges)
	if r <= 74689883554 {
		fmt.printfln("Part 2 value is wrong")
	}
	time.stopwatch_stop(&t)

	d = time.stopwatch_duration(t)
	fmt.printfln("Part 2 time taken: %\n value: %v", d, "----")
}
