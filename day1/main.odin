package main

import "core:math"
import "core:bytes"
import sa "core:container/small_array"
import "core:fmt"
import "core:sort"
import "core:strconv"
import "core:strings"
import "core:testing"

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

rotate_dial :: proc(dial: ^Dial, action: i16) {
	new_value: i16 = (dial.value + action) % 100
	if new_value < 0 {
		new_value += 100
	}

	dial.value = new_value
}

// ugly solution
rotate_dial2 :: proc(dial: ^Dial, action: i16) {
	a := action
	modifier: i16 = a > 0 ? 1 : -1


	for a != 0 {
		dial.value += modifier
		a -= modifier

		if dial.value == -1 do dial.value = 99
		else if dial.value == 100 {
			dial.value = 0
			dial.pwd += 1
		} else if dial.value == 0 {
			dial.pwd += 1
		}
	}
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
	input := #load("./data", []byte)
	data := parse(&input)
	result := part1(data)
	result_2 := part2(data)
	fmt.println(result, result_2)
}
