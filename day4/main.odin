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

Grid :: struct($V: typeid) {
	width:  int,
	height: int,
	data:   []V,
}

Grid_Iter :: struct($V: typeid) {
	g: Grid(V),
	x: int,
	y: int,
}

grid_iter :: proc(grid: Grid($V)) -> Grid_Iter(V) {
	return Grid_Iter(V){g = grid, x = 0, y = 0}
}

grid_loop :: proc(gitr: ^$A/Grid_Iter($V)) -> (res: V, x, y: int, ok: bool) {
	if grid_inbound(gitr.g, gitr.x, gitr.y) {
		ok = true
		res = grid_get(gitr.g, gitr.x, gitr.y)
		x = gitr.x
		y = gitr.y
		if gitr.x < gitr.g.width - 1 {
			gitr.x += 1
		} else {
			gitr.x = 0
			gitr.y += 1
		}
	}

	return
}

grid_new :: proc(W, H: int, $V: typeid) -> Grid(V) {
	g := Grid(V){}

	g.width = W
	g.height = H

	g.data = make_slice([]V, H * W, context.allocator)

	return g
}

grid_delete :: proc(grid: $A/Grid($V)) {
	delete_slice(grid.data, context.allocator)
}

Point :: [2]int
POINTS :: [8]Point{{-1, -1}, {-1, 0}, {-1, 1}, {0, -1}, {0, 1}, {1, 1}, {1, 0}, {1, -1}}

grid_inbound :: #force_inline proc "contextless" (grid: $A/Grid, x, y: int) -> bool {
	return !(x < 0 || x >= grid.width || y < 0 || y >= grid.height)
}

grid_inboundp :: #force_inline proc "contextless" (grid: $A/Grid, p: Point) -> bool {
	return grid_inbound(grid, p.x, p.y)
}

grid_neighbours :: proc "contextless" (grid: $A/Grid($V), x, y: int) -> [8]V {
	ns := [8]V{}
	end: int = 0

	for p in POINTS {
		c := Point{x + p.x, y + p.y}

		if !grid_inboundp(grid, c) do continue
		ns[end] = grid_getp(grid, c)
		end += 1
	}

	return ns
}

grid_set :: proc "contextless" (grid: ^$A/Grid($V), x, y: int, value: V) {
	grid.data[(y * grid.height) + x] = value
}

grid_get :: proc "contextless" (grid: Grid($V), x, y: int) -> V {
	return grid.data[(y * grid.height) + x]
}

grid_getp :: proc "contextless" (grid: Grid($V), p: Point) -> V {
	return grid_get(grid, p.x, p.y)
}

grid_setp :: proc "contextless" (grid: ^$A/Grid($V), p: Point, value: V) {
	grid_set(grid, p.x, p.y, value)
}

parse :: proc(grid: ^$A/Grid(u8), data: ^[]byte) {
	y := 0
	for r in bytes.split_iterator(data, LB) {
		for c, x in r {
			grid_set(grid, x, y, c == '@' ? 1 : 0)
		}

		y += 1
	}
}

@(test)
p1_test :: proc(t: ^testing.T) {
	data := #load("./example_data", []byte)
	r := part1(&data, 10, 10)

	testing.expect_value(t, r, 13)
}

part1 :: proc(data: ^[]byte, $H, $W: int) -> int {
	g := grid_new(H, W, u8)
	defer grid_delete(g)
	parse(&g, data)
	g_iter := grid_iter(g)
	sum: int

	for v, x, y in grid_loop(&g_iter) {
		if v == 1 {
			nhs := grid_neighbours(g, x, y)

			n_nhs := math.sum(nhs[:])
			if n_nhs < 4 {
				sum += 1
			}
		}
	}

	return sum
}

@(test)
p2_test :: proc(t: ^testing.T) {
	data := #load("./example_data", []byte)
	r := part2(&data, 10, 10)

	testing.expect_value(t, r, 43)
}

part2 :: proc(data: ^[]byte, $H, $W: int) -> int {
	g := grid_new(H, W, u8)
	defer grid_delete(g)
	parse(&g, data)
	sum: int

	for {
		l_sum: int = 0
		g_iter := grid_iter(g)
		for v, x, y in grid_loop(&g_iter) {
			if v == 1 {
				nhs := grid_neighbours(g, x, y)

				n_nhs := math.sum(nhs[:])
				if n_nhs < 4 {
					l_sum += 1
					grid_set(&g, x, y, 0)
				}
			}
		}

		if l_sum == 0 do break

		sum += l_sum
	}

	return sum
}

main :: proc() {
	t := time.Stopwatch{}
	data := #load("./data", []byte)
	time.stopwatch_start(&t)
	r := part1(&data, 137, 137)
	time.stopwatch_stop(&t)

	d := time.stopwatch_duration(t)
	fmt.printfln("Part 1 time taken: %\n value: %v", d, r)

	time.stopwatch_reset(&t)

	time.stopwatch_start(&t)
	data = #load("./data", []byte)
	r2 := part2(&data, 137, 137)
	time.stopwatch_stop(&t)

	d = time.stopwatch_duration(t)
	fmt.printfln("Part 2 time taken: %\n value: %v", d, r2)
}
