package main

import "core:bytes"
import sa "core:container/small_array"
import "core:fmt"
import "core:math"
import "core:strconv"
import "core:testing"
import "core:time"

LB :: []byte{0x0d, 0x0a}

Dial :: struct {
	value: i16,
	pwd:   u16,
}

_actions: sa.Small_Array(4446, i16)

parse :: proc(data: ^[]byte) -> []i16 {
	for line in bytes.split_iterator(data, LB) {
		e: i16
		d: u8 = line[0]

		value, ok := strconv.parse_uint(string(line[1:]))
		if !ok {
			panic("failed to parse rotation value")
		}

		e = i16(value)

		switch d {
		case 'L':
			e *= -1
		}


		sa.append_elem(&_actions, e)
	}

	return sa.slice(&_actions)
}

rotate_dial :: #force_inline proc "contextless" (dial: ^Dial, action: i16) {
	dial.value = math.floor_mod(dial.value + action, 100)
}

rotate_dial2 :: #force_inline proc "contextless" (dial: ^Dial, action: i16) {
	awt := dial.value + action
	rev := math.abs(awt / 100)
	mod := math.floor_mod(awt, 100)

	if dial.value != 0 && awt <= 0 {
		rev += 1
	}

	dial.pwd += u16(rev)
	dial.value = mod
}

@(test)
_test :: proc(t: ^testing.T) {
	input := #load("./example_data", []byte)
	data := parse(&input)
	result := part1(data)

	testing.expect(t, result == 3, fmt.tprintf("expected result 3, got %d", result))

	result = part2(data)
	testing.expect(t, result == 6, fmt.tprintf("expected result 6, got %d", result))
}

part1 :: proc(actions: []i16) -> u16 {
	dial := Dial {
		value = 50,
		pwd   = 0,
	}

	for action in actions {
		rotate_dial(&dial, action)
		if dial.value == 0 do dial.pwd += 1
	}

	return dial.pwd
}

part2 :: proc(actions: []i16) -> u16 {
	dial := Dial {
		value = 50,
		pwd   = 0,
	}

	for action in actions {
		rotate_dial2(&dial, action)
	}

	return dial.pwd
}

main :: proc() {
	t := time.Stopwatch{}
	time.stopwatch_start(&t)
	input := #load("./data", []byte)
	data := parse(&input)
	result := part1(data)
	result_2 := part2(data)
	time.stopwatch_stop(&t)
	d := time.stopwatch_duration(t)
	fmt.println(result, result_2)
	fmt.printf("Time taken: %\n", d)
}
