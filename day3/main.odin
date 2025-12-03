package main

import "../utils"
import "core:bytes"
import sa "core:container/small_array"
import "core:fmt"
import "core:math"
import "core:slice"
import "core:testing"
import "core:time"

LB :: utils.LB

h_int :: #force_inline proc "contextless" (b: byte) -> int {
	return int(b - 0x30)
}

@(test)
p1_test :: proc(t: ^testing.T) {
	data := #load("./example_data", []byte)
	sum: int = part1(&data)

	testing.expect_value(t, sum, 357)
}

part1 :: proc(data: ^[]byte) -> int {
	sum: int = 0
	for r in bytes.split_iterator(data, LB) {
		l1, l2: u8
		l1i, l2i: int = -1, -1

		for c, i in r {
			if i < len(r) - 1 && l1 < c {
				l1 = c
				l1i = i
				if c == '9' do break
			}
		}

		for c, i in r[l1i + 1:] {
			if l2 < c {
				l2 = c
				l2i = l1i + i
			}
		}
		value := h_int(l1) * 10 + h_int(l2)
		sum += value
	}

	return sum
}

@(test)
p2_test :: proc(t: ^testing.T) {
	data := #load("./example_data", []byte)
	sum: u64 = part2(&data, 15)

	testing.expect_value(t, sum, 3121910778619)
}

part2 :: proc(data: ^[]byte, $width: $N/int) -> u64 {
	sum: u64
	k :: 12
	for r in bytes.split_iterator(data, LB) {
		res: sa.Small_Array(k, int)
		start: int = 0

		s: [width]int
		for c, i in r {
			s[i] = h_int(c)
		}

		for sa.len(res) < k {
			rem := k - sa.len(res)
			end := width - rem

			idx := slice.max_index(s[start:end + 1])
			pos := start + idx
			h := s[pos]

			sa.append(&res, h)
			start = pos + 1
		}

		exp := k - 1
		value: u64 = 0

		for v in sa.slice(&res) {
			if v != -1 {
				m := int(math.pow10(f64(exp)))
				value += u64(v * m)
				exp -= 1
			}
		}

		sum += value
	}

	return sum
}

main :: proc() {
	t := time.Stopwatch{}
	data := #load("./data", []byte)
	time.stopwatch_start(&t)
	r := part1(&data)
	time.stopwatch_stop(&t)

	d := time.stopwatch_duration(t)
	fmt.printfln("Part 1 time taken: %\n value: %v", d, r)

	time.stopwatch_reset(&t)

	time.stopwatch_start(&t)
	data = #load("./data", []byte)
	r2 := part2(&data, 100)
	time.stopwatch_stop(&t)

	d = time.stopwatch_duration(t)
	fmt.printfln("Part 2 time taken: %\n value: %v", d, r2)
}
