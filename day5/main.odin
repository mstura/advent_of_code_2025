package main

import "../utils"
import "../utils/range"
import "core:bytes"
import sa "core:container/small_array"
import "core:fmt"
import "core:math"
import "core:slice"
import "core:strconv"
import "core:testing"
import "core:time"

LB :: utils.LB
Range :: range.Range
COMMA :: utils.COMMA
DASH :: utils.DASH

parse_ranges :: proc(data: ^[]byte, out: ^sa.Small_Array($N, Range)) {
	for r in bytes.split_iterator(data, LB) {
		if len(r) == 0 do return
		rng := range.parse(r)
		sa.append_elem(out, rng)
	}
}

parse_ids :: proc(data: ^[]byte, out: ^sa.Small_Array($N, int)) {
	for r in bytes.split_iterator(data, LB) {
		i, _ := strconv.parse_int(string(r))
		sa.append_elem(out, i)
	}
}

@(test)
p1_test :: proc(t: ^testing.T) {
	data := #load("./example_data", []byte)
	r := part1(&data, 4, 6)

	testing.expect_value(t, r, 3)
}

part1 :: proc(data: ^[]byte, $R, $I: int) -> int {
	ranges: sa.Small_Array(R, Range)
	ids: sa.Small_Array(I, int)
	parse_ranges(data, &ranges)
	parse_ids(data, &ids)
	sum: int


	for id in sa.slice(&ids) {
		for rg in sa.slice(&ranges) {
			if range.within(id, rg) {
				sum += 1
				break
			}

		}
	}

	return sum
}

@(test)
p2_test :: proc(t: ^testing.T) {
	data := #load("./example_data", []byte)
	r := part2(&data, 4)

	testing.expect_value(t, r, 14)
}

part2 :: proc(data: ^[]byte, $R: int) -> int {
	ranges: sa.Small_Array(R, Range)
	parse_ranges(data, &ranges)
	sum: int
	rng_sl := sa.slice(&ranges)

	slice.sort_by(rng_sl, proc(a, b: Range) -> bool {
		return a.min < b.min
	})

	for rg, x in rng_sl {
		r: Range = rg
		rngl := rng_sl[x + 1:]
		if rg == range.EMPTY_RANGE do continue

		for rgd, y in rngl {
			if range.overlap(r, rgd) {
				r = range.union_join(r, rgd)
				rngl[y] = range.EMPTY_RANGE
			}
		}

		sum += range.count(r)
	}

	return sum
}

main :: proc() {
	t := time.Stopwatch{}
	data := #load("./data", []byte)
	time.stopwatch_start(&t)
	r := part1(&data, 167, 1000)
	time.stopwatch_stop(&t)

	d := time.stopwatch_duration(t)
	fmt.printfln("Part 1 time taken: %\n value: %v", d, r)

	time.stopwatch_reset(&t)

	time.stopwatch_start(&t)
	data = #load("./data", []byte)
	r2 := part2(&data, 167)
	time.stopwatch_stop(&t)

	d = time.stopwatch_duration(t)
	fmt.printfln("Part 2 time taken: %\n value: %v", d, r2)
}
