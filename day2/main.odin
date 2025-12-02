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
	if v < 10 do return 1
	else if v < 100 do return 2
	else if v < 1_000 do return 3
	else if v < 10_000 do return 4
	else if v < 100_000 do return 5
	else if v < 1_000_000 do return 6
	else if v < 10_000_000 do return 7
	else if v < 100_000_000 do return 8
	else if v < 1_000_000_000 do return 9
	else if v < 10_000_000_000 do return 10
	else if v < 100_000_000_000 do return 11
	else if v < 1_000_000_000_000 do return 12
	else if v < 10_000_000_000_000 do return 13
	else if v < 100_000_000_000_000 do return 14
	else if v < 1_000_000_000_000_000 do return 15
	else if v < 10_000_000_000_000_000 do return 16
	else if v < 100_000_000_000_000_000 do return 17
	else if v < 1_000_000_000_000_000_000 do return 18
	else if v < max(int) do return 19

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
	if value == 0 do return 0
	return math.floor_div(value, int(math.pow10(f32(digit_count(value) - n))))
}

@(test)
test_ni_digits :: proc(t: ^testing.T) {
	values := []struct {
		v: int,
		d: int,
		i: int,
		r: int,
	} {


		// ols:nofmt
		{1188511880, 2, 0, 11},
		{1188511880, 5, 0, 11885},
		{1188511880, 2, 1, 18},
		{1188511880, 5, 4, 51188},
		{1188511880, 1, 9, 0},
	}

	for v in values {
		x := ni_digits(v.v, v.d, v.i)
		fmt.println(x)
		testing.expect_value(t, x, v.r)
	}
}

ni_digits :: #force_inline proc "contextless" (value, n: int, i: int = 0) -> int {
	i := i
	value := value
	if i > 0 {
		dc := digit_count(value)
		pw := int(math.pow10(f32(dc - i)))
		top := math.floor_div(value, pw)
		tv := top * pw

		nv := value - tv
		if nv < (pw / 10) {
			return 0
		}

		return n_digits(nv, n)
	}

	return n_digits(value, n)
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

part2_compute :: proc(range: Range, acc: ^int) {
	l1:
	for v in range.min ..= range.max {
		dc := digit_count(v)

		l2: for chunk_size in 1 ..< dc {
			if valid_repeating(chunk_size, dc) {
				chunk := n_digits(v, chunk_size)
				chunk_offset := chunk_size
				for chunk_offset < dc {
					_chunk := ni_digits(v, chunk_size, chunk_offset)
					if _chunk != chunk {
						continue l2
					}
					chunk_offset += chunk_size
				}

				acc^ += v
				continue l1
			}
		}
	}
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
		part2_compute(r, &sum)
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
	fmt.printfln("Part 1 time taken: %\n value: %v", d, r)

	time.stopwatch_reset(&t)

	time.stopwatch_start(&t)
	r = part2(ranges)
	time.stopwatch_stop(&t)

	d = time.stopwatch_duration(t)
	fmt.printfln("Part 2 time taken: %\n value: %v", d, r)
}
